import CoreFP
import DataStructure
import Testing

// MARK: - Test fixtures

private enum TestError: Error, Equatable, Hashable {
    case network
    case decoding
}

private typealias Sut = Loading<Int, TestError>

// MARK: - Construction & accessors

@Suite("Loading — construction & accessors")
struct LoadingConstructionTests {
    @Test func loadedOrPrevious_idle_isNil() {
        let sut: Sut = .idle
        #expect(sut.loadedOrPrevious == nil)
    }

    @Test func loadedOrPrevious_loadingWithoutPrevious_isNil() {
        let sut: Sut = .loading(previous: nil)
        #expect(sut.loadedOrPrevious == nil)
    }

    @Test func loadedOrPrevious_loadingWithPrevious_returnsPrevious() {
        let sut: Sut = .loading(previous: 42)
        #expect(sut.loadedOrPrevious == 42)
    }

    @Test func loadedOrPrevious_loaded_returnsValue() {
        let sut: Sut = .loaded(100)
        #expect(sut.loadedOrPrevious == 100)
    }

    @Test func loadedOrPrevious_failedWithPrevious_returnsPrevious() {
        let sut: Sut = .failed(error: .network, previous: 7)
        #expect(sut.loadedOrPrevious == 7)
    }

    @Test func loadedOrPrevious_failedWithoutPrevious_isNil() {
        let sut: Sut = .failed(error: .network, previous: nil)
        #expect(sut.loadedOrPrevious == nil)
    }
}

// MARK: - Equatable / Hashable

@Suite("Loading — Equatable / Hashable")
struct LoadingEqualityTests {
    @Test func equalCases_areEqual() {
        #expect(Sut.idle == .idle)
        #expect(Sut.loading(previous: 1) == .loading(previous: 1))
        #expect(Sut.loaded(2) == .loaded(2))
        #expect(Sut.failed(error: .network, previous: 3) == .failed(error: .network, previous: 3))
    }

    @Test func differentPrevious_areNotEqual() {
        #expect(Sut.loading(previous: 1) != .loading(previous: 2))
        #expect(Sut.failed(error: .network, previous: 1) != .failed(error: .network, previous: 2))
    }

    @Test func differentErrors_areNotEqual() {
        #expect(Sut.failed(error: .network, previous: nil) != .failed(error: .decoding, previous: nil))
    }

    @Test func differentCases_areNotEqual() {
        #expect(Sut.idle != .loaded(0))
        #expect(Sut.loaded(0) != .loading(previous: 0))
    }

    @Test func hashable_equalValuesHaveEqualHashes() {
        let a: Sut = .failed(error: .network, previous: 5)
        let b: Sut = .failed(error: .network, previous: 5)
        var ah = Hasher(); a.hash(into: &ah)
        var bh = Hasher(); b.hash(into: &bh)
        #expect(ah.finalize() == bh.finalize())
    }
}

// MARK: - Prism namespace

@Suite("Loading — prism namespace")
struct LoadingPrismTests {
    @Test func preview_idle_hits() {
        #expect(Sut.prism.idle.preview(.idle) != nil)
        #expect(Sut.prism.idle.preview(.loaded(1)) == nil)
    }

    @Test func preview_loading_returnsPrevious() {
        #expect(Sut.prism.loading.preview(.loading(previous: 42)) == .some(.some(42)))
        // hit with no previous still hits — focus is `Success?`
        #expect(Sut.prism.loading.preview(.loading(previous: nil)) == .some(nil))
        // miss returns nil
        #expect(Sut.prism.loading.preview(.idle) == nil)
    }

    @Test func preview_loaded_returnsValue() {
        #expect(Sut.prism.loaded.preview(.loaded(7)) == 7)
        #expect(Sut.prism.loaded.preview(.idle) == nil)
    }

    @Test func preview_failed_returnsErrorAndPrevious() {
        let hit = Sut.prism.failed.preview(.failed(error: .network, previous: 3))
        #expect(hit?.0 == .network)
        #expect(hit?.1 == 3)
        #expect(Sut.prism.failed.preview(.loaded(0)) == nil)
    }

