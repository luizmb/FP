// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// `apply` must equal `ap` (`mf >>= \f -> fmap f ma`) for `WriterTEither` / `WriterTOptional` / `WriterTResult`,
// mirroring Haskell's `ExceptT e (Writer w)` / `MaybeT (Writer w)`: once the inner layer fails, the right-hand log
// must not be appended.

enum WriterApError: Error, Equatable {
    case function
    case lhs
    case rhs
}

@Suite struct WriterTEitherApLawTests {
    let functions: [WriterTEither<[String], String, @Sendable (Int) -> Int>] = [
        WriterTEither(Writer(.right { $0 + 100 }, ["f"])),
        WriterTEither(Writer(.left("f"), ["f!"]))
    ]
    let lhs: [WriterTEither<[String], String, Int>] = [
        WriterTEither(Writer(.right(1), ["a"])),
        WriterTEither(Writer(.left("a"), ["a!"]))
    ]
    let rhs: [WriterTEither<[String], String, String>] = [
        WriterTEither(Writer(.right("b"), ["b"])),
        WriterTEither(Writer(.left("b"), ["b!"]))
    ]

    @Test func applyEqualsAp() {
        for wf in functions {
            for wa in lhs {
                #expect(WriterTEither.apply(wf, wa).rawValue == wf.flatMap { f in wa.map(f) }.rawValue)
            }
        }
    }

    @Test func liftA2EqualsBind() {
        let combine: @Sendable (Int, String) -> String = { "\($0)-\($1)" }
        for wa in lhs {
            for wb in rhs {
                #expect(
                    WriterTEither.liftA2(combine)(wa, wb).rawValue == wa.flatMap { a in wb.map { b in combine(a, b) } }.rawValue
                )
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for wa in lhs {
            for wb in rhs {
                #expect(wa.seqRight(wb).rawValue == wa.flatMap(const(wb)).rawValue)
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for wa in lhs {
            for wb in rhs {
                #expect(wa.seqLeft(wb).rawValue == wa.flatMap { a in wb.map(const(a)) }.rawValue)
            }
        }
    }

    @Test func leftFunctionSkipsRightLog() {
        let wf = WriterTEither<[String], String, @Sendable (Int) -> Int>(Writer(.left("e"), ["f"]))
        let wa = WriterTEither<[String], String, Int>(Writer(.right(1), ["a"]))
        #expect(WriterTEither.apply(wf, wa).rawValue == Writer(.left("e"), ["f"]))
    }
}

@Suite struct WriterTOptionalApLawTests {
    let functions: [WriterTOptional<[String], @Sendable (Int) -> Int>] = [
        WriterTOptional(Writer(.some { $0 + 100 }, ["f"])),
        WriterTOptional(Writer(nil, ["f!"]))
    ]
    let lhs: [WriterTOptional<[String], Int>] = [
        WriterTOptional(Writer(.some(1), ["a"])),
        WriterTOptional(Writer(nil, ["a!"]))
    ]
    let rhs: [WriterTOptional<[String], String>] = [
        WriterTOptional(Writer(.some("b"), ["b"])),
        WriterTOptional(Writer(nil, ["b!"]))
    ]

    @Test func applyEqualsAp() {
        for wf in functions {
            for wa in lhs {
                #expect(WriterTOptional.apply(wf, wa).rawValue == wf.flatMap { f in wa.map(f) }.rawValue)
            }
        }
    }

    @Test func liftA2EqualsBind() {
        let combine: @Sendable (Int, String) -> String = { "\($0)-\($1)" }
        for wa in lhs {
            for wb in rhs {
                #expect(
                    WriterTOptional.liftA2(combine)(wa, wb).rawValue == wa.flatMap { a in wb.map { b in combine(a, b) } }.rawValue
                )
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for wa in lhs {
            for wb in rhs {
                #expect(wa.seqRight(wb).rawValue == wa.flatMap(const(wb)).rawValue)
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for wa in lhs {
            for wb in rhs {
                #expect(wa.seqLeft(wb).rawValue == wa.flatMap { a in wb.map(const(a)) }.rawValue)
            }
        }
    }

    @Test func noneSkipsRightLog() {
        let none = WriterTOptional<[String], Int>(Writer(nil, ["a"]))
        let some = WriterTOptional<[String], String>(Writer(.some("b"), ["b"]))
        #expect(none.seqRight(some).rawValue == Writer(nil, ["a"]))
        #expect(none.seqLeft(some).rawValue == Writer(nil, ["a"]))
    }
}

@Suite struct WriterTResultApLawTests {
    let functions: [WriterTResult<[String], WriterApError, @Sendable (Int) -> Int>] = [
        WriterTResult(Writer(.success { $0 + 100 }, ["f"])),
        WriterTResult(Writer(.failure(.function), ["f!"]))
    ]
    let lhs: [WriterTResult<[String], WriterApError, Int>] = [
        WriterTResult(Writer(.success(1), ["a"])),
        WriterTResult(Writer(.failure(.lhs), ["a!"]))
    ]
    let rhs: [WriterTResult<[String], WriterApError, String>] = [
        WriterTResult(Writer(.success("b"), ["b"])),
        WriterTResult(Writer(.failure(.rhs), ["b!"]))
    ]

    @Test func applyEqualsAp() {
        for wf in functions {
            for wa in lhs {
                #expect(WriterTResult.apply(wf, wa).rawValue == wf.flatMap { f in wa.map(f) }.rawValue)
            }
        }
    }

    @Test func liftA2EqualsBind() {
        let combine: @Sendable (Int, String) -> String = { "\($0)-\($1)" }
        for wa in lhs {
            for wb in rhs {
                #expect(
                    WriterTResult.liftA2(combine)(wa, wb).rawValue == wa.flatMap { a in wb.map { b in combine(a, b) } }.rawValue
                )
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for wa in lhs {
            for wb in rhs {
                #expect(wa.seqRight(wb).rawValue == wa.flatMap(const(wb)).rawValue)
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for wa in lhs {
            for wb in rhs {
                #expect(wa.seqLeft(wb).rawValue == wa.flatMap { a in wb.map(const(a)) }.rawValue)
            }
        }
    }

    @Test func failedFunctionSkipsRightLog() {
        let wf = WriterTResult<[String], WriterApError, @Sendable (Int) -> Int>(Writer(.failure(.function), ["f"]))
        let wa = WriterTResult<[String], WriterApError, Int>(Writer(.success(1), ["a"]))
        #expect(WriterTResult.apply(wf, wa).rawValue == Writer(.failure(.function), ["f"]))
    }
}
