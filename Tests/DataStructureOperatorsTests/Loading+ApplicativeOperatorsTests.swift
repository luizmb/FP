// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

private enum TestError: Error, Equatable {
    case network
    case decoding
}

private typealias Sut = Loading<Int, TestError>

@Suite("Loading — Applicative operators")
struct LoadingApplicativeOperatorTests {
    @Test func apply_bothLoaded_appliesFunction() {
        // (<*>) :: Loading<(a -> b), e> -> Loading<a, e> -> Loading<b, e>
        let fn: Loading<@Sendable (Int) -> String, TestError> = .loaded { "value \($0)" }
        let result = fn <*> Sut.loaded(5)
        #expect(result == .loaded("value 5"))
    }

    @Test func apply_failedTrumpsLoaded() {
        let fn: Loading<@Sendable (Int) -> String, TestError> = .failed(error: .network, previous: nil)
        let result = fn <*> Sut.loaded(5)
        guard case let .failed(err, prev) = result else {
            Issue.record("Expected .failed"); return
        }
        #expect(err == .network)
        #expect(prev == nil)
    }

    @Test func apply_idleTrumpsLoaded() {
        let fn: Loading<@Sendable (Int) -> String, TestError> = .idle
        let result = fn <*> Sut.loaded(5)
        if case .idle = result { /* expected */ } else {
            Issue.record("Expected .idle")
        }
    }

    @Test func seqRight_keepsRightValue() {
        // (*>) :: Loading<a, e> -> Loading<b, e> -> Loading<b, e>
        let left: Sut = .loaded(1)
        let right: Loading<String, TestError> = .loaded("a")
        #expect((left *> right) == .loaded("a"))
    }

    @Test func seqRight_failedOnLeft_propagatesFailure() {
        let left: Sut = .failed(error: .network, previous: 1)
        let right: Loading<String, TestError> = .loaded("a")
        let result = left *> right
        guard case let .failed(err, _) = result else {
            Issue.record("Expected .failed"); return
        }
        #expect(err == .network)
    }

    @Test func seqLeft_keepsLeftValue() {
        // (<*) :: Loading<a, e> -> Loading<b, e> -> Loading<a, e>
        let left: Sut = .loaded(1)
        let right: Loading<String, TestError> = .loaded("a")
        #expect((left <* right) == .loaded(1))
    }

    @Test func seqLeft_failedOnRight_propagatesFailure() {
        let left: Sut = .loaded(1)
        let right: Loading<String, TestError> = .failed(error: .decoding, previous: nil)
        let result = left <* right
        guard case let .failed(err, _) = result else {
            Issue.record("Expected .failed"); return
        }
        #expect(err == .decoding)
    }
}
