// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Loading {
    /// Combines two `Loading` values sharing a `Failure` type into a `Loading` of the pair.
    ///
    /// Precedence — first match wins:
    /// 1. If either side is `.failed`, the result is `.failed` carrying the first error
    ///    encountered and a pair of `loadedOrPrevious` values when both sides have one.
    /// 2. If either side is `.idle`, the result is `.idle`.
    /// 3. If either side is `.loading`, the result is `.loading`, with `previous` set to the
    ///    pair of `loadedOrPrevious` values when both sides have one.
    /// 4. Otherwise both sides are `.loaded` and the result is `.loaded` with the pair.
    static func zip<Left: Sendable, Right: Sendable>(
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

    /// Combines three `Loading` values sharing a `Failure` type into a `Loading` of the triple.
    /// Built from `zip(_:_:)` and `liftA2(_:)`, so it follows the same precedence:
    /// `.failed` beats `.idle` beats `.loading` beats `.loaded`.
    static func zip3<A1: Sendable, A2: Sendable, A3: Sendable>(
        _ first: Loading<A1, Failure>,
        _ second: Loading<A2, Failure>,
        _ third: Loading<A3, Failure>
    ) -> Loading<(A1, A2, A3), Failure>
    where Success == (A1, A2, A3) {
        Loading<(A1, A2, A3), Failure>.liftA2 { ab, c in (ab.0, ab.1, c) }(
            Loading<(A1, A2), Failure>.zip(first, second),
            third
        )
    }

    /// Combines four `Loading` values sharing a `Failure` type into a `Loading` of the quadruple.
    /// Built from `zip3(_:_:_:)` and `liftA2(_:)`, preserving the same precedence:
    /// `.failed` beats `.idle` beats `.loading` beats `.loaded`.
    static func zip4<A1: Sendable, A2: Sendable, A3: Sendable, A4: Sendable>(
        _ first: Loading<A1, Failure>,
        _ second: Loading<A2, Failure>,
        _ third: Loading<A3, Failure>,
        _ fourth: Loading<A4, Failure>
    ) -> Loading<(A1, A2, A3, A4), Failure>
    where Success == (A1, A2, A3, A4) {
        Loading<(A1, A2, A3, A4), Failure>.liftA2 { abc, d in (abc.0, abc.1, abc.2, d) }(
            Loading<(A1, A2, A3), Failure>.zip3(first, second, third),
            fourth
        )
    }

    /// Applies a `Loading`-wrapped function to a `Loading`-wrapped argument, sharing a
    /// `Failure` type, following the same precedence rules as ``zip(_:_:)``: `.failed` beats
    /// `.idle` beats `.loading` beats `.loaded`.
    static func apply<A: Sendable>(
        _ fnLoading: Loading<@Sendable (A) -> Success, Failure>,
        _ argLoading: Loading<A, Failure>
    ) -> Loading<Success, Failure> {
        Loading<(@Sendable (A) -> Success, A), Failure>.zip(fnLoading, argLoading)
            .map { fn, arg in fn(arg) }
    }

    /// Curried `liftA2` for `Loading`, built from ``zip(_:_:)`` and ``map(_:)``.
    /// liftA2 :: (a -> b -> c) -> Loading<a, e> -> Loading<b, e> -> Loading<c, e>
    static func liftA2<A: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (A, B) -> Success
    ) -> @Sendable (Loading<A, Failure>, Loading<B, Failure>) -> Loading<Success, Failure> {
        { left, right in
            Loading<(A, B), Failure>.zip(left, right).map(fn)
        }
    }
}

public extension Loading {
    /// Runs both `Loading` values, discarding `self` and returning `rhs`, following the same
    /// precedence rules as ``zip(_:_:)``.
    /// seqRight :: Loading<a, e> -> Loading<b, e> -> Loading<b, e>
    func seqRight<B: Sendable>(_ rhs: Loading<B, Failure>) -> Loading<B, Failure> {
        Loading<B, Failure>.liftA2 { _, b in b }(self, rhs)
    }

    /// Runs both `Loading` values, discarding `rhs` and returning `self`, following the same
    /// precedence rules as ``zip(_:_:)``.
    /// seqLeft :: Loading<a, e> -> Loading<b, e> -> Loading<a, e>
    func seqLeft<B: Sendable>(_ rhs: Loading<B, Failure>) -> Loading<Success, Failure> {
        Loading<Success, Failure>.liftA2 { a, _ in a }(self, rhs)
    }
}
