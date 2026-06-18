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

    @Test func arrayTEitherMapT() {
        let arr: [Either<L, Int>] = [.right(1), .left(.err), .right(3)]
        let result = { $0 * 2 } <£^> arr
        #expect(result == [.right(2), .left(.err), .right(6)])
    }

    @Test func arrayTEitherFlatMapT() {
        let arr: [Either<L, Int>] = [.right(1), .left(.err), .right(2)]
        let result = arr >>- { n in [Either<L, Int>.right(n), .right(n * 10)] }
        #expect(result == [.right(1), .right(10), .left(.err), .right(2), .right(20)])
    }

    @Test func arrayTEitherLiftA2() {
        let a: [Either<L, Int>] = [.right(1), .right(2)]
        let b: [Either<L, Int>] = [.right(10), .right(20)]
        let result = liftA2ArrayEither(+)(a, b)
        #expect(result == [.right(11), .right(21), .right(12), .right(22)])
    }

    @Test func arrayTEitherFmapOperator() {
        let arr: [Either<L, Int>] = [.right(5), .left(.err)]
        let result = { $0 * 2 } <£^> arr
        #expect(result == [.right(10), .left(.err)])
    }

    @Test func arrayTEitherFlippedFmapOperator() {
        let arr: [Either<L, Int>] = [.right(5), .left(.err)]
        let result = arr <&^> { $0 * 2 }
        #expect(result == [.right(10), .left(.err)])
    }

    @Test func arrayTEitherBindOperator() {
        let arr: [Either<L, Int>] = [.right(1), .right(2)]
        let result = arr >>- { n in [Either<L, Int>.right(n * 2)] }
        #expect(result == [.right(2), .right(4)])
    }

    // MARK: - OptionalTEither

    @Test func optionalTEitherMapTSomeRight() {
        let opt: Either<L, Int>? = .right(5)
        let result = { $0 * 2 } <£^> opt
        #expect(result == .some(.right(10)))
    }

    @Test func optionalTEitherMapTSomeLeft() {
        let opt: Either<L, Int>? = .left(.err)
        let result = { $0 * 2 } <£^> opt
        #expect(result == .some(.left(.err)))
    }

    @Test func optionalTEitherMapTNone() {
        let opt: Either<L, Int>? = nil
        let result = { $0 * 2 } <£^> opt
        #expect(result == nil)
    }

    @Test func optionalTEitherFlatMapTNone() {
        let opt: Either<L, Int>? = nil
        let result = opt >>- { n in Either<L, String>.right("\(n)") }
        #expect(result == nil)
    }

    @Test func optionalTEitherFlatMapTSomeLeft() {
        let opt: Either<L, Int>? = .left(.err)
        let result = opt >>- { n in Either<L, String>.right("\(n)") }
        #expect(result == .some(.left(.err)))
    }

    @Test func optionalTEitherFlatMapTSomeRight() {
        let opt: Either<L, Int>? = .right(5)
        let result = opt >>- { n in Either<L, String>?.some(.right("\(n)")) }
        #expect(result == .some(.right("5")))
    }

    // MARK: - EitherTOptional

    @Test func eitherTOptionalMapTRightSome() {
        let either: Either<L, Int?> = .right(.some(5))
        let result = { $0 * 2 } <£^> either
        #expect(result == .right(.some(10)))
    }

    @Test func eitherTOptionalMapTRightNone() {
        let either: Either<L, Int?> = .right(.none)
        let result = { $0 * 2 } <£^> either
        #expect(result == .right(.none))
    }

    @Test func eitherTOptionalMapTLeft() {
        let either: Either<L, Int?> = .left(.err)
        let result = { $0 * 2 } <£^> either
        #expect(result == .left(.err))
    }

    @Test func eitherTOptionalFlatMapTRightSome() {
        let either: Either<L, Int?> = .right(.some(5))
        let result = either >>- { n in Either<L, String?>.right(.some("\(n)")) }
        #expect(result == .right(.some("5")))
    }

    @Test func eitherTOptionalFlatMapTRightNone() {
        let either: Either<L, Int?> = .right(.none)
        let result = either >>- { n in Either<L, String?>.right(.some("\(n)")) }
        #expect(result == .right(.none))
    }

    @Test func eitherTOptionalFlatMapTLeft() {
        let either: Either<L, Int?> = .left(.err)
        let result = either >>- { n in Either<L, String?>.right(.some("\(n)")) }
        #expect(result == .left(.err))
    }

    // MARK: - EitherTArray

    @Test func eitherTArrayMapTRight() {
        let either: Either<L, [Int]> = .right([1, 2, 3])
        let result = { $0 * 2 } <£^> either
        #expect(result == .right([2, 4, 6]))
    }

    @Test func eitherTArrayMapTLeft() {
        let either: Either<L, [Int]> = .left(.err)
        let result = { $0 * 2 } <£^> either
        #expect(result == .left(.err))
    }

    @Test func eitherTArrayFlatMapTRight() {
        let either: Either<L, [Int]> = .right([1, 2])
        let result = either >>- { n in Either<L, [String]>.right(["\(n)", "\(n * 10)"]) }
        #expect(result == .right(["1", "10", "2", "20"]))
    }

    @Test func eitherTArrayFlatMapTLeft() {
        let either: Either<L, [Int]> = .left(.err)
        let result = either >>- { (n: Int) in Either<L, [String]>.right(["\(n)"]) }
        #expect(result == .left(.err))
    }

    // MARK: - EitherTResult

    @Test func eitherTResultMapTRightSuccess() throws {
        let either: Either<L, Result<Int, E>> = .right(.success(5))
        let result = { $0 * 2 } <£^> either
        #expect(result == .right(.success(10)))
    }

    @Test func eitherTResultMapTRightFailure() {
        let either: Either<L, Result<Int, E>> = .right(.failure(.fail))
        let result = { $0 * 2 } <£^> either
        #expect(result == .right(.failure(.fail)))
    }

    @Test func eitherTResultMapTLeft() {
        let either: Either<L, Result<Int, E>> = .left(.err)
        let result = { $0 * 2 } <£^> either
        #expect(result == .left(.err))
    }

    @Test func eitherTResultFlatMapTRightSuccess() {
        let either: Either<L, Result<Int, E>> = .right(.success(5))
        let result = either >>- { n in Either<L, Result<String, E>>.right(.success("\(n)")) }
        #expect(result == .right(.success("5")))
    }

    @Test func eitherTResultFlatMapTRightFailure() {
        let either: Either<L, Result<Int, E>> = .right(.failure(.fail))
        let result = either >>- { n in Either<L, Result<String, E>>.right(.success("\(n)")) }
        #expect(result == .right(.failure(.fail)))
    }

    @Test func eitherTResultFlatMapTLeft() {
        let either: Either<L, Result<Int, E>> = .left(.err)
        let result = either >>- { n in Either<L, Result<String, E>>.right(.success("\(n)")) }
        #expect(result == .left(.err))
    }

    // MARK: - EitherTStateful

    @Test func eitherTStatefulMapTRight() {
        let either: Either<L, Stateful<Int, Int>> = .right(Stateful<Int, Int>.get)
        let result = { $0 * 2 } <£^> either
        if case .right(let s) = result { #expect(s.eval(5) == 10) } else { Issue.record("Expected .right") }
    }

    @Test func eitherTStatefulMapTLeft() {
        let either: Either<L, Stateful<Int, Int>> = .left(.err)
        let result: Either<L, Stateful<Int, Int>> = { $0 * 2 } <£^> either
        if case .left(let l) = result { #expect(l == .err) } else { Issue.record("Expected .left") }
    }

    @Test func eitherTStatefulFlatMapTRight() {
        let either: Either<L, Stateful<Int, Int>> = .right(Stateful<Int, Int>.get)
        let result = either >>- { n in Stateful<Int, String>.pure("\(n)") }
        if case .right(let s) = result { #expect(s.eval(7) == "7") } else { Issue.record("Expected .right") }
    }

    @Test func eitherTStatefulFlatMapTLeft() {
        let either: Either<L, Stateful<Int, Int>> = .left(.err)
        let result = either >>- { n in Stateful<Int, String>.pure("\(n)") }
        if case .left(let l) = result { #expect(l == .err) } else { Issue.record("Expected .left") }
    }

    @Test func eitherTStatefulKleisli() {
        let f: @Sendable (Int) -> Either<L, Stateful<Int, Int>> = { n in .right(Stateful<Int, Int>.pure(n + 1)) }
        let g: @Sendable (Int) -> Stateful<Int, String> = { n in Stateful<Int, String>.pure("\(n)") }
        let result = (f >=> g)(4)
        if case .right(let s) = result { #expect(s.eval(0) == "5") } else { Issue.record("Expected .right") }
    }

    @Test func eitherTStatefulApply() {
        let eithF: Either<L, Stateful<Int, @Sendable (Int) -> String>> = .right(.pure({ "\($0)" }))
        let eithA: Either<L, Stateful<Int, Int>> = .right(.get)
        let result = eithF <*> eithA
        if case .right(let s) = result { #expect(s.eval(5) == "5") } else { Issue.record("Expected .right") }
    }

    @Test func eitherTStatefulSeqRight() {
        let lhs: Either<L, Stateful<Int, Int>> = .right(.pure(1))
        let rhs: Either<L, Stateful<Int, String>> = .right(.pure("hello"))
        let result = lhs *> rhs
        if case .right(let s) = result { #expect(s.eval(0) == "hello") } else { Issue.record("Expected .right") }
    }

    @Test func eitherTStatefulSeqLeft() {
        let lhs: Either<L, Stateful<Int, Int>> = .right(.pure(99))
        let rhs: Either<L, Stateful<Int, String>> = .right(.pure("ignored"))
        let result = lhs <* rhs
        if case .right(let s) = result { #expect(s.eval(0) == 99) } else { Issue.record("Expected .right") }
    }

    // MARK: - EitherTWriter

    @Test func eitherTWriterMapTRight() {
        let either: Either<L, Writer<[String], Int>> = .right(Writer(5, ["log"]))
        let result = { $0 * 2 } <£^> either
        if case .right(let w) = result {
            #expect(w.value == 10)
            #expect(w.log == ["log"])
        } else { Issue.record("Expected .right") }
    }

    @Test func eitherTWriterMapTLeft() {
        let either: Either<L, Writer<[String], Int>> = .left(.err)
        let result = { $0 * 2 } <£^> either
        #expect(result == .left(.err))
    }

    @Test func eitherTWriterFlatMapTRight() {
        let either: Either<L, Writer<[String], Int>> = .right(Writer(5, ["outer"]))
        let result = either >>- { n in Writer<[String], String>("\(n)", ["inner"]) }
        if case .right(let w) = result {
            #expect(w.value == "5")
            #expect(w.log == ["outer", "inner"])
        } else { Issue.record("Expected .right") }
    }

    @Test func eitherTWriterFlatMapTLeft() {
        let either: Either<L, Writer<[String], Int>> = .left(.err)
        let result = either >>- { n in Writer<[String], String>("\(n)", ["inner"]) }
        #expect(result == .left(.err))
    }

    @Test func eitherTWriterKleisli() {
        let f: @Sendable (Int) -> Either<L, Writer<[String], Int>> = { n in .right(Writer(n + 1, ["f"])) }
        let g: @Sendable (Int) -> Writer<[String], String> = { n in Writer("\(n)", ["g"]) }
        let result = (f >=> g)(4)
        if case .right(let w) = result {
            #expect(w.value == "5")
            #expect(w.log == ["f", "g"])
        } else { Issue.record("Expected .right") }
    }

    @Test func eitherTWriterApply() {
        let eithF: Either<L, Writer<[String], @Sendable (Int) -> String>> = .right(Writer({ @Sendable in "\($0)" }, ["fn"]))
        let eithA: Either<L, Writer<[String], Int>> = .right(Writer(7, ["val"]))
        let result = eithF <*> eithA
        #expect(result == .right(Writer("7", ["fn", "val"])))
    }

    @Test func eitherTWriterSeqRight() {
        let lhs: Either<L, Writer<[String], Int>> = .right(Writer(1, ["a"]))
        let rhs: Either<L, Writer<[String], String>> = .right(Writer("hello", ["b"]))
        let result = lhs *> rhs
        #expect(result == .right(Writer("hello", ["a", "b"])))
    }

    @Test func eitherTWriterSeqLeft() {
        let lhs: Either<L, Writer<[String], Int>> = .right(Writer(99, ["a"]))
        let rhs: Either<L, Writer<[String], String>> = .right(Writer("ignored", ["b"]))
        let result = lhs <* rhs
        #expect(result == .right(Writer(99, ["a", "b"])))
    }
}
