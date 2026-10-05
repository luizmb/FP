# Migrating to 3.0

What changed since 2.x, with the replacements, and the places where code keeps compiling but means something different now.

## Overview

Version 3.0 follows one policy: Haskell is the source of truth. A monad surface exists only where `transformers` defines one, `<*>` is `ap` wherever there is a monad, bind takes a continuation over the full stack, and the Compose-style (zip) applicative is a separate named function, never the operator. Most of the list below is that policy being applied.

## Transformers are structs now

A stack is its own struct (`ReaderTEither`, `StatefulTWriter`, …) instead of a nested value with `mapT`/`flatMapT` free functions. Wrap the nested value in the stack to use the operators (`reader.readerT`, or `ReaderTEither(reader)`) and leave with `.rawValue`. See <doc:MonadTransformers>.

## Silent meaning changes

These keep compiling and do something different, so check them first.

- Operators on a bare nested value now resolve to the outer type: `*>` on `Stateful<S, Either<L, A>>`, `<£>` and `>>-` on `Reader<E, [A]>`, `£>` on `Reader<_, [A]>`, `>>-` on `Stateful<S, A>?`. Wrap the value in its stack to act on the inner layer.
- `<*>`, `liftA2`, `*>` and `<*` on `Publisher` and `AsyncStream` are `ap` (cartesian, sequential), no longer a zip. Use `zip` to pair. Bind is ordered concat, not merge, and `AsyncStream`'s `<*>` buffers the right stream, so it must be finite.
- `Loading`'s `zip`, `<*>` and friends are left-biased `ap`. The old "failed beats loading beats idle" rule is `pessimisticCombine`.
- `Validation`'s `<|>` accumulates both failures when both sides fail.
- `Gen` needs an injected random number generator. There is no `generate()` that creates one for you, see <doc:Gen>.

## Removed operators

| Removed | Use instead |
|---|---|
| `a ++ b` | `a <> b` |
| `f £ x` (infix) | `f <\| x` |
| `x ^ n` (infix power) | `power(x, n)` |
| `f <£^> x`, `x <&^> f` | `f <£> x.readerT` (wrap in the stack) |
| transformer `£>` and `<£` on a bare nested value | `stack £> v` on the stack struct |

## Conversions

Conversions follow one convention: `to…()` going out of a type and `init(_:)` going in (`either.toResult()`, `Validation(either)`, `either.toValidation()`, `These(either)`, `Loading(result)`, `Zipper(nonEmpty)`).

## Smaller things

`NonEmpty` and `IdentifiedArray` need `Sendable` elements, and `Zipper.left` and `Zipper.right` are lazy views.
