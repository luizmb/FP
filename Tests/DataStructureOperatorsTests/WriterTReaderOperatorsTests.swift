// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterTReaderOperatorsTests {
    @Test func fmap() {
        let w = Writer<[String], Reader<Int, Int>>(Reader { $0 * 2 }, ["log"])
        let result = { $0 + 1 } <£^> w
        #expect(result.value(3) == 7)
        #expect(result.log == ["log"])
    }

    @Test func flippedFmap() {
        let w = Writer<[String], Reader<Int, Int>>(Reader { $0 * 2 }, ["log"])
        let result = w <&^> { $0 + 1 }
        #expect(result.value(3) == 7)
        #expect(result.log == ["log"])
    }

    @Test func apply() {
        let wf = Writer<[String], Reader<Int, @Sendable (Int) -> String>>(Reader { env in { "\(env + $0)" } }, ["fn"])
        let wa = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["val"])
        let result = wf <*> wa
        #expect(result.value(5) == "10")
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["a"])
        let rhs = Writer<[String], Reader<Int, String>>(Reader(const("done")), ["b"])
        let result = lhs *> rhs
        #expect(result.value(0) == "done")
        #expect(result.log == ["a", "b"])
    }
}
