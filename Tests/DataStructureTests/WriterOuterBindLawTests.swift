// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// `M<Writer<W, A>>` is Haskell's `WriterT w M`. `flatMap` is WriterT's bind: the continuation
// returns the full stack, so it can use the outer layer (fail, prune, branch) as well as log.
// Monad laws, checked on values and logs, for every outer `M`.

private typealias Log = [String]
private struct Boom: Error, Equatable {}

@Suite("M<Writer> bind is WriterT's bind")
struct WriterOuterBindLawTests {
    // MARK: - ArrayTWriter

    private static let arrayF: @Sendable (Int) -> ArrayTWriter<Log, Int> = { n in
        ArrayTWriter(n > 5 ? [] : [Writer(n + 1, ["f\(n)"]), Writer(n * 2, ["F\(n)"])])
    }

    private static let arrayG: @Sendable (Int) -> ArrayTWriter<Log, String> = { n in ArrayTWriter([Writer("\(n)", ["g\(n)"])]) }
    private static let arrays: [[Writer<Log, Int>]] = [[], [Writer(1, ["m"])], [Writer(2, ["a"]), Writer(9, ["b"])]]

    @Test func arrayTWriterLeftIdentity() {
        for a in [0, 3, 7] {
            #expect([Writer<Log, Int>(a, [])].arrayT.flatMap(Self.arrayF).rawValue == Self.arrayF(a).rawValue)
        }
    }

    @Test func arrayTWriterRightIdentity() {
        for m in Self.arrays {
            #expect(m.arrayT.flatMap { ArrayTWriter([Writer<Log, Int>($0, [])]) }.rawValue == m)
        }
    }

