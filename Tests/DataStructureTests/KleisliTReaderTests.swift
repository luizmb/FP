// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// Note: ReaderTPublisher's kleisliT is Combine-only; Publisher stacks get test coverage in a later branch.

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

        let composed = kleisliT(duplicate, describe)

        let env = Env(multiplier: 3)
        #expect(composed(2)(env) == ["2", "6"])
    }

    @Test func readerTArrayEmptyShortCircuits() {
        let empty: @Sendable (Int) -> Reader<Env, [Int]> = const(Reader(const([])))
        let describe: @Sendable (Int) -> Reader<Env, [String]> = { value in
            Reader(const(["\(value)"]))
        }

        let composed = kleisliT(empty, describe)

        let env = Env(multiplier: 3)
        #expect(composed(2)(env).isEmpty)
    }

    // MARK: - ReaderT + Either

    @Test func readerTEitherComposition() {
        let scale: @Sendable (Int) -> Reader<Env, Either<String, Int>> = { value in
            Reader { env in .right(value * env.multiplier) }
        }
        let describe: @Sendable (Int) -> Reader<Env, Either<String, String>> = { value in
            Reader(const(.right("\(value)")))
        }

        let composed = kleisliT(scale, describe)

        let env = Env(multiplier: 5)
        #expect(composed(2)(env) == .right("10"))
    }

    @Test func readerTEitherLeftShortCircuits() {
        let fail: @Sendable (Int) -> Reader<Env, Either<String, Int>> = const(Reader(const(.left("boom"))))
        let describe: @Sendable (Int) -> Reader<Env, Either<String, String>> = { value in
            Reader(const(.right("\(value)")))
        }

        let composed = kleisliT(fail, describe)

        let env = Env(multiplier: 5)
        #expect(composed(2)(env) == .left("boom"))
    }

    // MARK: - ReaderT + Optional

    @Test func readerTOptionalComposition() {
        let scale: @Sendable (Int) -> Reader<Env, Int?> = { value in
            Reader { env in value * env.multiplier }
        }
        let describe: @Sendable (Int) -> Reader<Env, String?> = { value in
            Reader(const("\(value)"))
        }

        let composed = kleisliT(scale, describe)

        let env = Env(multiplier: 4)
        #expect(composed(2)(env) == "8")
    }

    @Test func readerTOptionalNilShortCircuits() {
        let missing: @Sendable (Int) -> Reader<Env, Int?> = const(Reader(const(nil)))
        let describe: @Sendable (Int) -> Reader<Env, String?> = { value in
            Reader(const("\(value)"))
        }

        let composed = kleisliT(missing, describe)

        let env = Env(multiplier: 4)
        #expect(composed(2)(env) == nil)
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

        let composed = kleisliT(outer, inner)

        let env = Env(multiplier: 2)
        let result = composed(3)(env)(10)
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

        let composed = kleisliT(scale, describe)

        let env = Env(multiplier: 6)
        #expect(composed(2)(env) == .success("12"))
    }

    @Test func readerTResultFailureShortCircuits() {
        let fail: @Sendable (Int) -> Reader<Env, Result<Int, TestFailure>> = const(Reader(const(.failure(.broken))))
        let describe: @Sendable (Int) -> Reader<Env, Result<String, TestFailure>> = { value in
            Reader(const(.success("\(value)")))
        }

        let composed = kleisliT(fail, describe)

        let env = Env(multiplier: 6)
        #expect(composed(2)(env) == .failure(.broken))
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
        let describe: @Sendable (Int) -> Stateful<Int, String> = { value in
            Stateful { state in
                state += 10
                return "\(value)"
            }
        }

        let composed = kleisliT(scale, describe)

        let env = Env(multiplier: 3)
        let (value, state) = composed(2)(env).runStateful(0)
        #expect(value == "6")
        #expect(state == 11)
    }

    // MARK: - ReaderT + Writer

    @Test func readerTWriterComposition() {
        let scale: @Sendable (Int) -> Reader<Env, Writer<[String], Int>> = { value in
            Reader { env in Writer(value * env.multiplier, ["scaled"]) }
        }
        let describe: @Sendable (Int) -> Writer<[String], String> = { value in
            Writer("\(value)", ["described"])
        }

        let composed = kleisliT(scale, describe)

        let env = Env(multiplier: 7)
        let writer = composed(2)(env)
        #expect(writer.value == "14")
        #expect(writer.log == ["scaled", "described"])
    }
}
