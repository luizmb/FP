# Adding a transformer stack through the generator

Stacks are generated. You don't write the struct, its members or its operators: you make sure the nested-type functions it delegates to exist, add one line to the generator's table, run it, and write tests. The worked example adds `OptionalTValidation` (`Validation<E, A>?`), which doesn't exist yet.

## Contents

- What the generator produces
- Step 1: does it exist, and what kind is it
- Step 2: the nested-type functions
- Step 3: the inventory line
- Step 4: run, format, build
- Step 5: tests
- A brand-new layer
- Streams, errors and other special cases

## What the generator produces

`swift Scripts/GenerateTransformers.swift` writes, for each `Stack(.outer, .inner, kind)` in `inventory`:

- `Sources/<Module>/Transformer/Generated/<Outer>T<Inner>.swift`: the struct (`rawValue`, `init(rawValue:)`, `init(_:)`, typealiases `O` and `I`, conditional `Sendable`), the functor surface (`map`, static `fmap`), the applicative surface unless `.functor` (static `pure` / `apply` / `liftA2`, `seqRight`, `seqLeft`), the monad surface for `.monad` (`flatMap`, static `bind`, `kleisli`, `kleisliBack`), the escape hatch, and the lifting property on the outer type (`optional.optionalT`), constrained by the inner-shape protocol (`extension Optional where Wrapped: ValidationLike`).
- `Sources/<OperatorModule>/Transformer/Generated/<Outer>T<Inner>+Operators.swift`: `<£>`, `<&>`, `£>`, `<£`, `<*>`, `*>`, `<*`, and `>>-`, `-<<`, `>=>`, `<=<` for monads.

`<Module>` is `CoreFP` when both layers are CoreFP types (Array, Optional, Result, Publisher, AsyncStream), otherwise `DataStructure`. The generated directories are wiped and rewritten on every run, so a hand edit there is lost on the next run (and is a review blocker anyway). To change what every stack looks like, change the templates in the script.

## Step 1: does it exist, and what kind is it

Check `inventory` in `Scripts/GenerateTransformers.swift` and the matrix in `Sources/FP/FP.docc/Articles/MonadTransformers.md`.

Then pick the kind honestly:

- `.monad` (conforms to `MonadT`) only when the stack has a lawful monad.
- `.applicative` (conforms to `TransformerStack`) when it doesn't: anything with `Validation` (it accumulates, a bind would have to short-circuit), a list inside a non-commutative outer layer (`EitherTArray`, `StatefulTArray`, …: associativity fails), `Writer` outside another monad (no distributive law), a monad outside `Stateful`, `Stateful` outside anything but Reader / Publisher / AsyncStream.
- `.functor` when there's no lawful applicative either (`AsyncStreamTStateful`).

`OptionalTValidation` has `Validation` inside, so it's `.applicative`.

## Step 2: the nested-type functions

The generated members call functions on the nested type by name. They're `internal` (implementation, not API) and live in the stack's module, next to the DataStructure type involved (here `Sources/DataStructure/Validation/OptionalTValidation+Applicative.swift` and `+Functor.swift`). Names the generator expects, with `<Outer><Inner>` = `OptionalValidation`:

| Member | Calls |
|---|---|
| `map` | `rawValue.mapT(fn)`, a method on the outer type |
| `apply` | `applyOptionalValidation(ff, fa)` |
| `liftA2` | `liftA2OptionalValidation(fn)(lhs, rhs)` |
| `seqRight` / `seqLeft` | `seqRightOptionalValidation(lhs, rhs)` / `seqLeftOptionalValidation(lhs, rhs)` |
| `flatMap` (monads) | `rawValue.flatMapT { … }`, or the free `flatMapT<Outer><Inner>` with the `.freeFlatMap` override |

Implement each with the inner type's own functions, so the semantics stay the inner type's:

```swift
import FP

extension Optional {
    func mapT<E: Semigroup, Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Validation<E, B>?
    where Wrapped == Validation<E, Inner> {
        map(Validation<E, Inner>.fmap(fn))
    }

    static func fmapT<E: Semigroup, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Validation<E, Inner>?) -> Validation<E, B>?
    where Wrapped == Validation<E, Inner> {
        { $0.mapT(fn) }
    }
}

func applyOptionalValidation<E: Semigroup, A, B>(
    _ optionalF: Validation<E, @Sendable (A) -> B>?,
    _ optionalA: Validation<E, A>?
) -> Validation<E, B>? {
    optionalF.flatMap { validationF in optionalA.map { Validation.apply(validationF, $0) } }
}

func liftA2OptionalValidation<E: Semigroup, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Validation<E, A>?, Validation<E, B>?) -> Validation<E, C>? {
    { lhs, rhs in lhs.flatMap { va in rhs.map { vb in Validation.liftA2(fn)(va, vb) } } }
}

func seqRightOptionalValidation<E: Semigroup, A, B>(
    _ lhs: Validation<E, A>?,
    _ rhs: Validation<E, B>?
) -> Validation<E, B>? {
    lhs.flatMap { va in rhs.map { va.seqRight($0) } }
}

func seqLeftOptionalValidation<E: Semigroup, A, B>(
    _ lhs: Validation<E, A>?,
    _ rhs: Validation<E, B>?
) -> Validation<E, A>? {
    lhs.flatMap { va in rhs.map { va.seqLeft($0) } }
}
```

(The outer `Optional` short-circuits on `nil`, the inner `Validation` accumulates: that's the composed applicative, and it's what the tests should pin down.)

When a stack's functions can't follow those names or shapes, use an `Override` in the table instead of bending the functions:

