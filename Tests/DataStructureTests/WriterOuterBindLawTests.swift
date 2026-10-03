// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// `M<Writer<W, A>>` is Haskell's `WriterT w M`. `flatMapT` is WriterT's bind: the continuation
// returns the full stack, so it can use the outer layer (fail, prune, branch) as well as log.
// Monad laws, checked on values and logs, for every outer `M`.

private typealias Log = [String]
private struct Boom: Error, Equatable {}

@Suite("M<Writer> bind is WriterT's bind")
struct WriterOuterBindLawTests {
    // MARK: - ArrayTWriter

    private static let arrayF: @Sendable (Int) -> [Writer<Log, Int>] = { n in
        n > 5 ? [] : [Writer(n + 1, ["f\(n)"]), Writer(n * 2, ["F\(n)"])]
    }

    private static let arrayG: @Sendable (Int) -> [Writer<Log, String>] = { n in [Writer("\(n)", ["g\(n)"])] }
    private static let arrays: [[Writer<Log, Int>]] = [[], [Writer(1, ["m"])], [Writer(2, ["a"]), Writer(9, ["b"])]]

    @Test func arrayTWriterLeftIdentity() {
        for a in [0, 3, 7] {
            #expect([Writer<Log, Int>(a, [])].flatMapT(Self.arrayF) == Self.arrayF(a))
        }
    }

    @Test func arrayTWriterRightIdentity() {
        for m in Self.arrays {
            #expect(m.flatMapT { [Writer<Log, Int>($0, [])] } == m)
        }
    }

    @Test func arrayTWriterAssociativity() {
        for m in Self.arrays {
            #expect(m.flatMapT(Self.arrayF).flatMapT(Self.arrayG) == m.flatMapT { Self.arrayF($0).flatMapT(Self.arrayG) })
        }
    }

    @Test func arrayTWriterContinuationBranchesAndPrunes() {
        let m: [Writer<Log, Int>] = [Writer(1, ["a"]), Writer(6, ["b"]), Writer(2, ["c"])]
        let fromA: [Writer<Log, Int>] = [Writer(2, ["a", "f1"]), Writer(2, ["a", "F1"])]
        let fromC: [Writer<Log, Int>] = [Writer(3, ["c", "f2"]), Writer(4, ["c", "F2"])]
        let expected = fromA + fromC
        #expect(m.flatMapT(Self.arrayF) == expected)
        #expect([Writer<Log, Int>].bindT(Self.arrayF)(m) == expected)
        #expect(kleisliT(Self.arrayF, Self.arrayG)(1) == [Writer("2", ["f1", "g2"]), Writer("2", ["F1", "g2"])])
    }

    // MARK: - OptionalTWriter

    private static let optionalF: @Sendable (Int) -> Writer<Log, Int>? = { n in n > 5 ? nil : Writer(n + 1, ["f\(n)"]) }
    private static let optionalG: @Sendable (Int) -> Writer<Log, String>? = { n in Writer("\(n)", ["g\(n)"]) }
    private static let optionals: [Writer<Log, Int>?] = [nil, Writer(1, ["m"]), Writer(9, ["m"])]

    @Test func optionalTWriterLeftIdentity() {
        for a in [0, 7] {
            #expect(Writer<Log, Int>?.some(Writer(a, [])).flatMapT(Self.optionalF) == Self.optionalF(a))
        }
    }

    @Test func optionalTWriterRightIdentity() {
        for m in Self.optionals {
            #expect(m.flatMapT { Writer<Log, Int>?.some(Writer($0, [])) } == m)
        }
    }

