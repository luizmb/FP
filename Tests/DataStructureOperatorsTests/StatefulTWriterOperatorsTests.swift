// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

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
        let result = s >>- { (n: Int) in
            Stateful<Int, Writer<[String], String>> { state in
                state *= 10
                return Writer("\(n)", ["inner"])
            }
        }
        let (w, finalState) = result.runStateful(5)
        #expect(w.value == "5")
        #expect(w.log == ["outer", "inner"])
        #expect(finalState == 60)
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> Stateful<Int, Writer<[String], Int>> = { n in
            Stateful<Int, Writer<[String], Int>>.pure(Writer(n + 1, ["f"]))
        }
        let g: @Sendable (Int) -> Stateful<Int, Writer<[String], String>> = { n in
            Stateful { state in
                state += n
                return Writer("\(n)", ["g"])
            }
        }
        let (w, finalState) = (f >=> g)(4).runStateful(1)
        #expect(w.value == "5")
        #expect(w.log == ["f", "g"])
        #expect(finalState == 6)
    }
}
