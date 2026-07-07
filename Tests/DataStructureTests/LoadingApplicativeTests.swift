// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// MARK: - Test fixtures

private enum LoadingApplicativeTestError: Error, Equatable {
    case network
    case decoding
}

@Suite("Loading — apply / liftA2 / seqRight / seqLeft")
struct LoadingApplicativeMethodsTests {
    fileprivate typealias L<A: Sendable> = Loading<A, LoadingApplicativeTestError>

    // MARK: - apply

    @Test func apply_bothLoaded_appliesFunction() {
        let fn: L<@Sendable (Int) -> String> = .loaded { "value \($0)" }
        let arg: L<Int> = .loaded(5)
        let result = L<String>.apply(fn, arg)
        #expect(result == .loaded("value 5"))
    }

    @Test func apply_failedTrumpsLoaded() {
        let fn: L<@Sendable (Int) -> String> = .failed(error: .network, previous: nil)
        let arg: L<Int> = .loaded(5)
        let result = L<String>.apply(fn, arg)
        guard case let .failed(err, prev) = result else {
            Issue.record("Expected .failed"); return
        }
        #expect(err == .network)
        #expect(prev == nil)
    }

    @Test func apply_idleTrumpsLoaded() {
        let fn: L<@Sendable (Int) -> String> = .idle
        let arg: L<Int> = .loaded(5)
        let result = L<String>.apply(fn, arg)
        if case .idle = result { /* expected */ } else {
            Issue.record("Expected .idle")
        }
    }

    @Test func apply_loadingCarriesMappedPrevious() {
        let fn: L<@Sendable (Int) -> String> = .loading(previous: nil)
        let arg: L<Int> = .loaded(5)
        let result = L<String>.apply(fn, arg)
        if case .loading = result { /* expected */ } else {
            Issue.record("Expected .loading")
        }
    }

    // MARK: - liftA2

    @Test func liftA2_bothLoaded_combinesValues() {
        let combine = L<Int>.liftA2 { (a: Int, b: Int) in a + b }
        let left: L<Int> = .loaded(2)
        let right: L<Int> = .loaded(3)
        #expect(combine(left, right) == .loaded(5))
    }

    @Test func liftA2_failedTrumpsEverything() {
        let combine = L<Int>.liftA2 { (a: Int, b: Int) in a + b }
        let left: L<Int> = .idle
        let right: L<Int> = .failed(error: .decoding, previous: nil)
        let result = combine(left, right)
        guard case let .failed(err, prev) = result else {
            Issue.record("Expected .failed"); return
        }
        #expect(err == .decoding)
        #expect(prev == nil)
    }

    @Test func liftA2_idleTrumpsLoading() {
        let combine = L<Int>.liftA2 { (a: Int, b: Int) in a + b }
        let left: L<Int> = .idle
        let right: L<Int> = .loading(previous: 1)
        if case .idle = combine(left, right) { /* expected */ } else {
            Issue.record("Expected .idle")
        }
    }

    // MARK: - seqRight

    @Test func seqRight_bothLoaded_returnsRightValue() {
        let left: L<Int> = .loaded(1)
        let right: L<String> = .loaded("a")
        #expect(left.seqRight(right) == .loaded("a"))
    }

    @Test func seqRight_failedOnLeft_propagatesFailure() {
        let left: L<Int> = .failed(error: .network, previous: 1)
        let right: L<String> = .loaded("a")
        let result = left.seqRight(right)
        guard case let .failed(err, _) = result else {
            Issue.record("Expected .failed"); return
        }
        #expect(err == .network)
    }

    @Test func seqRight_oneIdle_isIdle() {
        let left: L<Int> = .loaded(1)
        let right: L<String> = .idle
        if case .idle = left.seqRight(right) { /* expected */ } else {
            Issue.record("Expected .idle")
        }
    }

    // MARK: - seqLeft

    @Test func seqLeft_bothLoaded_returnsLeftValue() {
        let left: L<Int> = .loaded(1)
        let right: L<String> = .loaded("a")
        #expect(left.seqLeft(right) == .loaded(1))
    }

    @Test func seqLeft_failedOnRight_propagatesFailure() {
        let left: L<Int> = .loaded(1)
        let right: L<String> = .failed(error: .decoding, previous: nil)
        let result = left.seqLeft(right)
        guard case let .failed(err, _) = result else {
            Issue.record("Expected .failed"); return
        }
        #expect(err == .decoding)
    }

    @Test func seqLeft_oneLoading_isLoading() {
        let left: L<Int> = .loaded(1)
        let right: L<String> = .loading(previous: nil)
        if case .loading = left.seqLeft(right) { /* expected */ } else {
            Issue.record("Expected .loading")
        }
    }
}