    @Test func optionalTWriterAssociativity() {
        for m in Self.optionals {
            #expect(
                m.flatMapT(Self.optionalF).flatMapT(Self.optionalG) == m.flatMapT { Self.optionalF($0).flatMapT(Self.optionalG) }
            )
        }
    }

    @Test func optionalTWriterContinuationCanFail() {
        let some: Writer<Log, Int>? = Writer(1, ["a"])
        let tooBig: Writer<Log, Int>? = Writer(6, ["a"])
        #expect(some.flatMapT(Self.optionalF) == Writer(2, ["a", "f1"]))
        #expect(tooBig.flatMapT(Self.optionalF) == nil)
        #expect(Writer<Log, Int>?.bindT(Self.optionalF)(tooBig) == nil)
        #expect(kleisliT(Self.optionalF, Self.optionalG)(1) == Writer("2", ["f1", "g2"]))
        #expect(kleisliT(Self.optionalF, Self.optionalG)(6) == nil)
    }

    // MARK: - ResultTWriter

    private static let resultF: @Sendable (Int) -> Result<Writer<Log, Int>, Boom> = { n in
        n > 5 ? .failure(Boom()) : .success(Writer(n + 1, ["f\(n)"]))
    }

    private static let resultG: @Sendable (Int) -> Result<Writer<Log, String>, Boom> = { n in .success(Writer("\(n)", ["g\(n)"])) }
    private static let results: [Result<Writer<Log, Int>, Boom>] = [
        .failure(Boom()), .success(Writer(1, ["m"])), .success(Writer(9, ["m"]))
    ]

    @Test func resultTWriterLeftIdentity() {
        for a in [0, 7] {
            #expect(Result<Writer<Log, Int>, Boom>.success(Writer(a, [])).flatMapT(Self.resultF) == Self.resultF(a))
        }
    }

    @Test func resultTWriterRightIdentity() {
        for m in Self.results {
            #expect(m.flatMapT { Result<Writer<Log, Int>, Boom>.success(Writer($0, [])) } == m)
        }
    }

    @Test func resultTWriterAssociativity() {
        for m in Self.results {
            #expect(m.flatMapT(Self.resultF).flatMapT(Self.resultG) == m.flatMapT { Self.resultF($0).flatMapT(Self.resultG) })
        }
    }

    @Test func resultTWriterContinuationCanFail() {
        let ok: Result<Writer<Log, Int>, Boom> = .success(Writer(1, ["a"]))
        let tooBig: Result<Writer<Log, Int>, Boom> = .success(Writer(6, ["a"]))
        #expect(ok.flatMapT(Self.resultF) == .success(Writer(2, ["a", "f1"])))
        #expect(tooBig.flatMapT(Self.resultF) == .failure(Boom()))
        #expect(Result<Writer<Log, Int>, Boom>.bindT(Self.resultF)(tooBig) == .failure(Boom()))
        #expect(kleisliT(Self.resultF, Self.resultG)(1) == .success(Writer("2", ["f1", "g2"])))
        #expect(kleisliT(Self.resultF, Self.resultG)(6) == .failure(Boom()))
    }

    // MARK: - EitherTWriter

    private static let eitherF: @Sendable (Int) -> Either<String, Writer<Log, Int>> = { n in
        n > 5 ? .left("too big: \(n)") : .right(Writer(n + 1, ["f\(n)"]))
    }

    private static let eitherG: @Sendable (Int) -> Either<String, Writer<Log, String>> = { n in .right(Writer("\(n)", ["g\(n)"])) }
    private static let eithers: [Either<String, Writer<Log, Int>>] = [.left("m"), .right(Writer(1, ["m"])), .right(Writer(9, ["m"]))]

    @Test func eitherTWriterLeftIdentity() {
        for a in [0, 7] {
            #expect(Either<String, Writer<Log, Int>>.right(Writer(a, [])).flatMapT(Self.eitherF) == Self.eitherF(a))
        }
    }

    @Test func eitherTWriterRightIdentity() {
        for m in Self.eithers {
            #expect(m.flatMapT { Either<String, Writer<Log, Int>>.right(Writer($0, [])) } == m)
        }
    }

    @Test func eitherTWriterAssociativity() {
        for m in Self.eithers {
            #expect(m.flatMapT(Self.eitherF).flatMapT(Self.eitherG) == m.flatMapT { Self.eitherF($0).flatMapT(Self.eitherG) })
        }
    }

    @Test func eitherTWriterContinuationCanFail() {
        let ok: Either<String, Writer<Log, Int>> = .right(Writer(1, ["a"]))
        let tooBig: Either<String, Writer<Log, Int>> = .right(Writer(6, ["a"]))
        #expect(ok.flatMapT(Self.eitherF) == .right(Writer(2, ["a", "f1"])))
        #expect(tooBig.flatMapT(Self.eitherF) == .left("too big: 6"))
        #expect(Either<String, Writer<Log, Int>>.bindT(Self.eitherF)(tooBig) == .left("too big: 6"))
        #expect(kleisliT(Self.eitherF, Self.eitherG)(1) == .right(Writer("2", ["f1", "g2"])))
        #expect(kleisliT(Self.eitherF, Self.eitherG)(6) == .left("too big: 6"))
    }
}
