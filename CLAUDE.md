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

| Operator | Haskell equiv | Meaning |
|---|---|---|
| `<£>` | `fmap` / `<$>` | Functor map |
| `£>` / `<£` | `$>` / `<$` | Replace with constant |
| `<*>` | `<*>` | Applicative apply |
| `*>` / `<*` | `*>` / `<*` | Sequence, discard one side |
| `>>-` | `>>=` | Monadic bind |
| `>=>` | `>=>` | Kleisli composition |
| `>>>` | `>>>` | Function composition |
| `\|>` | `\|>` | Pipe (forward application) |
| `<>` | `<>` | Semigroup/Monoid append |
| `<\|>` | `<\|>` | Alternative / alt |

## Testing Conventions

Tests use Swift Testing (`@Suite`, `@Test`, `#expect`). Tests verify **functor/applicative/monad laws** and all transformer combinations. When naming `@Test` functions, avoid names that collide with global FP functions (`mconcat`, `sconcat`, etc.) — Swift will prefer `self.method` and cause ambiguity errors.
