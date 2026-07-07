// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct ValidationTNonEmptyTests {
    // MARK: - Validation<E, NonEmpty<A>> — mapTValidationNonEmpty

    @Test func fmapT_success() {
        let v: Validation<String, NonEmpty<Int>> = .success(NonEmpty(head: 1, tail: [2, 3]))
        let result = mapTValidationNonEmpty { $0 * 10 }(v)
        #expect(result == .success(NonEmpty(head: 10, tail: [20, 30])))
    }

    @Test func fmapT_failure_propagates() {
        let v: Validation<String, NonEmpty<Int>> = .failure("err")
        let result = mapTValidationNonEmpty { $0 * 10 }(v)
        #expect(result == .failure("err"))
    }
}
