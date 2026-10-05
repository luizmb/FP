// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterTReaderOperatorsTests {
    @Test func apply() {
        let wf = Writer<[String], Reader<Int, @Sendable (Int) -> String>>(Reader { env in { "\(env + $0)" } }, ["fn"])
        let wa = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["val"])
        let result = (wf.writerT <*> wa.writerT).rawValue
        #expect(result.value(5) == "10")
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["a"])
        let rhs = Writer<[String], Reader<Int, String>>(Reader(const("done")), ["b"])
        let result = (lhs.writerT *> rhs.writerT).rawValue
        #expect(result.value(0) == "done")
        #expect(result.log == ["a", "b"])
    }
}
