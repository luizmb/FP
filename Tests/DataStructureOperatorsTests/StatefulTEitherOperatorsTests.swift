import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct StatefulTEitherOperatorsTests {
    @Test func fmapRight() {
        let s = Stateful<Int, Either<String, Int>>.pure(.right(5))
        let result: Stateful<Int, Either<String, Int>> = { $0 * 2 } <£^> s
        #expect(result.eval(0) == .right(10))
    }

    @Test func flippedFmapRight() {
        let s = Stateful<Int, Either<String, Int>>.pure(.right(5))
        let result: Stateful<Int, Either<String, Int>> = s <&^> { $0 * 2 }
        #expect(result.eval(0) == .right(10))
    }

    @Test func fmapLeft() {
        let s = Stateful<Int, Either<String, Int>>.pure(.left("err"))
        let result: Stateful<Int, Either<String, Int>> = { $0 * 2 } <£^> s
        #expect(result.eval(0) == .left("err"))
    }

    @Test func apply() {
        let sf = Stateful<Int, Either<String, (Int) -> String>>.pure(.right { "\($0)" })
        let sa = Stateful<Int, Either<String, Int>>.pure(.right(42))
        let result = sf <*> sa
        #expect(result.eval(0) == .right("42"))
    }

    @Test func seqRight() {
        let lhs = Stateful<Int, Either<String, Int>>.pure(.right(1))
        let rhs = Stateful<Int, Either<String, String>>.pure(.right("b"))
        let result = lhs *> rhs
        #expect(result.eval(0) == .right("b"))
    }

    @Test func seqLeft() {
        let lhs = Stateful<Int, Either<String, Int>>.pure(.right(1))
        let rhs = Stateful<Int, Either<String, String>>.pure(.right("b"))
        let result = lhs <* rhs
        #expect(result.eval(0) == .right(1))
    }

    @Test func bind() {
        let s = Stateful<Int, Either<String, Int>>.pure(.right(5))
        let result = s >>- { n in Stateful<Int, Either<String, String>>.pure(.right("\(n)")) }
        #expect(result.eval(0) == .right("5"))
    }

    @Test func bindLeft() {
        let s = Stateful<Int, Either<String, Int>>.pure(.left("err"))
        let result = s >>- { n in Stateful<Int, Either<String, String>>.pure(.right("\(n)")) }
        #expect(result.eval(0) == .left("err"))
    }

    @Test func kleisli() {
        let f: (Int) -> Stateful<Int, Either<String, Int>> = { n in .pure(.right(n + 1)) }
        let g: (Int) -> Stateful<Int, Either<String, String>> = { n in .pure(.right("\(n)")) }
        let result = (f >=> g)(4)
        #expect(result.eval(0) == .right("5"))
    }
}
