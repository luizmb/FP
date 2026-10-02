// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Loading {
    // MARK: Applicative (derived from bind, so `<*> == ap` as Haskell requires)

    //
    // Left-biased and short-circuiting, like PureScript's `RemoteData`: the right side only
    // matters when the left is `.loaded`. For the UI rule "show the failure if either request
    // failed", use ``pessimisticCombine(_:_:)`` instead; it is deliberately not the applicative.

    /// Pairs two `Loading` values: `liftA2 (,)`, i.e. `left >>= { l in right.map { (l, $0) } }`.
    static func zip<Left: Sendable, Right: Sendable>(
        _ left: Loading<Left, Failure>,
        _ right: Loading<Right, Failure>
    ) -> Loading<(Left, Right), Failure>
    where Success == (Left, Right) {
        left.flatMap { l in right.map { r in (l, r) } }
    }

    /// Triples three `Loading` values, left to right, with the same rules as ``zip(_:_:)``.
    static func zip3<A1: Sendable, A2: Sendable, A3: Sendable>(
        _ first: Loading<A1, Failure>,
        _ second: Loading<A2, Failure>,
        _ third: Loading<A3, Failure>
    ) -> Loading<(A1, A2, A3), Failure>
    where Success == (A1, A2, A3) {
        Loading<(A1, A2), Failure>.zip(first, second).flatMap { ab in third.map { c in (ab.0, ab.1, c) } }
    }

    /// Quadruples four `Loading` values, left to right, with the same rules as ``zip(_:_:)``.
    static func zip4<A1: Sendable, A2: Sendable, A3: Sendable, A4: Sendable>(
        _ first: Loading<A1, Failure>,
        _ second: Loading<A2, Failure>,
        _ third: Loading<A3, Failure>,
        _ fourth: Loading<A4, Failure>
    ) -> Loading<(A1, A2, A3, A4), Failure>
    where Success == (A1, A2, A3, A4) {
        Loading<(A1, A2, A3), Failure>.zip3(first, second, third).flatMap { abc in fourth.map { d in (abc.0, abc.1, abc.2, d) } }
    }

    /// `ap`: applies a `Loading`-wrapped function to a `Loading`-wrapped argument.
    /// (<*>) :: Loading e (a -> b) -> Loading e a -> Loading e b
    static func apply<A: Sendable>(
        _ fnLoading: Loading<@Sendable (A) -> Success, Failure>,
        _ argLoading: Loading<A, Failure>
    ) -> Loading<Success, Failure> {
        fnLoading.flatMap { fn in argLoading.map(fn) }
    }

    /// liftA2 :: (a -> b -> c) -> Loading e a -> Loading e b -> Loading e c
    static func liftA2<A: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (A, B) -> Success
    ) -> @Sendable (Loading<A, Failure>, Loading<B, Failure>) -> Loading<Success, Failure> {
        { left, right in left.flatMap { a in right.map { b in fn(a, b) } } }
    }
}

public extension Loading {
    /// seqRight :: Loading e a -> Loading e b -> Loading e b (derived from bind)
    func seqRight<B: Sendable>(_ rhs: Loading<B, Failure>) -> Loading<B, Failure> {
        Loading<B, Failure>.liftA2 { _, b in b }(self, rhs)
    }

    /// seqLeft :: Loading e a -> Loading e b -> Loading e a (derived from bind)
    func seqLeft<B: Sendable>(_ rhs: Loading<B, Failure>) -> Loading<Success, Failure> {
        Loading<Success, Failure>.liftA2 { a, _ in a }(self, rhs)
    }
}

// MARK: - Pessimistic combine (UI rule, not the applicative)

public extension Loading {
    /// Combines two requests for one screen, pessimistically. Precedence, first match wins:
    /// 1. Either side `.failed` → `.failed` with the first error found, and the pair of
    ///    `loadedOrPrevious` values when both sides have one.
    /// 2. Either side `.idle` → `.idle`.
    /// 3. Either side `.loading` → `.loading`, `previous` paired as above.
    /// 4. Both `.loaded` → `.loaded` with the pair.
    ///
    /// This checks both sides, so it is not `<*>`/``zip(_:_:)`` (those are left-biased and follow
    /// bind). Use it when the screen should show a failure as soon as any request failed.
    static func pessimisticCombine<Left: Sendable, Right: Sendable>(
        _ left: Loading<Left, Failure>,
        _ right: Loading<Right, Failure>
    ) -> Loading<(Left, Right), Failure>
    where Success == (Left, Right) {
        switch (left, right) {
        case let (.failed(err, _), _),
             let (_, .failed(err, _)):
            .failed(error: err, previous: (Left, Right)?.zip(left.loadedOrPrevious, right.loadedOrPrevious))

        case (.idle, _),
             (_, .idle):
            .idle

        case let (.loading(l), _):
            .loading(previous: (Left, Right)?.zip(l, right.loadedOrPrevious))

        case let (_, .loading(r)):
            .loading(previous: (Left, Right)?.zip(left.loadedOrPrevious, r))

        case let (.loaded(l), .loaded(r)):
            .loaded((l, r))
        }
    }

    /// Three-way ``pessimisticCombine(_:_:)``, same precedence.
    static func pessimisticCombine<A1: Sendable, A2: Sendable, A3: Sendable>(
        _ first: Loading<A1, Failure>,
        _ second: Loading<A2, Failure>,
        _ third: Loading<A3, Failure>
    ) -> Loading<(A1, A2, A3), Failure>
    where Success == (A1, A2, A3) {
        let firstTwo = Loading<(A1, A2), Failure>.pessimisticCombine(first, second)
        return Loading<((A1, A2), A3), Failure>.pessimisticCombine(firstTwo, third).map { abc in (abc.0.0, abc.0.1, abc.1) }
    }

    /// Four-way ``pessimisticCombine(_:_:)``, same precedence.
    static func pessimisticCombine<A1: Sendable, A2: Sendable, A3: Sendable, A4: Sendable>(
        _ first: Loading<A1, Failure>,
        _ second: Loading<A2, Failure>,
        _ third: Loading<A3, Failure>,
        _ fourth: Loading<A4, Failure>
    ) -> Loading<(A1, A2, A3, A4), Failure>
    where Success == (A1, A2, A3, A4) {
        let firstThree = Loading<(A1, A2, A3), Failure>.pessimisticCombine(first, second, third)
        return Loading<((A1, A2, A3), A4), Failure>.pessimisticCombine(firstThree, fourth)
            .map { abcd in (abcd.0.0, abcd.0.1, abcd.0.2, abcd.1) }
    }
}
