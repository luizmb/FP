import DataStructureOperators
import DataStructure
import Testing
import CoreFPOperators
import CoreFP

@Suite struct StatefulTWriterOperatorsTests {

    @Test func fmap() {
        let s = Stateful<Int, Writer<[String], Int>> { state in Writer(state, ["x"]) }
        let result = { $0 * 2 } <£^> s
        let w = result.eval(4)
        #expect(w.value == 8)
        #expect(w.log == ["x"])
    }

    @Test func flippedFmap() {
        let s = Stateful<Int, Writer<[String], Int>> { state in Writer(state, ["x"]) }
        let result = s <&^> { $0 * 2 }
        let w = result.eval(4)
        #expect(w.value == 8)
        #expect(w.log == ["x"])
    }

    @Test func bind() {
        let s = Stateful<Int, Writer<[String], Int>> { state in
            let v = state
            state += 1
            return Writer(v, ["outer"])
        }
        let result = s >>- { n in Writer<[String], String>("\(n)", ["inner"]) }
        let (w, finalState) = result.runStateful(5)
        #expect(w.value == "5")
        #expect(w.log == ["outer", "inner"])
        #expect(finalState == 6)
    }

    @Test func kleisli() {
        let f: (Int) -> Stateful<Int, Writer<[String], Int>> = { n in
            Stateful { _ in Writer(n + 1, ["f"]) }
        }
        let g: (Int) -> Writer<[String], String> = { n in Writer("\(n)", ["g"]) }
        let result = f(4) >>- g
        let w = result.eval(0)
        #expect(w.value == "5")
        #expect(w.log == ["f", "g"])
    }
}
