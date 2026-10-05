# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.


## Build & Test Commands

This is a Swift Package Manager project — no Xcode project file. Use `swift build` / `swift test` directly. However, always pipe the result to xcsift for clean output.

```bash
# Build all targets
swift build 2>&1 | xcsift

# Run all tests
swift test 2>&1 | xcsift

# Run a single test target
swift test --target CoreFPTests 2>&1 | xcsift

# Run a specific test by name (Swift Testing uses / as separator)
swift test --filter "EitherFunctorTests/flatMap" 2>&1 | xcsift
```

Test targets: `CoreFPTests`, `CoreFPOperatorsTests`, `DataStructureTests`, `DataStructureOperatorsTests`.

## Architecture

### Two-Layer Module System

Every operation is implemented twice: once as a **named function** in a core module, and once as an **operator** in a companion operator module.

| Core module | Operator module |
|---|---|
| `CoreFP` | `CoreFPOperators` |
| `DataStructure` | `DataStructureOperators` |

The `FP` umbrella product re-exports all four. **Operators must always delegate to a named function in the core module — never implement logic inside an operator definition** (exception: inverted-direction operators like `<£` vs `£>`).

### Monad Transformers

Every transformer stack is its own concrete struct named `OuterTInner`, wrapping the whole nested value: `ReaderTEither<Env, L, A>` wraps `Reader<Env, Either<L, A>>`, `PublisherTOptional<Failure, A>` wraps `AnyPublisher<A?, Failure>`, `StatefulTWriter<S, W, A>` wraps `Stateful<S, Writer<W, A>>`. A plain `Reader<Env, [A]>` is just a `Reader` (its operators are the Reader ones); the stack behaviour only exists once you wrap it.

- **Protocols** (`Sources/CoreFP/Transformer/TransformerStack.swift`): `TransformerStack<O, I>` (`O` is the whole nested value, `I` its inner layer) and `MonadT<O, I>` for stacks with a lawful monad. Applicative-only stacks (no lawful monad, e.g. `ReaderTValidation`, `StatefulTArray`, `PublisherTArray`) conform to `TransformerStack` only. `TransformerStack` mirrors `RawRepresentable` (`rawValue`, `init(rawValue:)`) but doesn't refine it, because Swift 6.3 breaks type inference for generic `RawRepresentable` structs whose `RawValue` is an `Optional`. Neither protocol refines `Sendable`; each struct has its own conditional conformance.
- **Members** of every struct: `rawValue`, `init(rawValue:)`, `init(_:)`, `map` + static `fmap`, static `pure`, static `apply`, static `liftA2`, `seqRight`, `seqLeft`, and on `MonadT` stacks `flatMap`, static `bind`, static `kleisli` / `kleisliBack`. No `T`-suffixed names. Operators in the companion module: `<£>`, `<&>`, `£>`, `<£`, `<*>`, `*>`, `<*`, plus `>>-`, `-<<`, `>=>`, `<=<` on `MonadT` stacks.
- **Lifting in**: a property on the outer type named after it (`reader.readerT`, `stateful.statefulT`, `publisher.publisherT`, `asyncStream.asyncStreamT`, `array.arrayT`, `optional.optionalT`, `either.eitherT`, …), constrained through the inner-shape protocols (`ArrayLike`, `OptionalLike`, `ResultLike`, `AsyncStreamLike`, `EitherLike`, `NonEmptyLike`, `WriterLike`, `ValidationLike`, `ReaderLike`, `StatefulLike`) since Swift has no parameterized extensions. `Stack(nested)` works too. **Leaving**: `.rawValue`.
- **Escape hatch** `(O) -> O2`, Haskell-named, to reach the whole API of the underlying types: by the outer layer for Reader / Stateful / streams (`mapReaderT`, `mapStateT`, `mapPublisherT`, `mapAsyncStreamT`), else by the inner layer for Optional / Either / Result / Writer (`mapMaybeT`, `mapExceptT`, `mapWriterT`), else (Compose-like stacks) by the outer layer (`mapArrayT`, `mapOptionalT`, `mapEitherT`, `mapResultT`, `mapNonEmptyT`, `mapValidationT`). The rule lives in CONTRIBUTING.
- **Generated code**: all 74 stacks come from `swift Scripts/GenerateTransformers.swift` into `Sources/*/Transformer/Generated/` (structs in `CoreFP` / `DataStructure`, operators in the operator modules). **Never hand-edit generated files**; change the templates or add a `Stack(.outer, .inner, kind)` line to the generator's `inventory` table and rerun it, then commit script and output together.
- The nested-type functions (`mapT`, `flatMapT`, free `apply<Outer><Inner>`, `liftA2<Outer><Inner>`, …) still exist but are `internal`: they are the implementation the structs delegate to, not public API. Don't document or re-export them, and don't add operator overloads on nested shapes (`Reader<E, [A]>`); the struct is the only public transformer surface.

### Key Types

