# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

This is a Swift Package Manager project — no Xcode project file. Use `swift build` / `swift test` directly.

```bash
# Build all targets
swift build

# Run all tests
swift test

# Run a single test target
swift test --target CoreFPTests

# Run a specific test by name (Swift Testing uses / as separator)
swift test --filter "DeferredTaskTests/flatMap"
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
