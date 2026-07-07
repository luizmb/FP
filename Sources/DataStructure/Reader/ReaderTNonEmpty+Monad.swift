// SPDX-License-Identifier: Apache-2.0
// ReaderTNonEmpty: outer = Reader, inner = NonEmpty
// Type: Reader<Environment, NonEmpty<A>>

public extension Reader {
    /// Declaration.
    func flatMapT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Reader<Environment, NonEmpty<B>?>
    ) -> Reader<Environment, NonEmpty<B>?> where Output == NonEmpty<Inner> {
        Reader<Environment, NonEmpty<B>?> { env in
            let results = self.runReader(env).toArray.map { fn($0).runReader(env) }
            let nonEmpties = results.compactMap(\.self)
            return nonEmpties.first.map { first in
                nonEmpties.dropFirst().reduce(first, NonEmpty.combine)
            }
        }
    }

    /// The `property` property.
    static func bindT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Reader<Environment, NonEmpty<B>?>
    ) -> (Reader<Environment, NonEmpty<Inner>>) -> Reader<Environment, NonEmpty<B>?>
    where Output == NonEmpty<Inner> {
        { $0.flatMapT(fn) }
    }
}

/// Kleisli composition for `ReaderT + NonEmpty` (left-to-right)
/// (>=>) :: (a -> Reader<env, NonEmpty<b>?>) -> (b -> Reader<env, NonEmpty<c>?>) -> a -> Reader<env, NonEmpty<c>?>
///
/// Both arrows already return the fold-and-combine `NonEmpty<_>?` shape produced by `flatMapT`,
/// so composition re-applies the same "run + collect + NonEmpty.combine fold" idiom starting
/// from the (already optional) result of `fn1`, short-circuiting to `nil` if it is empty.
public func kleisliT<Env, A, B, C>(
    _ fn1: @escaping @Sendable (A) -> Reader<Env, NonEmpty<B>?>,
    _ fn2: @escaping @Sendable (B) -> Reader<Env, NonEmpty<C>?>
) -> (A) -> Reader<Env, NonEmpty<C>?> {
    { a in
        let readerB = fn1(a)
        return Reader<Env, NonEmpty<C>?> { env in
            guard let nonEmptyB = readerB.runReader(env) else { return nil }
            let results = nonEmptyB.toArray.map { fn2($0).runReader(env) }
            let nonEmpties = results.compactMap(\.self)
            return nonEmpties.first.map { first in
                nonEmpties.dropFirst().reduce(first, NonEmpty.combine)
            }
        }
    }
}
