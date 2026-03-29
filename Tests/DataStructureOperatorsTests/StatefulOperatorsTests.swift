import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct StatefulOperatorsTests {
    // MARK: - Functor operators

    @Test func fmapOperator() {
        let s = Stateful<Int, Int>.get
        let mapped = { $0 * 2 } <£> s
        #expect(mapped.eval(5) == 10)
    }

    @Test func flippedFmapOperator() {
        let s = Stateful<Int, Int>.get
        let mapped = s <&> { $0 + 1 }
        #expect(mapped.eval(3) == 4)
    }

    @Test func replaceRightOperator() {
        let s = Stateful<Int, Int>.get
        let replaced = s £> "hello"
        #expect(replaced.eval(0) == "hello")
    }

    @Test func replaceLeftOperator() {
        let s = Stateful<Int, Int>.get
        let replaced = "world" <£ s
        #expect(replaced.eval(0) == "world")
    }

    // MARK: - Applicative operators

    @Test func applyOperator() {
        let sf = Stateful<Int, (Int) -> String>.pure { "\($0)" }
        let sa = Stateful<Int, Int>.get
        let result = sf <*> sa
        #expect(result.eval(9) == "9")
    }

    @Test func seqRightOperator() {
        let incr = Stateful<Int, Void>.modify { $0 + 1 }
        let getValue = Stateful<Int, Int>.get
        let result = incr *> getValue
        #expect(result.eval(4) == 5)
    }

    @Test func seqLeftOperator() {
        let getValue = Stateful<Int, Int>.get
        let incr = Stateful<Int, Void>.modify { $0 + 1 }
        let result = getValue <* incr
        // returns the value before increment
        #expect(result.eval(4) == 4)
        #expect(result.exec(4) == 5)
    }

    // MARK: - Monad operators

    @Test func bindOperator() {
        let s = Stateful<Int, Int>.get
        let result = s >>- { value in
            Stateful<Int, String> { state in
                state += value
                return "\(value)"
            }
        }
        let (output, finalState) = result.runStateful(3)
        #expect(output == "3")
        #expect(finalState == 6)
    }

    @Test func reversedBindOperator() {
        let fn: (Int) -> Stateful<Int, String> = { value in
            Stateful<Int, String>.pure("\(value)")
        }
        let s = Stateful<Int, Int>.get
        let result = fn -<< s
        #expect(result.eval(7) == "7")
    }

    @Test func kleisliOperator() {
        let addOne: (Int) -> Stateful<Int, Int> = { n in .pure(n + 1) }
        let toString: (Int) -> Stateful<Int, String> = { n in .pure("\(n)") }
        let composed = addOne >=> toString
        #expect(composed(4).eval(0) == "5")
    }
}
