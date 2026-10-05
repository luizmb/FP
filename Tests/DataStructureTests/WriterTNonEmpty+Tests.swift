// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct WriterTNonEmptyTests {
    // MARK: - WriterTNonEmpty — map (functor)

    @Test func map() {
        let w = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1, tail: [2, 3]), ["log"])
        let result = w.writerT.map { $0 * 10 }.rawValue
        #expect(result.value == NonEmpty(head: 10, tail: [20, 30]))
        #expect(result.log == ["log"])
    }

    @Test func fmapCurried() {
        let w = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 5), ["entry"])
        let result = WriterTNonEmpty<[String], Int>.fmap { $0 + 1 }(w.writerT).rawValue
        #expect(result.value == NonEmpty(head: 6))
        #expect(result.log == ["entry"])
    }
}
