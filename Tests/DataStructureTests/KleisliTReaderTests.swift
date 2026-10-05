// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// Covers the Reader-outer stacks' `kleisli` through the struct API; ReaderTPublisher is covered in PublisherStackLawTests.

@Suite struct KleisliTReaderTests {
    struct Env {
        let multiplier: Int
    }

    enum TestFailure: Error, Equatable {
        case broken
    }

    // MARK: - ReaderT + Array

    @Test func readerTArrayComposition() {
        let duplicate: @Sendable (Int) -> Reader<Env, [Int]> = { value in
            Reader { env in [value, value * env.multiplier] }
        }
        let describe: @Sendable (Int) -> Reader<Env, [String]> = { value in
            Reader(const(["\(value)"]))
        }

        let composed = ReaderTArray<Env, Int>.kleisli({ ReaderTArray(duplicate($0)) }, { ReaderTArray(describe($0)) })

        let env = Env(multiplier: 3)
        #expect(composed(2).rawValue(env) == ["2", "6"])
    }

    @Test func readerTArrayEmptyShortCircuits() {
        let empty: @Sendable (Int) -> Reader<Env, [Int]> = const(Reader(const([])))
        let describe: @Sendable (Int) -> Reader<Env, [String]> = { value in
            Reader(const(["\(value)"]))
        }

        let composed = ReaderTArray<Env, Int>.kleisli({ ReaderTArray(empty($0)) }, { ReaderTArray(describe($0)) })

        let env = Env(multiplier: 3)
        #expect(composed(2).rawValue(env).isEmpty)
    }

    // MARK: - ReaderT + Either

    @Test func readerTEitherComposition() {
        let scale: @Sendable (Int) -> Reader<Env, Either<String, Int>> = { value in
            Reader { env in .right(value * env.multiplier) }
        }
        let describe: @Sendable (Int) -> Reader<Env, Either<String, String>> = { value in
            Reader(const(.right("\(value)")))
        }

        let composed = ReaderTEither<Env, String, Int>.kleisli({ ReaderTEither(scale($0)) }, { ReaderTEither(describe($0)) })

        let env = Env(multiplier: 5)
        #expect(composed(2).rawValue(env) == .right("10"))
    }

    @Test func readerTEitherLeftShortCircuits() {
        let fail: @Sendable (Int) -> Reader<Env, Either<String, Int>> = const(Reader(const(.left("boom"))))
        let describe: @Sendable (Int) -> Reader<Env, Either<String, String>> = { value in
            Reader(const(.right("\(value)")))
        }

        let composed = ReaderTEither<Env, String, Int>.kleisli({ ReaderTEither(fail($0)) }, { ReaderTEither(describe($0)) })

        let env = Env(multiplier: 5)
        #expect(composed(2).rawValue(env) == .left("boom"))
    }

    // MARK: - ReaderT + Optional

    @Test func readerTOptionalComposition() {
        let scale: @Sendable (Int) -> Reader<Env, Int?> = { value in
            Reader { env in value * env.multiplier }
        }
        let describe: @Sendable (Int) -> Reader<Env, String?> = { value in
            Reader(const("\(value)"))
        }

        let composed = ReaderTOptional<Env, Int>.kleisli({ ReaderTOptional(scale($0)) }, { ReaderTOptional(describe($0)) })

        let env = Env(multiplier: 4)
        #expect(composed(2).rawValue(env) == "8")
    }

    @Test func readerTOptionalNilShortCircuits() {
        let missing: @Sendable (Int) -> Reader<Env, Int?> = const(Reader(const(nil)))
        let describe: @Sendable (Int) -> Reader<Env, String?> = { value in
            Reader(const("\(value)"))
        }

        let composed = ReaderTOptional<Env, Int>.kleisli({ ReaderTOptional(missing($0)) }, { ReaderTOptional(describe($0)) })

        let env = Env(multiplier: 4)
        #expect(composed(2).rawValue(env) == nil)
    }

    // MARK: - ReaderT + Reader (nested)

    @Test func readerTReaderComposition() {
        let outer: @Sendable (Int) -> Reader<Env, Reader<Int, Int>> = { value in
            Reader { env in
                Reader { offset in value * env.multiplier + offset }
            }
        }
        let inner: @Sendable (Int) -> Reader<Env, Reader<Int, String>> = { value in
            Reader(const(Reader { offset in "\(value + offset)" }))
        }

        let composed = ReaderTReader<Env, Int, Int>.kleisli({ ReaderTReader(outer($0)) }, { ReaderTReader(inner($0)) })

        let env = Env(multiplier: 2)
        let result = composed(3).rawValue(env)(10)
        #expect(result == "26")
    }

    // MARK: - ReaderT + Result

    @Test func readerTResultComposition() {
        let scale: @Sendable (Int) -> Reader<Env, Result<Int, TestFailure>> = { value in
            Reader { env in .success(value * env.multiplier) }
        }
        let describe: @Sendable (Int) -> Reader<Env, Result<String, TestFailure>> = { value in
            Reader(const(.success("\(value)")))
        }

        let composed = ReaderTResult<Env, TestFailure, Int>.kleisli({ ReaderTResult(scale($0)) }, { ReaderTResult(describe($0)) })

        let env = Env(multiplier: 6)
        #expect(composed(2).rawValue(env) == .success("12"))
    }

    @Test func readerTResultFailureShortCircuits() {
        let fail: @Sendable (Int) -> Reader<Env, Result<Int, TestFailure>> = const(Reader(const(.failure(.broken))))
        let describe: @Sendable (Int) -> Reader<Env, Result<String, TestFailure>> = { value in
            Reader(const(.success("\(value)")))
        }

        let composed = ReaderTResult<Env, TestFailure, Int>.kleisli({ ReaderTResult(fail($0)) }, { ReaderTResult(describe($0)) })

        let env = Env(multiplier: 6)
        #expect(composed(2).rawValue(env) == .failure(.broken))
    }

    // MARK: - ReaderT + Stateful

    @Test func readerTStatefulComposition() {
        let scale: @Sendable (Int) -> Reader<Env, Stateful<Int, Int>> = { value in
            Reader { env in
                Stateful { state in
                    state += 1
                    return value * env.multiplier
                }
            }
        }
        let describe: @Sendable (Int) -> Reader<Env, Stateful<Int, String>> = { value in
            Reader { env in
                Stateful { state in
                    state += 10 * env.multiplier
                    return "\(value)"
                }
            }
        }

        let composed = ReaderTStateful<Env, Int, Int>.kleisli({ ReaderTStateful(scale($0)) }, { ReaderTStateful(describe($0)) })

        let env = Env(multiplier: 3)
        let (value, state) = composed(2).rawValue(env).runStateful(0)
        #expect(value == "6")
        #expect(state == 31)
    }

    // MARK: - ReaderT + Writer

    @Test func readerTWriterComposition() {
        let scale: @Sendable (Int) -> Reader<Env, Writer<[String], Int>> = { value in
            Reader { env in Writer(value * env.multiplier, ["scaled"]) }
        }
        let describe: @Sendable (Int) -> Reader<Env, Writer<[String], String>> = { value in
            Reader { env in Writer("\(value)", ["described by \(env.multiplier)"]) }
        }

        let composed = ReaderTWriter<Env, [String], Int>.kleisli({ ReaderTWriter(scale($0)) }, { ReaderTWriter(describe($0)) })

        let env = Env(multiplier: 7)
        let writer = composed(2).rawValue(env)
        #expect(writer.value == "14")
        #expect(writer.log == ["scaled", "described by 7"])
    }
}
