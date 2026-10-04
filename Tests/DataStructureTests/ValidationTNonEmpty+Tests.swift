// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct ValidationTNonEmptyTests {
    // MARK: - Validation<E, NonEmpty<A>> — mapT

    @Test func fmapT_success() {
        let v: Validation<String, NonEmpty<Int>> = .success(NonEmpty(head: 1, tail: [2, 3]))
        let result = v.mapT { $0 * 10 }
        #expect(result == .success(NonEmpty(head: 10, tail: [20, 30])))
    }

    @Test func fmapT_failure_propagates() {
        let v: Validation<String, NonEmpty<Int>> = .failure("err")
        let result = v.mapT { $0 * 10 }
        #expect(result == .failure("err"))
    }
}
