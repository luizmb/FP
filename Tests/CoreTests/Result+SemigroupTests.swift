import Testing
@testable import Core

// A test error conforming to Monoid so we can exercise all 4 variants.
private struct Err: Error, Monoid, Equatable {
    let message: String
    static func combine(_ lhs: Err, _ rhs: Err) -> Err { Err(message: lhs.message + rhs.message) }
    static var identity: Err { Err(message: "") }
}

@Suite struct ResultSemigroupTests {

    // MARK: - Optimistic (Semigroup, Success: Semigroup)

    @Test func optimisticCombinesTwoSuccesses() {
        let a = Result<String, Err>.Monoids.Optimistic(.success("hello"))
        let b = Result<String, Err>.Monoids.Optimistic(.success(" world"))
        #expect(Result.Monoids.Optimistic.combine(a, b).rawValue == .success("hello world"))
    }

    @Test func optimisticPrefersSuccessOverFailure() {
        let s = Result<String, Err>.Monoids.Optimistic(.success("ok"))
        let f = Result<String, Err>.Monoids.Optimistic(.failure(Err(message: "err")))
        #expect(Result.Monoids.Optimistic.combine(s, f).rawValue == .success("ok"))
        #expect(Result.Monoids.Optimistic.combine(f, s).rawValue == .success("ok"))
    }

    @Test func optimisticPicksLeftForTwoFailures() {
        let f1 = Result<String, Err>.Monoids.Optimistic(.failure(Err(message: "first")))
        let f2 = Result<String, Err>.Monoids.Optimistic(.failure(Err(message: "second")))
        #expect(Result.Monoids.Optimistic.combine(f1, f2).rawValue == .failure(Err(message: "first")))
    }

    // MARK: - OptimisticCombining (Monoid, Success: Semigroup, Failure: Monoid)

    @Test func optimisticCombiningCombinesFailures() {
        let f1 = Result<String, Err>.Monoids.OptimisticCombining(.failure(Err(message: "A")))
        let f2 = Result<String, Err>.Monoids.OptimisticCombining(.failure(Err(message: "B")))
        #expect(Result.Monoids.OptimisticCombining.combine(f1, f2).rawValue == .failure(Err(message: "AB")))
    }

    @Test func optimisticCombiningIdentity() {
        let identity = Result<String, Err>.Monoids.OptimisticCombining.identity
        let s = Result<String, Err>.Monoids.OptimisticCombining(.success("ok"))
        #expect(Result.Monoids.OptimisticCombining.combine(identity, s).rawValue == .success("ok"))
        #expect(Result.Monoids.OptimisticCombining.combine(s, identity).rawValue == .success("ok"))
    }

    // MARK: - Pessimistic (Semigroup, Failure: Semigroup)

    @Test func pessimisticCombinesTwoFailures() {
        let f1 = Result<String, Err>.Monoids.Pessimistic(.failure(Err(message: "A")))
        let f2 = Result<String, Err>.Monoids.Pessimistic(.failure(Err(message: "B")))
        #expect(Result.Monoids.Pessimistic.combine(f1, f2).rawValue == .failure(Err(message: "AB")))
    }

    @Test func pessimisticPrefersFailureOverSuccess() {
        let s = Result<String, Err>.Monoids.Pessimistic(.success("ok"))
        let f = Result<String, Err>.Monoids.Pessimistic(.failure(Err(message: "err")))
        #expect(Result.Monoids.Pessimistic.combine(s, f).rawValue == .failure(Err(message: "err")))
        #expect(Result.Monoids.Pessimistic.combine(f, s).rawValue == .failure(Err(message: "err")))
    }

    @Test func pessimisticPicksLeftForTwoSuccesses() {
        let s1 = Result<String, Err>.Monoids.Pessimistic(.success("first"))
        let s2 = Result<String, Err>.Monoids.Pessimistic(.success("second"))
        #expect(Result.Monoids.Pessimistic.combine(s1, s2).rawValue == .success("first"))
    }

    // MARK: - PessimisticCombining (Monoid, Success: Monoid, Failure: Semigroup)

    @Test func pessimisticCombiningCombinesSuccesses() {
        let s1 = Result<String, Err>.Monoids.PessimisticCombining(.success("hello"))
        let s2 = Result<String, Err>.Monoids.PessimisticCombining(.success(" world"))
        #expect(Result.Monoids.PessimisticCombining.combine(s1, s2).rawValue == .success("hello world"))
    }

    @Test func pessimisticCombiningIdentity() {
        let identity = Result<String, Err>.Monoids.PessimisticCombining.identity
        let f = Result<String, Err>.Monoids.PessimisticCombining(.failure(Err(message: "err")))
        #expect(Result.Monoids.PessimisticCombining.combine(identity, f).rawValue == .failure(Err(message: "err")))
        #expect(Result.Monoids.PessimisticCombining.combine(f, identity).rawValue == .failure(Err(message: "err")))
    }
}
