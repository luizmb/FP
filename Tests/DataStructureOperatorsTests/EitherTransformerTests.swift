// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct EitherTransformerTests {
    private enum L: Equatable { case err }
    private enum E: Error, Equatable { case fail }

    // MARK: - ArrayTEither

    @Test func arrayTEitherBind() {
        let arr: [Either<L, Int>] = [.right(1), .left(.err), .right(2)]
        let result = (arr.arrayT >>- { n in [Either<L, Int>.right(n), .right(n * 10)].arrayT }).rawValue
        #expect(result == [.right(1), .right(10), .left(.err), .right(2), .right(20)])
    }

    @Test func arrayTEitherLiftA2() {
        let a: [Either<L, Int>] = [.right(1), .right(2)]
        let b: [Either<L, Int>] = [.right(10), .right(20)]
        let add: @Sendable (Int) -> @Sendable (Int) -> Int = { x in { y in x + y } }
        let result = (add <£> a.arrayT <*> b.arrayT).rawValue
        #expect(result == [.right(11), .right(21), .right(12), .right(22)])
    }

    @Test func arrayTEitherBindOperator() {
        let arr: [Either<L, Int>] = [.right(1), .right(2)]
        let result = (arr.arrayT >>- { n in [Either<L, Int>.right(n * 2)].arrayT }).rawValue
        #expect(result == [.right(2), .right(4)])
    }

    // MARK: - OptionalTEither

    @Test func optionalTEitherBindNone() {
        let opt: Either<L, Int>? = nil
        let result = (opt.optionalT >>- { n in Either<L, String>?.some(.right("\(n)")).optionalT }).rawValue
        #expect(result == nil)
    }

    @Test func optionalTEitherBindSomeLeft() {
        let opt: Either<L, Int>? = .left(.err)
        let result = (opt.optionalT >>- { n in Either<L, String>?.some(.right("\(n)")).optionalT }).rawValue
        #expect(result == .some(.left(.err)))
    }

    @Test func optionalTEitherBindSomeRight() {
        let opt: Either<L, Int>? = .right(5)
        let result = (opt.optionalT >>- { n in Either<L, String>?.some(.right("\(n)")).optionalT }).rawValue
        #expect(result == .some(.right("5")))
    }

    // MARK: - EitherTOptional

    @Test func eitherTOptionalBindRightSome() {
        let either: Either<L, Int?> = .right(.some(5))
        let result = (either.eitherT >>- { n in Either<L, String?>.right(.some("\(n)")).eitherT }).rawValue
        #expect(result == .right(.some("5")))
    }

    @Test func eitherTOptionalBindRightNone() {
        let either: Either<L, Int?> = .right(.none)
        let result = (either.eitherT >>- { n in Either<L, String?>.right(.some("\(n)")).eitherT }).rawValue
        #expect(result == .right(.none))
    }

    @Test func eitherTOptionalBindLeft() {
        let either: Either<L, Int?> = .left(.err)
        let result = (either.eitherT >>- { n in Either<L, String?>.right(.some("\(n)")).eitherT }).rawValue
        #expect(result == .left(.err))
    }

    // MARK: - EitherTResult

    @Test func eitherTResultBindRightSuccess() {
        let either: Either<L, Result<Int, E>> = .right(.success(5))
        let result = (either.eitherT >>- { n in Either<L, Result<String, E>>.right(.success("\(n)")).eitherT }).rawValue
        #expect(result == .right(.success("5")))
    }

    @Test func eitherTResultBindRightFailure() {
        let either: Either<L, Result<Int, E>> = .right(.failure(.fail))
        let result = (either.eitherT >>- { n in Either<L, Result<String, E>>.right(.success("\(n)")).eitherT }).rawValue
        #expect(result == .right(.failure(.fail)))
    }

    @Test func eitherTResultBindLeft() {
        let either: Either<L, Result<Int, E>> = .left(.err)
        let result = (either.eitherT >>- { n in Either<L, Result<String, E>>.right(.success("\(n)")).eitherT }).rawValue
        #expect(result == .left(.err))
    }

    // MARK: - EitherTStateful

    @Test func eitherTStatefulApply() {
        let eithF: Either<L, Stateful<Int, @Sendable (Int) -> String>> = .right(.pure { "\($0)" })
        let eithA: Either<L, Stateful<Int, Int>> = .right(.get)
        let result = (eithF.eitherT <*> eithA.eitherT).rawValue
        if case let .right(s) = result { #expect(s.eval(5) == "5") } else { Issue.record("Expected .right") }
    }

    @Test func eitherTStatefulSeqRight() {
        let lhs: Either<L, Stateful<Int, Int>> = .right(.pure(1))
        let rhs: Either<L, Stateful<Int, String>> = .right(.pure("hello"))
        let result = (lhs.eitherT *> rhs.eitherT).rawValue
        if case let .right(s) = result { #expect(s.eval(0) == "hello") } else { Issue.record("Expected .right") }
    }

    @Test func eitherTStatefulSeqLeft() {
        let lhs: Either<L, Stateful<Int, Int>> = .right(.pure(99))
        let rhs: Either<L, Stateful<Int, String>> = .right(.pure("ignored"))
        let result = (lhs.eitherT <* rhs.eitherT).rawValue
        if case let .right(s) = result { #expect(s.eval(0) == 99) } else { Issue.record("Expected .right") }
    }

    // MARK: - EitherTWriter

    @Test func eitherTWriterBindRight() {
        let either: Either<L, Writer<[String], Int>> = .right(Writer(5, ["outer"]))
        let fn: @Sendable (Int) -> Either<L, Writer<[String], String>> = { n in .right(Writer("\(n)", ["inner"])) }
        #expect((either.eitherT >>- { fn($0).eitherT }).rawValue == .right(Writer("5", ["outer", "inner"])))
    }

    @Test func eitherTWriterBindLeft() {
        let either: Either<L, Writer<[String], Int>> = .left(.err)
        let fn: @Sendable (Int) -> Either<L, Writer<[String], String>> = { n in .right(Writer("\(n)", ["inner"])) }
        #expect((either.eitherT >>- { fn($0).eitherT }).rawValue == .left(.err))
    }

    @Test func eitherTWriterBindContinuationFails() {
        let either: Either<L, Writer<[String], Int>> = .right(Writer(5, ["outer"]))
        let fn: @Sendable (Int) -> Either<L, Writer<[String], String>> = const(.left(.err))
        #expect((either.eitherT >>- { fn($0).eitherT }).rawValue == .left(.err))
    }

    @Test func eitherTWriterFlippedBind() {
        let either: Either<L, Writer<[String], Int>> = .right(Writer(5, ["outer"]))
        let fn: @Sendable (Int) -> Either<L, Writer<[String], String>> = { n in .right(Writer("\(n)", ["inner"])) }
        #expect(({ fn($0).eitherT } -<< either.eitherT).rawValue == .right(Writer("5", ["outer", "inner"])))
    }

    @Test func eitherTWriterKleisli() {
        let f: @Sendable (Int) -> Either<L, Writer<[String], Int>> = { n in .right(Writer(n + 1, ["f"])) }
        let g: @Sendable (Int) -> Either<L, Writer<[String], String>> = { n in .right(Writer("\(n)", ["g"])) }
        #expect(({ f($0).eitherT } >=> { g($0).eitherT })(4).rawValue == .right(Writer("5", ["f", "g"])))
    }

    @Test func eitherTWriterReverseKleisli() {
        let f: @Sendable (Int) -> Either<L, Writer<[String], Int>> = { n in .right(Writer(n + 1, ["f"])) }
        let g: @Sendable (Int) -> Either<L, Writer<[String], String>> = { n in .right(Writer("\(n)", ["g"])) }
        #expect(({ g($0).eitherT } <=< { f($0).eitherT })(4).rawValue == .right(Writer("5", ["f", "g"])))
    }

    @Test func eitherTWriterApply() {
        let eithF: Either<L, Writer<[String], @Sendable (Int) -> String>> = .right(Writer({ @Sendable in "\($0)" }, ["fn"]))
        let eithA: Either<L, Writer<[String], Int>> = .right(Writer(7, ["val"]))
        let result = (eithF.eitherT <*> eithA.eitherT).rawValue
        #expect(result == .right(Writer("7", ["fn", "val"])))
    }

    @Test func eitherTWriterSeqRight() {
        let lhs: Either<L, Writer<[String], Int>> = .right(Writer(1, ["a"]))
        let rhs: Either<L, Writer<[String], String>> = .right(Writer("hello", ["b"]))
        let result = (lhs.eitherT *> rhs.eitherT).rawValue
        #expect(result == .right(Writer("hello", ["a", "b"])))
    }

    @Test func eitherTWriterSeqLeft() {
        let lhs: Either<L, Writer<[String], Int>> = .right(Writer(99, ["a"]))
        let rhs: Either<L, Writer<[String], String>> = .right(Writer("ignored", ["b"]))
        let result = (lhs.eitherT <* rhs.eitherT).rawValue
        #expect(result == .right(Writer(99, ["a", "b"])))
    }
}
