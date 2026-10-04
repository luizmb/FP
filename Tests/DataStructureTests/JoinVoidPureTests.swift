// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

private enum LoadError: Error, Equatable {
    case network
}

@Suite struct PureSiblingsTests {
    @Test func validationPureIsSuccess() {
        #expect(Validation<[String], Int>.pure(3) == .success(3))
    }

    @Test func validationPureIsApplyIdentity() {
        // pure id <*> v == v
        let v: Validation<[String], Int> = .failure(["e"])
        let pureId = Validation<[String], @Sendable (Int) -> Int>.pure { $0 }
        #expect(Validation<[String], Int>.apply(pureId, v) == v)
    }

    @Test func loadingPureIsLoaded() {
        #expect(Loading<Int, LoadError>.pure(3) == .loaded(3))
    }

    @Test func loadingPureIsZipIdentity() {
        let other: Loading<String, LoadError> = .loading(previous: "x")
        let zipped = Loading<(Int, String), LoadError>.zip(.pure(1), other)
        #expect(zipped.map(\.1) == other)
    }
}

@Suite struct JoinVoidSiblingsTests {
    // MARK: - NonEmpty

    @Test func joinNonEmptyConcatenates() {
        let nested = NonEmpty(head: NonEmpty(head: 1, tail: [2]), tail: [NonEmpty(head: 3, tail: [])])
        #expect(DataStructure.join(nested) == NonEmpty(head: 1, tail: [2, 3]))
    }

    @Test func voidNonEmptyKeepsLength() {
        #expect(DataStructure.void(NonEmpty(head: 1, tail: [2, 3])).count == 3)
    }

    // MARK: - These

    @Test func joinTheseAccumulates() {
        let nested: These<[String], These<[String], Int>> = .both(["a"], .both(["b"], 1))
        #expect(DataStructure.join(nested) == .both(["a", "b"], 1))
    }

    @Test func voidTheseKeepsShape() {
        let both: These<String, Int> = .both("a", 1)
        let this: These<String, Int> = .this("e")
        #expect(DataStructure.void(both).this == "a")
        #expect(DataStructure.void(both).that != nil)
        #expect(DataStructure.void(this).this == "e")
        #expect(DataStructure.void(this).that == nil)
    }

    // MARK: - Loading

    @Test func joinLoadingLoadedYieldsInner() {
        let nested: Loading<Loading<Int, LoadError>, LoadError> = .loaded(.failed(error: .network, previous: 1))
        #expect(DataStructure.join(nested) == .failed(error: .network, previous: 1))
    }

    @Test func joinLoadingIdlePassesThrough() {
        let nested: Loading<Loading<Int, LoadError>, LoadError> = .idle
        #expect(DataStructure.join(nested) == .idle)
    }

    @Test func voidLoadingKeepsState() {
        let failed: Loading<Int, LoadError> = .failed(error: .network, previous: 1)
        let voided = DataStructure.void(failed)
        #expect(voided.map(const(0)) == .failed(error: .network, previous: 0))
        #expect(DataStructure.void(Loading<Int, LoadError>.idle).map(const(0)) == .idle)
    }
}
