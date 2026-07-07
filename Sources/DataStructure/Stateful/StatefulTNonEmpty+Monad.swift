// SPDX-License-Identifier: Apache-2.0
// StatefulTNonEmpty: outer = Stateful, inner = NonEmpty
// Type: Stateful<S, NonEmpty<A>>

public extension Stateful {
    /// Declaration.
    func flatMapT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Stateful<S, NonEmpty<B>?>
    ) -> Stateful<S, NonEmpty<B>?> where A == NonEmpty<Inner> {
        Stateful<S, NonEmpty<B>?> { s in
            let results = self.run(&s).toArray.map { fn($0).run(&s) }
            let nonEmpties = results.compactMap(\.self)
            let combined: NonEmpty<B>? = nonEmpties.first.map { first in
                nonEmpties.dropFirst().reduce(first, NonEmpty.combine)
            }
            return combined
        }
    }

    /// The `property` property.
    static func bindT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Stateful<S, NonEmpty<B>?>
    ) -> (Stateful<S, NonEmpty<Inner>>) -> Stateful<S, NonEmpty<B>?>
    where A == NonEmpty<Inner> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `StatefulT + NonEmpty` (left-to-right)
///
/// Both arrows share the same optional-returning shape so `>=>`/`<=<` compose
/// associatively (matching `EitherTNonEmpty`/`ReaderTNonEmpty`/`WriterTNonEmpty`) —
/// `fn1` cannot be non-optional here, or a further `>=> fn3` composition would not typecheck.
/// (>=>) :: (a -> Stateful<s, NonEmpty<b>?>) -> (b -> Stateful<s, NonEmpty<c>?>) -> a -> Stateful<s, NonEmpty<c>?>
public func kleisliT<S, A: Sendable, B: Sendable, C>(
    _ fn1: @escaping @Sendable (A) -> Stateful<S, NonEmpty<B>?>,
    _ fn2: @escaping @Sendable (B) -> Stateful<S, NonEmpty<C>?>
) -> (A) -> Stateful<S, NonEmpty<C>?> {
    { a in
        Stateful<S, NonEmpty<C>?> { s in
            guard let nb = fn1(a).run(&s) else { return nil }
            // swiftlint:disable:next closure_ignoring_args unnecessary_single_param_closure
            let liftedNb = Stateful<S, NonEmpty<B>> { _ in nb } // `_` is inout S — `const` takes (T)->A not (inout T)->A
            return liftedNb.flatMapT(fn2).run(&s)
        }
    }
}
