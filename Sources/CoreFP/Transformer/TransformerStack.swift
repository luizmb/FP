// SPDX-License-Identifier: Apache-2.0

/// A monad-transformer stack wrapped in its own nominal type, e.g. `ReaderTArray<Env, A>` around
/// `Reader<Env, [A]>`.
///
/// Swift has no higher-kinded types, so a generic `ReaderT<Env, M, A>` can't be written. Each stack is
/// instead one concrete struct whose only stored property is the whole nested value (`rawValue`).
/// Wrapping the nested value gives every stack its own `map` / `<£>` / `<*>` / `>>-` without
/// colliding with the operators of the outer type (a `Reader<Env, [A]>` is still just a `Reader`).
///
/// - `O` is the whole nested value (`Reader<Env, [A]>`).
/// - `I` is the inner layer only (`[A]`).
///
/// Stacks without a lawful monad (see ``MonadT``) adopt only this protocol and expose the functor and
/// applicative surface, like Haskell's `Compose`.
///
/// The requirements mirror `RawRepresentable` (`rawValue`, non-failable `init(rawValue:)`) without
/// refining it: with Swift 6.3, a generic `RawRepresentable` struct whose `RawValue` is an `Optional`
/// (`OptionalTArray`'s `[A]?`) breaks type inference of every generic method returning the struct in a
/// contextual position (`let x: OptionalTArray<Int> = xs.map(f)` fails to type-check).
///
/// The protocol does not refine `Sendable` (a marker protocol cannot be conditionally inherited);
/// every conforming struct declares its own conditional `Sendable` conformance instead.
public protocol TransformerStack<O, I> {
    /// The whole nested value, e.g. `Reader<Env, [A]>`.
    associatedtype O
    /// The inner layer of the stack, e.g. `[A]` for `Reader<Env, [A]>`.
    associatedtype I

    /// The wrapped nested value.
    var rawValue: O { get }

    /// Wraps the nested value.
    init(rawValue: O)

    /// Wraps the nested value. Same as `init(rawValue:)`, unlabelled for point-free use.
    init(_ rawValue: O)
}

/// A ``TransformerStack`` that is a lawful monad: besides the functor and applicative surface it
/// exposes `flatMap`, `bind`, `kleisli` and `kleisliBack` (and the `>>-`, `-<<`, `>=>`, `<=<` operators).
public protocol MonadT<O, I>: TransformerStack {}
