// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// `<*>` must equal `ap` (`mf >>= \f -> fmap f ma`) for `Writer<W, Either/Optional/Result>`, mirroring
// Haskell's `ExceptT e (Writer w)` / `MaybeT (Writer w)`: once the inner layer fails, the right-hand log
// must not be appended.

enum WriterApError: Error, Equatable {
    case function
    case lhs
    case rhs
}

@Suite struct WriterTEitherApLawTests {
    let functions: [Writer<[String], Either<String, @Sendable (Int) -> Int>>] = [
        Writer(.right { $0 + 100 }, ["f"]),
        Writer(.left("f"), ["f!"])
    ]
    let lhs: [Writer<[String], Either<String, Int>>] = [
        Writer(.right(1), ["a"]),
        Writer(.left("a"), ["a!"])
    ]
    let rhs: [Writer<[String], Either<String, String>>] = [
        Writer(.right("b"), ["b"]),
        Writer(.left("b"), ["b!"])
    ]

    @Test func applyEqualsAp() {
        for wf in functions {
            for wa in lhs {
                #expect(applyWriterEither(wf, wa) == wf.flatMapT { f in wa.mapT(f) })
            }
        }
    }

    @Test func liftA2EqualsBind() {
        let combine: @Sendable (Int, String) -> String = { "\($0)-\($1)" }
        for wa in lhs {
            for wb in rhs {
                #expect(liftA2WriterEither(combine)(wa, wb) == wa.flatMapT { a in wb.mapT { b in combine(a, b) } })
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for wa in lhs {
            for wb in rhs {
                #expect(seqRightWriterEither(wa, wb) == wa.flatMapT(const(wb)))
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for wa in lhs {
            for wb in rhs {
                #expect(seqLeftWriterEither(wa, wb) == wa.flatMapT { a in wb.mapT(const(a)) })
            }
        }
    }

    @Test func leftFunctionSkipsRightLog() {
        let wf = Writer<[String], Either<String, @Sendable (Int) -> Int>>(.left("e"), ["f"])
        let wa = Writer<[String], Either<String, Int>>(.right(1), ["a"])
        #expect(applyWriterEither(wf, wa) == Writer(.left("e"), ["f"]))
    }
}

@Suite struct WriterTOptionalApLawTests {
    let functions: [Writer<[String], (@Sendable (Int) -> Int)?>] = [
        Writer(.some { $0 + 100 }, ["f"]),
        Writer(nil, ["f!"])
    ]
    let lhs: [Writer<[String], Int?>] = [
        Writer(.some(1), ["a"]),
        Writer(nil, ["a!"])
    ]
    let rhs: [Writer<[String], String?>] = [
        Writer(.some("b"), ["b"]),
        Writer(nil, ["b!"])
    ]

    @Test func applyEqualsAp() {
        for wf in functions {
            for wa in lhs {
                #expect(applyWriterOptional(wf, wa) == wf.flatMapT { f in wa.mapT(f) })
            }
        }
    }

    @Test func liftA2EqualsBind() {
        let combine: @Sendable (Int, String) -> String = { "\($0)-\($1)" }
        for wa in lhs {
            for wb in rhs {
                #expect(liftA2WriterOptional(combine)(wa, wb) == wa.flatMapT { a in wb.mapT { b in combine(a, b) } })
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for wa in lhs {
            for wb in rhs {
                #expect(seqRightWriterOptional(wa, wb) == wa.flatMapT(const(wb)))
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for wa in lhs {
            for wb in rhs {
                #expect(seqLeftWriterOptional(wa, wb) == wa.flatMapT { a in wb.mapT(const(a)) })
            }
        }
    }

    @Test func noneSkipsRightLog() {
        let none = Writer<[String], Int?>(nil, ["a"])
        let some = Writer<[String], String?>(.some("b"), ["b"])
        #expect(seqRightWriterOptional(none, some) == Writer(nil, ["a"]))
        #expect(seqLeftWriterOptional(none, some) == Writer(nil, ["a"]))
    }
}

@Suite struct WriterTResultApLawTests {
    let functions: [Writer<[String], Result<@Sendable (Int) -> Int, WriterApError>>] = [
        Writer(.success { $0 + 100 }, ["f"]),
        Writer(.failure(.function), ["f!"])
    ]
    let lhs: [Writer<[String], Result<Int, WriterApError>>] = [
        Writer(.success(1), ["a"]),
        Writer(.failure(.lhs), ["a!"])
    ]
    let rhs: [Writer<[String], Result<String, WriterApError>>] = [
        Writer(.success("b"), ["b"]),
        Writer(.failure(.rhs), ["b!"])
    ]

    @Test func applyEqualsAp() {
        for wf in functions {
            for wa in lhs {
                #expect(applyWriterResult(wf, wa) == wf.flatMapT { f in wa.mapT(f) })
            }
        }
    }

    @Test func liftA2EqualsBind() {
        let combine: @Sendable (Int, String) -> String = { "\($0)-\($1)" }
        for wa in lhs {
            for wb in rhs {
                #expect(liftA2WriterResult(combine)(wa, wb) == wa.flatMapT { a in wb.mapT { b in combine(a, b) } })
            }
        }
    }

    @Test func seqRightEqualsBind() {
        for wa in lhs {
            for wb in rhs {
                #expect(seqRightWriterResult(wa, wb) == wa.flatMapT(const(wb)))
            }
        }
    }

    @Test func seqLeftEqualsBind() {
        for wa in lhs {
            for wb in rhs {
                #expect(seqLeftWriterResult(wa, wb) == wa.flatMapT { a in wb.mapT(const(a)) })
            }
        }
    }

    @Test func failedFunctionSkipsRightLog() {
        let wf = Writer<[String], Result<@Sendable (Int) -> Int, WriterApError>>(.failure(.function), ["f"])
        let wa = Writer<[String], Result<Int, WriterApError>>(.success(1), ["a"])
        #expect(applyWriterResult(wf, wa) == Writer(.failure(.function), ["f"]))
    }
}