- **`Either<L, R>`** — unconstrained sum type (unlike `Result`, both sides are unrestricted); conforms to `SumType2`
- **`Validation<E, A>`** — accumulating applicative (errors collect rather than short-circuit); minimal `Monad` instance
- **`Reader<Env, Out>`** — dependency injection monad; wraps `(Env) -> Out`
- **`Stateful<S, A>`** — state threading monad; named `Stateful` (not `State`) to avoid SwiftUI conflicts; wraps `(S) -> (S, A)`
- **`Writer<Log, A>`** — append-as-you-go monad; wraps `(A, Log)`

### SumType Protocol

`Either`, `Result`, and related types share a `SumType2<A, B>` protocol that provides `.a`, `.b`, `.isA`, `.isB`, and `.match()` for free. New sum types should conform to this protocol rather than duplicating boilerplate.

### Operator Vocabulary

Every operator that has a directional sense has a **flipped counterpart**. When adding a new overload for the forward operator, **always add the corresponding overload for the flipped operator in the same commit**. The flipped version delegates to the forward one with arguments swapped — never duplicates logic.

| Forward | Flipped | Haskell equiv | Meaning |
|---|---|---|---|
| `<£>` | `<&>` | `<$>` / `<&>` | Functor map — fn left / container left |
| `£>` | `<£` | `$>` / `<$` | Replace with constant — container left / value left |
| `<*>` | — | `<*>` | Applicative apply (symmetric, no flip) |
| `*>` | `<*` | `*>` / `<*` | Sequence — keep right / keep left |
| `>>-` | `-<<` | `>>=` / `=<<` | Monadic bind — container left / fn left |
| `->>` | `<<-` | — | Comonad extend — container left / fn left |
| `>=>` | `<=<` | `>=>` / `<=<` | Kleisli composition — left-to-right / right-to-left |
| `>>>` | `<<<` | `>>>` / `<<<` | Function/optics composition — left-to-right / right-to-left |
| `<\|` | `\|>` | `$` | Function application — fn left (`f <\| x`) / value left (`x \|> f`) |
| `<\|>` | — | `<\|>` | Alternative / choice (symmetric, no flip) |
| `<>` | — | `<>` | Semigroup/Monoid append (symmetric, no flip) |
| `^` (prefix) | — | — | Lift — `WritableKeyPath` → `Lens`; `KeyPath` → partial `Lens` builder |
| `≅` | — | — | Isomorphism / approximate equality check |
| `±` / `+/-` | — | — | Numeric range construction — `value ± delta` |