    @Test func review_reconstructs() {
        #expect(Sut.prism.idle.review(()) == .idle)
        #expect(Sut.prism.loading.review(9) == .loading(previous: 9))
        #expect(Sut.prism.loaded.review(11) == .loaded(11))
        #expect(Sut.prism.failed.review((.network, 5)) == .failed(error: .network, previous: 5))
    }

    @Test func law_previewReview() {
        // preview(review(a)) == a
        #expect(Sut.prism.loaded.preview(Sut.prism.loaded.review(42)) == 42)
        #expect(Sut.prism.failed.preview(Sut.prism.failed.review((.decoding, 9)))?.0 == .decoding)
    }

    @Test func law_setOnWrongCase_isNoop() {
        let updated = Sut.prism.loaded.set(.idle, 42)
        #expect(updated == .idle)
    }

    @Test func over_transformsMatchingCase() {
        let doubled = Sut.prism.loaded.over { $0 * 2 }(.loaded(5))
        #expect(doubled == .loaded(10))
    }

    @Test func caseKeyPath_recoversPrism() {
        let prism = Prism(\.loaded as PrismKeyPath<Sut, Int>)
        #expect(prism.preview(.loaded(42)) == 42)
        #expect(prism.preview(.idle) == nil)
    }
}

// MARK: - cases enum + is(_:)

@Suite("Loading — cases enum and is(_:)")
struct LoadingCasesTests {
    @Test func cases_isCaseIterable() {
        #expect(Sut.Cases.allCases == [.idle, .loading, .loaded, .failed])
    }

    @Test func is_returnsTrue_whenAligned() {
        let s: Sut = .loading(previous: nil)
        #expect(s.is(.loading) == true)
        #expect(Sut.idle.is(.idle) == true)
        #expect(Sut.loaded(1).is(.loaded) == true)
        #expect(Sut.failed(error: .network, previous: nil).is(.failed) == true)
    }

    @Test func is_returnsFalse_whenCasesDiffer() {
        #expect(Sut.idle.is(.loaded) == false)
        #expect(Sut.loaded(1).is(.failed) == false)
        #expect(Sut.failed(error: .network, previous: nil).is(.idle) == false)
    }

    @Test func is_ignoresAssociatedPayload() {
        #expect(Sut.loading(previous: nil).is(.loading) == true)
        #expect(Sut.loading(previous: 42).is(.loading) == true)
        #expect(Sut.failed(error: .network, previous: 0).is(.failed) == true)
        #expect(Sut.failed(error: .decoding, previous: 99).is(.failed) == true)
    }
}

// MARK: - Transitions

@Suite("Loading — transitions")
struct LoadingTransitionTests {
    @Test func startLoading_fromIdle_hasNoPrevious() {
        let sut: Sut = .idle
        #expect(sut.startLoading() == .loading(previous: nil))
    }

    @Test func startLoading_fromLoaded_carriesPrevious() {
        let sut: Sut = .loaded(42)
        #expect(sut.startLoading() == .loading(previous: 42))
    }

    @Test func startLoading_fromFailedWithPrevious_carriesPrevious() {
        let sut: Sut = .failed(error: .network, previous: 7)
        #expect(sut.startLoading() == .loading(previous: 7))
    }

    @Test func applying_success_transitionsToLoaded() {
        let sut: Sut = .loading(previous: 1)
        #expect(sut.applying(.success(99)) == .loaded(99))
    }

    @Test func applying_failure_preservesLoadedOrPrevious() {
        let sut: Sut = .loaded(42)
        #expect(sut.applying(.failure(.network)) == .failed(error: .network, previous: 42))
    }

    @Test func applying_failure_fromIdle_hasNoPrevious() {
        let sut: Sut = .idle
        #expect(sut.applying(.failure(.network)) == .failed(error: .network, previous: nil))
    }

    @Test func from_success_hasNoPrevious() {
        #expect(Sut.from(.success(7)) == .loaded(7))
    }

    @Test func from_failure_hasNoPrevious() {
        #expect(Sut.from(.failure(.decoding)) == .failed(error: .decoding, previous: nil))
    }
}

// MARK: - Functor

