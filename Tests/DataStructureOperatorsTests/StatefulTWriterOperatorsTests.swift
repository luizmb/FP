// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct StatefulTWriterOperatorsTests {
    @Test func bind() {
        let s = Stateful<Int, Writer<[String], Int>> { state in
            let v = state
            state += 1
            return Writer(v, ["outer"])
        }
        let result = s.statefulT >>- { (n: Int) in
            StatefulTWriter(Stateful<Int, Writer<[String], String>> { state in
                state *= 10
                return Writer("\(n)", ["inner"])
            })
        }
        let (w, finalState) = result.rawValue.runStateful(5)
        #expect(w.value == "5")
        #expect(w.log == ["outer", "inner"])
        #expect(finalState == 60)
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> StatefulTWriter<Int, [String], Int> = { n in
            StatefulTWriter(Stateful<Int, Writer<[String], Int>>.pure(Writer(n + 1, ["f"])))
        }
        let g: @Sendable (Int) -> StatefulTWriter<Int, [String], String> = { n in
            StatefulTWriter(Stateful { state in
                state += n
                return Writer("\(n)", ["g"])
            })
        }
        let (w, finalState) = (f >=> g)(4).rawValue.runStateful(1)
        #expect(w.value == "5")
        #expect(w.log == ["f", "g"])
        #expect(finalState == 6)
    }
}