    @Test func arrayTWriterAssociativity() {
        for m in Self.arrays {
            #expect(
                m.arrayT.flatMap(Self.arrayF).flatMap(Self.arrayG).rawValue
                    == m.arrayT.flatMap { Self.arrayF($0).flatMap(Self.arrayG) }.rawValue
            )
        }
    }

    @Test func arrayTWriterContinuationBranchesAndPrunes() {
        let m: [Writer<Log, Int>] = [Writer(1, ["a"]), Writer(6, ["b"]), Writer(2, ["c"])]
        let fromA: [Writer<Log, Int>] = [Writer(2, ["a", "f1"]), Writer(2, ["a", "F1"])]
        let fromC: [Writer<Log, Int>] = [Writer(3, ["c", "f2"]), Writer(4, ["c", "F2"])]
        let expected = fromA + fromC
        #expect(m.arrayT.flatMap(Self.arrayF).rawValue == expected)
        #expect(ArrayTWriter<Log, Int>.bind(Self.arrayF)(m.arrayT).rawValue == expected)
        #expect(ArrayTWriter.kleisli(Self.arrayF, Self.arrayG)(1).rawValue == [Writer("2", ["f1", "g2"]), Writer("2", ["F1", "g2"])])
    }

    // MARK: - OptionalTWriter

    private static let optionalF: @Sendable (Int) -> OptionalTWriter<Log, Int> = { n in
        OptionalTWriter(n > 5 ? nil : Writer(n + 1, ["f\(n)"]))
    }

    private static let optionalG: @Sendable (Int) -> OptionalTWriter<Log, String> = { n in OptionalTWriter(Writer("\(n)", ["g\(n)"])) }
    private static let optionals: [Writer<Log, Int>?] = [nil, Writer(1, ["m"]), Writer(9, ["m"])]

    @Test func optionalTWriterLeftIdentity() {
        for a in [0, 7] {
            #expect(Writer<Log, Int>?.some(Writer(a, [])).optionalT.flatMap(Self.optionalF).rawValue == Self.optionalF(a).rawValue)
        }
    }

    @Test func optionalTWriterRightIdentity() {
        for m in Self.optionals {
            #expect(m.optionalT.flatMap { OptionalTWriter(Writer<Log, Int>?.some(Writer($0, []))) }.rawValue == m)
        }
    }

    @Test func optionalTWriterAssociativity() {
        for m in Self.optionals {
            #expect(
                m.optionalT.flatMap(Self.optionalF).flatMap(Self.optionalG).rawValue
                    == m.optionalT.flatMap { Self.optionalF($0).flatMap(Self.optionalG) }.rawValue
            )
        }
    }

    @Test func optionalTWriterContinuationCanFail() {
        let some: Writer<Log, Int>? = Writer(1, ["a"])
        let tooBig: Writer<Log, Int>? = Writer(6, ["a"])
        #expect(some.optionalT.flatMap(Self.optionalF).rawValue == Writer(2, ["a", "f1"]))
        #expect(tooBig.optionalT.flatMap(Self.optionalF).rawValue == nil)
        #expect(OptionalTWriter<Log, Int>.bind(Self.optionalF)(tooBig.optionalT).rawValue == nil)
        #expect(OptionalTWriter.kleisli(Self.optionalF, Self.optionalG)(1).rawValue == Writer("2", ["f1", "g2"]))
        #expect(OptionalTWriter.kleisli(Self.optionalF, Self.optionalG)(6).rawValue == nil)
    }

    // MARK: - ResultTWriter

    private static let resultF: @Sendable (Int) -> ResultTWriter<Boom, Log, Int> = { n in
        ResultTWriter(n > 5 ? .failure(Boom()) : .success(Writer(n + 1, ["f\(n)"])))
    }

    private static let resultG: @Sendable (Int) -> ResultTWriter<Boom, Log, String> = { n in
        ResultTWriter(.success(Writer("\(n)", ["g\(n)"])))
    }

    private static let results: [Result<Writer<Log, Int>, Boom>] = [
        .failure(Boom()), .success(Writer(1, ["m"])), .success(Writer(9, ["m"]))
    ]

    @Test func resultTWriterLeftIdentity() {
        for a in [0, 7] {
            #expect(
                Result<Writer<Log, Int>, Boom>.success(Writer(a, [])).resultT.flatMap(Self.resultF).rawValue == Self.resultF(a).rawValue
            )
        }
    }

    @Test func resultTWriterRightIdentity() {
        for m in Self.results {
            #expect(m.resultT.flatMap { ResultTWriter(Result<Writer<Log, Int>, Boom>.success(Writer($0, []))) }.rawValue == m)
        }
    }

    @Test func resultTWriterAssociativity() {
        for m in Self.results {
            #expect(
                m.resultT.flatMap(Self.resultF).flatMap(Self.resultG).rawValue
                    == m.resultT.flatMap { Self.resultF($0).flatMap(Self.resultG) }.rawValue
            )
        }
    }

    @Test func resultTWriterContinuationCanFail() {
        let ok: Result<Writer<Log, Int>, Boom> = .success(Writer(1, ["a"]))
        let tooBig: Result<Writer<Log, Int>, Boom> = .success(Writer(6, ["a"]))
        #expect(ok.resultT.flatMap(Self.resultF).rawValue == .success(Writer(2, ["a", "f1"])))
        #expect(tooBig.resultT.flatMap(Self.resultF).rawValue == .failure(Boom()))
        #expect(ResultTWriter<Boom, Log, Int>.bind(Self.resultF)(tooBig.resultT).rawValue == .failure(Boom()))
        #expect(ResultTWriter.kleisli(Self.resultF, Self.resultG)(1).rawValue == .success(Writer("2", ["f1", "g2"])))
        #expect(ResultTWriter.kleisli(Self.resultF, Self.resultG)(6).rawValue == .failure(Boom()))
    }

    // MARK: - EitherTWriter

    private static let eitherF: @Sendable (Int) -> EitherTWriter<String, Log, Int> = { n in
        EitherTWriter(n > 5 ? .left("too big: \(n)") : .right(Writer(n + 1, ["f\(n)"])))
    }

    private static let eitherG: @Sendable (Int) -> EitherTWriter<String, Log, String> = { n in
        EitherTWriter(.right(Writer("\(n)", ["g\(n)"])))
    }

    private static let eithers: [Either<String, Writer<Log, Int>>] = [.left("m"), .right(Writer(1, ["m"])), .right(Writer(9, ["m"]))]

    @Test func eitherTWriterLeftIdentity() {
        for a in [0, 7] {
            #expect(
                Either<String, Writer<Log, Int>>.right(Writer(a, [])).eitherT.flatMap(Self.eitherF).rawValue == Self.eitherF(a).rawValue
            )
        }
    }

    @Test func eitherTWriterRightIdentity() {
        for m in Self.eithers {
            #expect(m.eitherT.flatMap { EitherTWriter(Either<String, Writer<Log, Int>>.right(Writer($0, []))) }.rawValue == m)
        }
    }

    @Test func eitherTWriterAssociativity() {
        for m in Self.eithers {
            #expect(
                m.eitherT.flatMap(Self.eitherF).flatMap(Self.eitherG).rawValue
                    == m.eitherT.flatMap { Self.eitherF($0).flatMap(Self.eitherG) }.rawValue
            )
        }
    }

    @Test func eitherTWriterContinuationCanFail() {
        let ok: Either<String, Writer<Log, Int>> = .right(Writer(1, ["a"]))
        let tooBig: Either<String, Writer<Log, Int>> = .right(Writer(6, ["a"]))
        #expect(ok.eitherT.flatMap(Self.eitherF).rawValue == .right(Writer(2, ["a", "f1"])))
        #expect(tooBig.eitherT.flatMap(Self.eitherF).rawValue == .left("too big: 6"))
        #expect(EitherTWriter<String, Log, Int>.bind(Self.eitherF)(tooBig.eitherT).rawValue == .left("too big: 6"))
        #expect(EitherTWriter.kleisli(Self.eitherF, Self.eitherG)(1).rawValue == .right(Writer("2", ["f1", "g2"])))
        #expect(EitherTWriter.kleisli(Self.eitherF, Self.eitherG)(6).rawValue == .left("too big: 6"))
    }
}
