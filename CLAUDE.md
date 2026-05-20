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
swift test --filter "DeferredTaskTests/flatMap" 2>&1 | xcsift
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

### Monad Transformer Naming

Transformers are named `OuterTInner`, e.g. `OptionalTArray` means `Optional<[A]>`, `DeferredTaskTEither` means `DeferredTask<Either<E, A>>`. Each transformer exposes three operations as free functions: `mapT`, `liftA2*`, `flatMapT`.

### Key Types

- **`Either<L, R>`** — unconstrained sum type (unlike `Result`, both sides are unrestricted); conforms to `SumType2`
- **`Validation<E, A>`** — accumulating applicative (errors collect rather than short-circuit); minimal `Monad` instance
- **`Reader<Env, Out>`** — dependency injection monad; wraps `(Env) -> Out`
- **`Stateful<S, A>`** — state threading monad; named `Stateful` (not `State`) to avoid SwiftUI conflicts; wraps `(S) -> (S, A)`
- **`Writer<Log, A>`** — append-as-you-go monad; wraps `(A, Log)`
- **`DeferredTask<A>`** — lazy async computation (IO monad); nothing executes until `.run()` is called
- **`DeferredStream<A>`** — lazy async stream; streaming counterpart to `DeferredTask`

### SumType Protocol

`Either`, `Result`, and related types share a `SumType2<A, B>` protocol that provides `.a`, `.b`, `.isA`, `.isB`, and `.match()` for free. New sum types should conform to this protocol rather than duplicating boilerplate.

### Operator Vocabulary

Every operator that has a directional sense has a **flipped counterpart**. When adding a new overload for the forward operator, **always add the corresponding overload for the flipped operator in the same commit**. The flipped version delegates to the forward one with arguments swapped — never duplicates logic.

| Forward | Flipped | Haskell equiv | Meaning |
|---|---|---|---|
| `<£>` | `<&>` | `<$>` / `<&>` | Functor map — fn left / container left |
| `<£^>` | `<&^>` | — | Transformer (nested) functor map — fn left / container left |
| `£>` | `<£` | `$>` / `<$` | Replace with constant — container left / value left |
| `<*>` | — | `<*>` | Applicative apply (symmetric, no flip) |
| `*>` | `<*` | `*>` / `<*` | Sequence — keep right / keep left |
| `>>-` | `-<<` | `>>=` / `=<<` | Monadic bind — container left / fn left |
| `->>` | `<<-` | — | Comonad extend — container left / fn left |
| `>=>` | `<=<` | `>=>` / `<=<` | Kleisli composition — left-to-right / right-to-left |
| `>>>` | `<<<` | `>>>` / `<<<` | Function/optics composition — left-to-right / right-to-left |
| `£` / `<\|` | `\|>` | `$` | Function application — fn left (`f £ x`) / value left (`x \|> f`) |
| `<\|>` | — | `<\|>` | Alternative / choice (symmetric, no flip) |
| `<>` | — | `<>` | Semigroup/Monoid append (symmetric, no flip) |
| `++` | — | `++` | List/String concat (symmetric, no flip) |
| `^` (infix) | — | `^` | Numeric power — `base ^ exp` |
| `^` (prefix) | — | — | Lift — `WritableKeyPath` → `Lens`; `KeyPath` → partial `Lens` builder |
| `≅` | — | — | Isomorphism / approximate equality check |
| `±` / `+/-` | — | — | Numeric range construction — `value ± delta` |

**Notes:**
- `£` and `<|` are two symbols for the same operator (both `fn £ value` / `fn <| value`); `|>` is its flip.
- `<£^>` and `<&^>` have **no base-type overloads** by design — transformer-only, so Swift always resolves unambiguously.
- Optics (`Lens`, `Prism`, `AffineTraversal`) compose via `>>>` / `<<<` alongside regular function composition.

## Sendable Contract — MANDATORY

The library is **Sendable-first**. Composition (functor / applicative / monad / transformer surfaces, function helpers, optics, free functions like `compose` / `curry` / `flip` / `withArg`) takes and returns `@Sendable` closures everywhere. When adding new surfaces, follow these rules:

- **All algebraic value types** (`Either`, `Validation`, `Reader`, `Stateful`, `Writer`, `Loading`, `NonEmpty`, `Newtype`, `Endo`, `EndoMut`, `Iso`, `Lens`, `Prism`, `AffineTraversal`, `DeferredTask`, `DeferredStream`, `ZIO`, `ZIOKleisli`, …) carry a conditional `extension X: Sendable where T: Sendable [, ...]` conformance. Stored closures are `@Sendable`.
- **Algebra protocols** (`Semigroup`, `Monoid`, `SumType2`, `FunctionWrapper`, `CaseMatchable`, `HasCases`, `HasMax`, `HasMin`, `SIMDMonoidScalar`) refine `Sendable`. Conformers must be Sendable.
- **`apply` / `<*>` and friends** require the *inner* closure type to be `@Sendable`, e.g. `Either<L, @Sendable (A) -> B>`, `Reader<E, @Sendable (A) -> B>`, `Stateful<S, @Sendable (A) -> B>`, `[@Sendable (A) -> B]`, `Result<@Sendable (A) -> B, E>`, etc. The Either pattern is the template — copy it for new transformer combinations.
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
- **Operator overload ambiguity:** When the same operator (`*>`, `<*`, etc.) has both a generic `Either<A, B>` overload and a specialised `Either<L, Stateful<S, A>>` transformer overload, Sendable constraints must be placed in `where` clauses (not inline on type parameters) on the generic version, with matching `where L: Sendable, S: Sendable, …` clauses on the transformer version. Otherwise Swift can't pick the more-specific overload.
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