@Suite("Loading — Functor")
struct LoadingFunctorTests {
    @Test func map_loaded_transformsValue() {
        let sut: Sut = .loaded(5)
        #expect(sut.map { $0 * 2 } == .loaded(10))
    }

    @Test func map_idle_passesThrough() {
        let sut: Sut = .idle
        #expect(sut.map { $0 * 2 } == .idle)
    }

    @Test func map_loadingWithPrevious_mapsPrevious() {
        let sut: Sut = .loading(previous: 3)
        #expect(sut.map { $0 * 2 } == .loading(previous: 6))
    }

    @Test func map_loadingWithoutPrevious_passesThrough() {
        let sut: Sut = .loading(previous: nil)
        #expect(sut.map { $0 * 2 } == .loading(previous: nil))
    }

    @Test func map_failedWithPrevious_mapsPrevious() {
        let sut: Sut = .failed(error: .network, previous: 4)
        #expect(sut.map { $0 * 2 } == .failed(error: .network, previous: 8))
    }

    @Test func fmap_curriedForm() {
        let double = Sut.fmap { $0 * 2 }
        #expect(double(.loaded(5)) == .loaded(10))
        #expect(double(.idle) == .idle)
    }

    // Functor laws

    @Test func functorIdentityLaw() {
        // fmap id == id
        let values: [Sut] = [.idle, .loading(previous: 1), .loaded(2), .failed(error: .network, previous: 3)]
        for v in values {
            // swiftlint:disable:next array_init
            #expect(v.map { $0 } == v)
        }
    }

    @Test func functorCompositionLaw() {
        // fmap (f . g) == fmap f . fmap g
        let f: @Sendable (Int) -> Int = { $0 + 1 }
        let g: @Sendable (Int) -> Int = { $0 * 2 }
        let values: [Sut] = [.idle, .loading(previous: 1), .loaded(2), .failed(error: .network, previous: 3)]
        for v in values {
            #expect(v.map { f(g($0)) } == v.map(g).map(f))
        }
    }
}

// MARK: - Applicative (zip)

@Suite("Loading — Applicative.zip")
struct LoadingApplicativeTests {
    fileprivate typealias L<A: Sendable> = Loading<A, TestError>

    @Test func zip_bothLoaded_returnsPair() {
        let left: L<Int> = .loaded(1)
        let right: L<String> = .loaded("a")
        let result = L<(Int, String)>.zip(left, right)
        guard case .loaded(let pair) = result else {
            Issue.record("Expected .loaded"); return
        }
        #expect(pair.0 == 1)
        #expect(pair.1 == "a")
    }

    @Test func zip_idleWins_overLoaded() {
        let left: L<Int> = .idle
        let right: L<String> = .loaded("a")
        let result = L<(Int, String)>.zip(left, right)
        if case .idle = result { /* expected */ } else {
            Issue.record("Expected .idle")
        }
    }

    @Test func zip_failedTrumpsIdle() {
        let left: L<Int> = .idle
        let right: L<String> = .failed(error: .network, previous: "stale")
        let result = L<(Int, String)>.zip(left, right)
        // Failed always wins; previous pair is nil because left has none.
        guard case .failed(let err, let prev) = result else {
            Issue.record("Expected .failed"); return
        }
        #expect(err == .network)
        #expect(prev == nil)
    }

    @Test func zip_loadingPairsPrevious() {
        let left: L<Int> = .loading(previous: 1)
        let right: L<String> = .loaded("a")
        let result = L<(Int, String)>.zip(left, right)
        guard case .loading(let prev) = result else {
            Issue.record("Expected .loading"); return
        }
        #expect(prev?.0 == 1)
        #expect(prev?.1 == "a")
    }

    @Test func zip_failedPairsLoadedOrPreviousBothSides() {
        let left: L<Int> = .failed(error: .network, previous: 1)
        let right: L<String> = .loaded("a")
        let result = L<(Int, String)>.zip(left, right)
        guard case .failed(let err, let prev) = result else {
            Issue.record("Expected .failed"); return
        }
        #expect(err == .network)
        #expect(prev?.0 == 1)
        #expect(prev?.1 == "a")
    }
}