**Notes:**
- `<|` is function application (`fn <| value`, Haskell's `$`); `|>` is its flip. There is no plain `£` operator: `£` only appears inside other operators such as `<£>`, `£>`, `<£`.
- There is no `++`: concatenate arrays and strings with `<>`.
- Transformer stacks reuse the base operators (`<£>`, `£>`, `<*>`, `*>`, `>>-`, `>=>`, …) on their own struct type (see Monad Transformers above); there are no transformer-specific operators. On a bare nested value (`Reader<E, [A]>`) the operators are the outer type's, so `£>` replaces the whole output; wrap it (`.readerT`) to act on the inner value.
- Optics (`Lens`, `Prism`, `AffineTraversal`) compose via `>>>` / `<<<` alongside regular function composition.

## Sendable Contract — MANDATORY

The library is **Sendable-first**. Composition (functor / applicative / monad / transformer surfaces, function helpers, optics, free functions like `compose` / `curry` / `flip` / `withArg`) takes and returns `@Sendable` closures everywhere. When adding new surfaces, follow these rules:

- **All algebraic value types** (`Either`, `Validation`, `Reader`, `Stateful`, `Writer`, `Loading`, `NonEmpty`, `Newtype`, `Endo`, `EndoMut`, `Iso`, `Lens`, `Prism`, `AffineTraversal`, …) carry a conditional `extension X: Sendable where T: Sendable [, ...]` conformance. Stored closures are `@Sendable`.
- **Algebra protocols** (`Semigroup`, `Monoid`, `SumType2`, `FunctionWrapper`, `CaseMatchable`, `HasCases`, `HasMax`, `HasMin`, `SIMDMonoidScalar`) refine `Sendable`. Conformers must be Sendable.
- **`apply` / `<*>` and friends** require the *inner* closure type to be `@Sendable`, e.g. `Either<L, @Sendable (A) -> B>`, `Reader<E, @Sendable (A) -> B>`, `Stateful<S, @Sendable (A) -> B>`, `[@Sendable (A) -> B]`, `Result<@Sendable (A) -> B, E>`, etc. The Either pattern is the template for base types; transformer stacks get theirs from the generator (`apply` takes `Stack<…, @Sendable (Input) -> A>`).
- **Composition free functions** (`compose`, `compose3`, `compose4`, `withArg`, `tuple`, `untuple`, `uncurry`, `flipU`, `call(then:)`, `lazy(_function:)`, `unlazy(_:)`) return `@Sendable` functions unconditionally — they only capture their input closures (which are already `@Sendable`).
- **Helpers that capture a generic-typed value** (`curry`, `curryT`, `partialApply`, `flip` (2-arg + curried), `partialApplyFlip`, `lazy(value:)`, `pure`) require the captured generic to be `Sendable` to return `@Sendable`. The library exposes both: a non-Sendable original and a `<A: Sendable>` overload returning `@Sendable`. Compiler picks based on context.
- **KeyPath → function**: Swift's implicit `KeyPath → (Root) -> Value` conversion is **not** `@Sendable`. Use `get(_:)` (CoreFP) or `prefix ^` (CoreFPOperators) to lift explicitly.
- **`inout` cannot be captured in `@Sendable` closures.** When `Stateful<S, A>` combinators need to run multiple sub-`Stateful`s, evaluate them *before* the `@Sendable` block, in left-to-right applicative order:
  ```swift
  Stateful<S, B> { s in
      let f = sf.run(&s)  // first
      let a = sa.run(&s)  // second
      return ...          // pure combine inside @Sendable body
  }
  ```
- **Operator overload ambiguity:** there are no operator overloads on nested shapes any more (stacks are structs), so the old "specialised `Either<L, Stateful<S, A>>` overload vs generic `Either<A, B>` overload" ranking problem is gone. If two overloads of one operator ever compete on the same base type again, put Sendable constraints in `where` clauses (not inline on type parameters) on both, otherwise Swift can't pick the more-specific one.
- **`Result.Monoids.Pessimistic` semigroup** — Failure is constrained to `Semigroup` but Success is **not**. Swift forbids `Success: Sendable` in a `Semigroup` conditional conformance (marker-protocol rule), so Pessimistic ships a separate `extension … : Sendable where Success: Sendable, Failure: Sendable {}` alongside its `: Semigroup` conformance. Same pattern for the other three `Result.Monoids.*` variants.
- **What does NOT need `: Sendable`:** uninhabited phantom-namespace enums (`Of<T>`, `Of2<T,U>`, `Of3<T,U,V>`, `Result.Monoids`, `Bool.Monoids`). They have no instances; conformance would be vacuous. Same for the `Mutable` marker protocol — its conformers are arbitrary value types and most are already Sendable; forcing the protocol bound would over-restrict.

## Swift Limitations — What Cannot Be Implemented

Swift lacks Higher-Kinded Types (HKT). You cannot write a type parameter that is itself generic — `protocol Functor { associatedtype F<A> }` is not valid Swift. This rules out entire categories of abstractions that exist in Haskell or Scala Cats:

- **`Functor`, `Applicative`, `Monad` as protocols** — impossible to express generically. Each type (`Optional`, `Array`, `Reader`, …) gets its own concrete `map`/`flatMap` methods rather than conforming to a shared protocol.
- **`Bifunctor` protocol** — cannot abstract over `F<A, B>` generically. `bimap` exists as an ad-hoc method on each type.
- **`Contravariant` protocol** — same reason; `contramap` is only on `Reader`.
- **`Profunctor` protocol** — `dimap` is only on `Reader`; cannot be generalised across optics or other profunctors.
- **`Category` / `Arrow` protocols** — require abstracting over the morphism type `F<A, B>`.
- **`Traversable` as a protocol** — `traverse` can't be expressed generically because the applicative effect `F` would need to be an HKT parameter.
- **`Identity<A>` as a generic monad transformer base** — the type itself is trivial, but using it to parameterise transformer stacks generically requires HKT.
- **`Const<C, A>` as a generic functor** — same constraint; can exist as a concrete type but can't participate in generic functor machinery.
- **`Free` monad, `Coyoneda`, recursion schemes** — all require HKT in their general form.

When suggesting new additions to this library, only propose things that are expressible as **concrete types with concrete method implementations**. Do not propose protocol abstractions that require HKT — they will not compile in Swift.

## Testing Conventions

Tests use Swift Testing (`@Suite`, `@Test`, `#expect`). Tests verify **functor/applicative/monad laws** and all transformer combinations. When naming `@Test` functions, avoid names that collide with global FP functions (`mconcat`, `sconcat`, etc.) — Swift will prefer `self.method` and cause ambiguity errors.

### Core tests vs Operator tests — MANDATORY split

Every operation requires **two independent sets of tests**:

| Test target | What it tests | Allowed syntax |
|---|---|---|
| `CoreFPTests` | Named functions in `CoreFP` | Named functions only — **no custom operator symbols** |
| `DataStructureTests` | Named functions in `DataStructure` | Named functions only — **no custom operator symbols** |
| `CoreFPOperatorsTests` | Operator syntax in `CoreFPOperators` | Must use the operator symbol (e.g. `<£>`, `>>-`, `>>>`) |
| `DataStructureOperatorsTests` | Operator syntax in `DataStructureOperators` | Must use the operator symbol |

**Rules:**
- `CoreFPTests` and `DataStructureTests` must **never** contain custom operator symbols. If you catch yourself writing `value <£> f` or `a >>> b` in these targets, stop — use the named function (`map(value, f)`, `compose(a, b)`) instead.
- `CoreFPOperatorsTests` and `DataStructureOperatorsTests` must test the operator symbol directly — not just the backing named function.
- Both test sets must exist for every operator. Having only one of the two is a bug.

**Why:** Named functions are the semantic layer and must be testable without importing any operator module. The operator tests verify only that the syntactic sugar correctly delegates — they are thin by design.
