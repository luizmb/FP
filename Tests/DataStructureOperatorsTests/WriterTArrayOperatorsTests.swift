// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterTArrayOperatorsTests {
    @Test func fmap() {
        let w = Writer<[String], [Int]>([1, 2, 3], ["log"])
        let result = { $0 * 2 } <£^> w
        #expect(result.value == [2, 4, 6])
        #expect(result.log == ["log"])
    }

    @Test func flippedFmap() {
        let w = Writer<[String], [Int]>([1, 2, 3], ["log"])
        let result = w <&^> { $0 * 2 }
        #expect(result.value == [2, 4, 6])
        #expect(result.log == ["log"])
    }

    @Test func apply() {
        let wf = Writer<[String], [@Sendable (Int) -> Int]>([{ $0 + 1 }, { $0 * 10 }], ["fn"])
        let wa = Writer<[String], [Int]>([1, 2], ["val"])
        let result = wf <*> wa
        #expect(result.value == [2, 3, 10, 20])
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs = Writer<[String], [Int]>([1, 2], ["a"])
        let rhs = Writer<[String], [String]>(["x", "y"], ["b"])
        let result = lhs *> rhs
        #expect(result.value == ["x", "y", "x", "y"])
        #expect(result.log == ["a", "b"])
    }
}