- `.applyViaLiftA2`: no `apply…` function, derive `apply` from `liftA2`.
- `.freeFlatMap`: the bind is the free `flatMapT<Outer><Inner>(_:_:)` instead of a method.
- `.map(body)`, `.liftA2(body)`, `.flatMap(body)`, `.pure(body)`: a custom member body (stream stacks whose nested `mapT` returns `AsyncMapSequence`, a `pure` that must build a fresh stream per run, a `Stateful` `liftA2` that has to run both sides before the `@Sendable` body).

## Step 3: the inventory line

One line in `inventory`, in the section of the DataStructure type involved (the Validation one here), or the CoreFP section:

```swift-sketch
    Stack(.optional, .validation, .applicative),
    Stack(.validation, .array, .applicative),
```

`Stack.name` gives `OptionalTValidation`, the module comes from the layers, the lifting property from the outer layer (`.optionalT`), the escape hatch from the naming rule (outer Optional, inner Validation: neither rule 1 nor 2 applies, so it's `mapOptionalT`).

## Step 4: run, format, build

From the package root:

```bash
swift Scripts/GenerateTransformers.swift
mint run swiftformat --lint .
swift build 2>&1 | xcsift
```

The output is already formatted, so the lint must stay clean; if it doesn't, fix the template, not the output. Commit the script change, the nested functions and the regenerated sources together.

## Step 5: tests

Both targets, written against the struct API only (never the internal nested functions, which tests can't see without `@testable`, and which aren't the contract anyway). The examples use the existing `ReaderTValidation`; a new stack's tests look the same.

Named tests (`DataStructureTests` / `CoreFPTests`, no operator symbols): laws and semantics, comparing `rawValue`s (run function-like layers first):

```swift
import Testing

struct Env: Sendable { let limit: Int }

@Suite("ReaderTValidation")
struct ReaderTValidationTests {
    let env = Env(limit: 5)

    @Test func mapReachesTheInnerValue() {
        let stack = Reader<Env, Validation<[String], Int>> { .success($0.limit) }.readerT
        #expect(stack.map { $0 * 2 }.rawValue(env) == .success(10))
    }

    @Test func functorIdentity() {
        let stack = ReaderTValidation<Env, [String], Int>(Reader { .success($0.limit) })
        #expect(stack.map(id).rawValue(env) == stack.rawValue(env))
    }

    @Test func applyAccumulatesErrors() {
        let ff = ReaderTValidation<Env, [String], @Sendable (Int) -> Int>(Reader { _ in .failure(["f"]) })
        let fa = ReaderTValidation<Env, [String], Int>(Reader { _ in .failure(["a"]) })
        #expect(ReaderTValidation.apply(ff, fa).rawValue(env) == .failure(["f", "a"]))
    }

    @Test func escapeHatchReachesTheReader() {
        let stack = Reader<Env, Validation<[String], Int>> { .success($0.limit) }.readerT
        let local = stack.mapReaderT { $0.local { _ in Env(limit: 1) } }
        #expect(local.rawValue(env) == .success(1))
    }
}
```

Operator tests (`DataStructureOperatorsTests` / `CoreFPOperatorsTests`, must use the symbols), one assertion per operator against its named member:

```swift
@Suite("ReaderTValidation operators")
struct ReaderTValidationOperatorTests {
    let env = Env(limit: 3)
    let stack = Reader<Env, Validation<[String], Int>> { .success($0.limit) }.readerT
    let increment: @Sendable (Int) -> Int = { $0 + 1 }

    @Test func functorOperators() {
        #expect((increment <£> stack).rawValue(env) == stack.map(increment).rawValue(env))
        #expect((stack <&> increment).rawValue(env) == stack.map(increment).rawValue(env))
        #expect((stack £> "x").rawValue(env) == .success("x"))
    }

    @Test func applicativeOperators() {
        let other = ReaderTValidation<Env, [String], Int>(Reader { _ in .failure(["other"]) })
        #expect((stack *> other).rawValue(env) == stack.seqRight(other).rawValue(env))
        #expect((stack <* other).rawValue(env) == stack.seqLeft(other).rawValue(env))
    }
}
```

## A brand-new layer

A layer type that isn't in `enum Layer` yet needs a case and its entries in the `Layer` switches: type spelling (`type(around:)`), outer / inner context parameters, `outerPure`, `isCore`, the lifting extension (`lift`), and, if it can be an inner layer, an inner-shape protocol in `Sources/<Module>/Transformer/InnerShape.swift` (`XLike`, one conformer, identity requirements only, so lifting never copies) plus its `shape` entry. Then add stacks for it as above.

## Streams, errors and other special cases

- Streams (`Publisher`, `AsyncStream`): bind is ordered concat; the applicative is `ap` derived from it (each left element over the whole right stream), never zip. The right stream is single-pass, buffered with `AsyncStream.replayable(_:)`. A `pure` inside a function-like outer layer (`Reader`, `Stateful`) must build a fresh stream per run (`.pure` override). Availability annotations and `#if canImport(Combine)` come from the `Layer`, don't add them by hand.
- Error inner layers (`Result`, `Either`): keep the error type, short-circuit on the first failure, and make `<*>` agree with `ap` of the bind. `Validation` accumulates and never gets a monad.
- `Stateful`: `inout` can't be captured in a `@Sendable` closure, so run the sub-computations before the `@Sendable` body, left to right.
- No new operators, and no operator overloads on nested shapes (`Reader<E, Validation<…>>`): the struct is the only public transformer surface.
- Update `CHANGELOG.md` and the matrix in `MonadTransformers.md` with the new stack.
