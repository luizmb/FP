// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterTStatefulOperatorsTests {
    @Test func fmap() {
        let w = Writer<[String], Stateful<Int, Int>>(Stateful<Int, Int>.get, ["log"])
        let result = { $0 * 2 } <£^> w
        #expect(result.value.eval(5) == 10)
        #expect(result.log == ["log"])
    }

    @Test func flippedFmap() {
        let w = Writer<[String], Stateful<Int, Int>>(Stateful<Int, Int>.get, ["log"])
        let result = w <&^> { $0 * 2 }
        #expect(result.value.eval(5) == 10)
        #expect(result.log == ["log"])
    }

    @Test func apply() {
        let fn: @Sendable (Int) -> String = { "\($0)" }
        let wf = Writer<[String], Stateful<Int, @Sendable (Int) -> String>>(
            Stateful<Int, @Sendable (Int) -> String>.pure(fn),
            ["fn"]
        )
        let wa = Writer<[String], Stateful<Int, Int>>(Stateful<Int, Int>.get, ["val"])
        let result = wf <*> wa
        #expect(result.value.eval(9) == "9")
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs = Writer<[String], Stateful<Int, Int>>(Stateful<Int, Int>.get, ["a"])
        let rhs = Writer<[String], Stateful<Int, String>>(Stateful<Int, String>.pure("done"), ["b"])
        let result = lhs *> rhs
        #expect(result.value.eval(0) == "done")
        #expect(result.log == ["a", "b"])
    }

    @Test func seqLeft() {
        let lhs = Writer<[String], Stateful<Int, Int>>(Stateful<Int, Int>.get, ["a"])
        let rhs = Writer<[String], Stateful<Int, String>>(Stateful<Int, String>.pure("done"), ["b"])
        let result = lhs <* rhs
        #expect(result.value.eval(7) == 7)
        #expect(result.log == ["a", "b"])
    }
}
