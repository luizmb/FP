import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ArrayTStatefulOperatorsTests {
    @Test func fmap() {
        let arr: [Stateful<Int, Int>] = [.get, .pure(10)]
        let result = { $0 * 2 } <£^> arr
        #expect(result[0].eval(5) == 10)
        #expect(result[1].eval(5) == 20)
    }

    @Test func flippedFmap() {
        let arr: [Stateful<Int, Int>] = [.get, .pure(10)]
        let result = arr <&^> { $0 * 2 }
        #expect(result[0].eval(5) == 10)
        #expect(result[1].eval(5) == 20)
    }

    @Test func bind() {
        let arr: [Stateful<Int, Int>] = [.pure(3), .pure(4)]
        let result = arr >>- { n in Stateful<Int, String>.pure("\(n)") }
        #expect(result[0].eval(0) == "3")
        #expect(result[1].eval(0) == "4")
    }

    @Test func kleisli() {
        let f: (Int) -> [Stateful<Int, Int>] = { n in [.pure(n), .pure(n + 1)] }
        let g: (Int) -> Stateful<Int, String> = { n in .pure("\(n)") }
        let results = (f >=> g)(3)
        #expect(results[0].eval(0) == "3")
        #expect(results[1].eval(0) == "4")
    }

    @Test func apply() {
        let fns: [Stateful<Int, (Int) -> String>] = [.pure({ "\($0)" })]
        let vals: [Stateful<Int, Int>] = [.pure(5)]
        let result = fns <*> vals
        #expect(result.count == 1)
        #expect(result[0].eval(0) == "5")
    }

    @Test func seqRight() {
        let lhs: [Stateful<Int, Int>] = [.pure(1)]
        let rhs: [Stateful<Int, String>] = [.pure("hello")]
        let result = lhs *> rhs
        #expect(result.count == 1)
        #expect(result[0].eval(0) == "hello")
    }

    @Test func seqLeft() {
        let lhs: [Stateful<Int, Int>] = [.pure(99)]
        let rhs: [Stateful<Int, String>] = [.pure("ignored")]
        let result = lhs <* rhs
        #expect(result.count == 1)
        #expect(result[0].eval(0) == 99)
    }
}