// MARK: - Monad

@Suite("Loading — Monad")
struct LoadingMonadTests {
    @Test func flatMap_loaded_chains() {
        let sut: Sut = .loaded(5)
        let result = sut.flatMap { Sut.loaded($0 * 2) }
        #expect(result == .loaded(10))
    }

    @Test func flatMap_idle_passesThrough() {
        let sut: Sut = .idle
        let result: Sut = sut.flatMap { _ in .loaded(99) }
        #expect(result == .idle)
    }

    @Test func flatMap_loaded_intoFailure() {
        let sut: Sut = .loaded(5)
        let result: Sut = sut.flatMap { _ in .failed(error: .network, previous: nil) }
        #expect(result == .failed(error: .network, previous: nil))
    }

    @Test func flatMap_loadingPreservesPreviousViaMapping() {
        let sut: Sut = .loading(previous: 3)
        let result = sut.flatMap { Sut.loaded($0 * 2) }
        // previous=3 → f(3) = .loaded(6) → loadedOrPrevious = 6
        #expect(result == .loading(previous: 6))
    }

    @Test func flatMap_failedPreservesError() {
        let sut: Sut = .failed(error: .network, previous: 4)
        let result = sut.flatMap { Sut.loaded($0 * 2) }
        guard case .failed(let err, let prev) = result else {
            Issue.record("Expected .failed"); return
        }
        #expect(err == .network)
        #expect(prev == 8)
    }

    // Monad laws

    @Test func leftIdentity() {
        // return a >>= f == f a
        let f: @Sendable (Int) -> Sut = { .loaded($0 * 2) }
        #expect(Sut.loaded(5).flatMap(f) == f(5))
    }

    @Test func rightIdentity() {
        // m >>= return == m
        let m: Sut = .loaded(5)
        #expect(m.flatMap { .loaded($0) } == m)
    }

    @Test func associativity() {
        // (m >>= f) >>= g == m >>= (\x -> f x >>= g)
        let m: Sut = .loaded(2)
        let f: @Sendable (Int) -> Sut = { .loaded($0 + 1) }
        let g: @Sendable (Int) -> Sut = { .loaded($0 * 10) }
        #expect(m.flatMap(f).flatMap(g) == m.flatMap { f($0).flatMap(g) })
    }

    @Test func kleisli_composesLeftToRight() {
        let f: @Sendable (Int) -> Sut = { .loaded($0 + 1) }
        let g: @Sendable (Int) -> Sut = { .loaded($0 * 10) }
        let fg = Sut.kleisli(f, g)
        #expect(fg(2) == .loaded(30))
    }

    @Test func kleisliBack_composesRightToLeft() {
        let f: @Sendable (Int) -> Sut = { .loaded($0 + 1) }
        let g: @Sendable (Int) -> Sut = { .loaded($0 * 10) }
        let gf = Sut.kleisliBack(g, f)
        #expect(gf(2) == .loaded(30))
    }
}

// MARK: - Catch

@Suite("Loading — Catch")
struct LoadingCatchTests {
    @Test func catch_failed_appliesTransform() {
        let sut: Sut = .failed(error: .network, previous: nil)
        let recovered = sut.catch { _ in .loaded(99) }
        #expect(recovered == .loaded(99))
    }

    @Test func catch_loaded_passesThrough() {
        let sut: Sut = .loaded(5)
        let recovered = sut.catch { _ in .loaded(99) }
        #expect(recovered == .loaded(5))
    }

    @Test func catch_idle_passesThrough() {
        let sut: Sut = .idle
        let recovered = sut.catch { _ in .loaded(99) }
        #expect(recovered == .idle)
    }

    @Test func catch_loading_passesThrough() {
        let sut: Sut = .loading(previous: 1)
        let recovered = sut.catch { _ in .loaded(99) }
        #expect(recovered == .loading(previous: 1))
    }

    @Test func catch_canMapErrorToAnotherFailure() {
        let sut: Sut = .failed(error: .network, previous: 7)
        let recovered = sut.catch { _ in .failed(error: .decoding, previous: nil) }
        #expect(recovered == .failed(error: .decoding, previous: nil))
    }
}
