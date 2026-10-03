// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct WriterTNonEmptyTests {
    // MARK: - Writer<W, NonEmpty<A>> — mapT (functor)

    @Test func mapT() {
        let w = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1, tail: [2, 3]), ["log"])
        let result = w.mapT { $0 * 10 }
        #expect(result.value == NonEmpty(head: 10, tail: [20, 30]))
        #expect(result.log == ["log"])
    }

    @Test func fmapT_curried() {
        let w = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 5), ["entry"])
        let result = Writer<[String], NonEmpty<Int>>.fmapT { $0 + 1 }(w)
        #expect(result.value == NonEmpty(head: 6))
        #expect(result.log == ["entry"])
    }
}
