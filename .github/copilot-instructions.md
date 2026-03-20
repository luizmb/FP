# Copilot Instructions for FP Library

## Overview

**FP** is a Swift functional programming library (~4.8K lines) providing operators, monads, and transformers inspired by Haskell. It exports 8 separate libraries and 378 comprehensive tests covering functor/applicative/monad laws.

**Philosophy**: Operators over methods, tacit (point-free) style over explicit lambdas, composition over procedural code.

---

## Build, Test & Lint

### Running Tests

```bash
# Run all tests (378 tests)
swift test

# Run tests for a single module
swift test --filter FPTests
swift test --filter EitherTests
swift test --filter ReaderTests
swift test --filter OperatorsTests
swift test --filter EitherOperatorsTests
swift test --filter ReaderOperatorsTests
swift test --filter ReaderEitherTests
swift test --filter ReaderEitherOperatorsTests

# Run a specific test by name
swift test --filter FPTests.OptionalTraversableTests/testSequenceWithOptionals
```

### Building

```bash
# Build library (all targets)
swift build

# Build a specific target
swift build --product Either
swift build --product Reader
```

### Linting & Formatting

No automated linter is configured. Follow Swift style conventions and review the module structure below for naming patterns.

---

## High-Level Architecture

### Module Dependency Graph

The library is organized as **8 independent products** with layered dependencies:

```
Core Modules:
├── FP
│   ├── Optional, Result, Array extensions (Functor/Applicative/Monad)
│   ├── Traversable protocol (traverse/sequence)
│   └── AsyncSequence, Publisher bridges (#if canImport)
├── Either
│   ├── Sum type (Either<Left, Right>) with type class support
│   └── Platform bridges (Completion+Either, AsyncThrowingStream+Either)
├── Reader
│   ├── Reader<Environment, Output> monad for dependency injection
│   └── Transformer support (ReaderT+Publisher, ReaderT+AsyncSequence)
└── Operators
    └── Operators for all core types (Optional, Result, Array, Either, Reader, Publisher, AsyncSequence)

Transformer Modules (depend on core modules):
├── EitherOperators
│   └── Dedicated operators for Either
├── ReaderOperators
│   └── ReaderT operators for Optional, Result, Array, Reader, Publisher, AsyncSequence
├── ReaderEither
│   └── ReaderT + Either combined implementation
└── ReaderEitherOperators
    └── Operators for ReaderEither transformers
```

**Test Structure:** Each module has a corresponding `*Tests` target. Tests verify functor/applicative/monad laws, all operators, and transformer combinations.

### Design Patterns

1. **Operators map Haskell conventions** with Swift-specific adjustments:
   - Haskell `>>=` (bind) → Swift `>>-` (avoids bitwise conflict)
   - Haskell `=<<` (flipped bind) → Swift `-<<`
   - Haskell `<$>` (fmap) → Swift `<£>` (currency symbol for better readability)
   - Other operators match Haskell: `<*>`, `*>`, `<*`, `>=>`, `>>>`, `<|>`, etc.

2. **Operator Precedence & Associativity** strictly follow Haskell equivalents (see `PRECEDENCE_CORRECTIONS.md`):
   - Right-associative: `>>>` (9), `>=>` (1), `-<<` (1), `<|>` (3)
   - Left-associative: `>>-` (1), `<£>`, `<*>` (4), `<&>` (1)
   - This ensures chain operations work intuitively: `f >=> g >=> h` = `f >=> (g >=> h)`

3. **Type Class Hierarchy:**
   - **Functor** (`<£>`, `<&>`, `£>`, `<£`): Map plain functions into containers
   - **Applicative** (`<*>`, `*>`, `<*`): Apply wrapped functions to wrapped values
   - **Monad** (`>>-`, `-<<`, `>=>`, `traverse`, `sequence`): Chain dependent computations

4. **Traversable Pattern:**
   - `traverse` inverts nested structures with computation: `[a?] -> [a]?`
   - `sequence` applies identity traversal: inverts nesting without transformation

---

## Key Conventions

### File Organization

- **Type implementations:** `Module/Type+TypeClass.swift` (e.g., `FP/Optional+Functor.swift`, `Either/Either+Monad.swift`)
- **Operator declarations:** `Module/Type+Operators.swift` or dedicated operator files
- **Transformer implementations:** `Reader/ReaderT*+TypeClass.swift` (e.g., `Reader/ReaderTOptional+Monad.swift`)
- **Platform bridges:** `Module/Type+Platform.swift` (e.g., `Either/Completion+Either.swift` for Combine)

### Naming Patterns

- **Core types use standard names:** `Optional`, `Result`, `Either`, `Reader`
- **Type class functions follow Haskell names** but map to Swift operators:
  - `fmap` → operator `<£>`; function `Optional.map(_:)`
  - `bind` / `flatMap` → operator `>>-`; function `Optional.flatMap(_:)`
  - `apply` → operator `<*>`; function `Optional.apply(_:)`
- **Transformers** prefix with the monad: `ReaderTOptional`, `ReaderTResult`, `ReaderTArray`
- **Bridge types** combine both names: `Completion+Either`, `AsyncThrowingStream+Either`

### Code Style

- Use **#if canImport(Combine)** and **#if canImport(AsyncSequence)** for platform-specific code
- Type extensions are preferred over standalone functions for discoverability
- Generic parameters use single uppercase letters when standard (T, E) or domain-specific names (Environment, Output) for clarity
- Comments explain *why*, not *what*; type signatures are self-documenting

### Operator Architecture Rule ⚠️

This is a **hard rule** critical to the library design:

1. **Every custom operator must delegate to a named public function in the matching core module** (not in Operators modules)
   - Named functions live in: `FP`, `Either`, `Reader`, etc.
   - Operators live in: `Operators`, `EitherOperators`, `ReaderOperators`, etc.
2. **Operator bodies are ONLY a single call** to their backing named function — never chained operators
3. **Named functions never call custom operators** in their bodies — they call other named functions or Swift built-ins
4. **Exception:** Bidirectional operators like `£>` and `<£` — the reverse-direction operator (e.g., `<£`) may call the forward operator declared immediately above it
5. **For transformers:** Each inner type combination needs its own named function (e.g., `seqRightReaderEither`, `seqRightReaderPublisher`)

**Example — CORRECT:**
```swift
// In core module (Reader)
public func fmapReader<E, A, B>(
    _ transform: @escaping (A) -> B,
    _ reader: Reader<E, A>
) -> Reader<E, B> {
    // implementation
}

// In operator module (ReaderOperators)
infix operator <£> : FunctorOps
func <£> <E, A, B>(
    _ transform: @escaping (A) -> B,
    _ reader: Reader<E, A>
) -> Reader<E, B> {
    fmapReader(transform, reader)
}
```

**Why:** Keeps named functions testable and composable without operator syntax; maintains clean separation between the DSL layer (Operators) and semantic layer (core modules).

### Code Style (continued)

- **No `return` keyword** — use implicit returns (single-expression functions, switch expressions, closures)
- **Never use force operations** (`as!`, `!`, `fatalError`, `preconditionFailure`) except in `FP/Functions.swift` where `fail` intentionally crashes
- **Avoid column-aligned formatting** in switch cases — just break to the next line normally
- Use safe alternatives: optional chaining, `guard`, `if let`, `Result`

### Platform Support

- **macOS 10.15+, iOS 13+, tvOS 13+, watchOS 6+** (core types)
- **Combine features** require macOS 13.0+ / iOS 16.0+
- **Linux** supported for non-Combine modules
- All platform-specific code guarded with compiler directives

### Testing Conventions

- **Law-based testing:** Every type class implementation verified against functor, applicative, and monad laws
- **Test organization:** `Tests/*Tests/` mirrors source structure (`FPTests` mirrors `Sources/FP`, etc.)
- **Parametric tests:** Use `@testable import` to access internal types and verify preconditions
- **Edge cases:** Tests cover empty containers, nil values, failures, and transformer stacking

### Platform-Specific Workarounds

**Existential Publisher Limitations** (swift's `any Publisher<A, E>` has compile-time restrictions):
1. Static methods don't resolve on existentials → use `AnyPublisher<A, E>.someStaticMethod()` instead
2. Instance methods fail on existentials → call `.eraseToAnyPublisher()` first
3. For operator chains: always use `.eraseToAnyPublisher().zip(...).map(...).eraseToAnyPublisher()` pattern
4. For `bind`: call on the type matching the *input* publisher's element type, not the output

### Naming for Operator-Backing Functions

Use names from the functional programming community (Haskell/Scala Cats):

| Name | Standard From | Usage |
|------|---|---|
| `fmap` | Haskell Functor | Map plain function through functor |
| `bind` | Haskell `>>=` | Chain dependent computations (Scala: `flatMap`) |
| `apply` | Haskell `ap` / Scala Cats | Apply wrapped function to wrapped value |
| `liftA2` | Haskell Applicative | Lift binary function to applicative |
| `kleisli` | Haskell / Scala Cats | Compose monadic functions (`>=>`) |
| `productR` / `productL` | Scala Cats `*>` / `<*` | Sequence two applicatives, keep one side |
| `replaceWith` / `replaceOutput` | Alternative to `$>` / `£>` | Replace wrapped value with constant |
| `seqRight` / `seqLeft` | Current names (consider `productR`/`productL`) | Descriptive but not standard |

**Note:** `productR`/`productL` are more aligned with Scala Cats standards than `seqRight`/`seqLeft`, but both exist in the current codebase.

---

## Important References

- **IMPLEMENTATION_SUMMARY.md**: Complete feature inventory, operator precedence table, and module architecture
- **PRECEDENCE_CORRECTIONS.md**: Detailed justification for operator precedence & associativity choices
- **docs/types/*.md**: Individual type documentation with operator examples and law verification
- **docs/claude-skills/**: Claude-specific guides for users and contributors

---

## Claude Skills & Guides

The project includes AI-specific documentation under `docs/claude-skills/`:

### For Users (Using the Library)
- **getting-started.md** — Learn operators, tacit style, and point-free programming
- **convert-to-functional.md** — Refactor imperative code to functional style with operators
- **explain-operators.md** — Understand operator precedence and composition chains
- **reader-monad-guide.md** — Use Reader monad for dependency injection patterns
- **make-type-composable.md** — Make custom types work with `<£>`, `>>-`, and other operators

### For Contributors (Extending the Library)
- **add-monad-support.md** — Implement Functor/Applicative/Monad for new types
- **create-readert-transformer.md** — Create ReaderT transformers following library patterns

### Key Principle: Operators + Tacit Style

Prefer operators over methods, composition over procedures:

```swift
// ❌ Avoid
array.map { $0 * 2 }.flatMap { [$0, $0 + 1] }

// ✅ Operators with lambdas
{ $0 * 2 } <£> array >>- { [$0, $0 + 1] }

// ✅✅ Tacit (point-free) when readable
let double = 2 |> curry(*)
let expand = { [$0, $0 + 1] }
double <£> array >>- expand
```

Tacit utilities in `FP.Functions`: `curry`, `flip`, `identity`, `const`, `compose`, `>>>`, `<<<`, `|>`

---

## Important References

## Common Tasks

### Adding a New Operator

1. **Create the named function** in the core module (e.g., `Reader/Reader+Monad.swift`):
   ```swift
   public func fmapReader<E, A, B>(
       _ f: @escaping (A) -> B,
       _ reader: Reader<E, A>
   ) -> Reader<E, B> {
       // implementation
   }
   ```
2. **Create the operator** in the operator module (e.g., `ReaderOperators/Reader+Operators.swift`):
   ```swift
   infix operator <£> : FunctorOps
   func <£> <E, A, B>(
       _ f: @escaping (A) -> B,
       _ reader: Reader<E, A>
   ) -> Reader<E, B> {
       fmapReader(f, reader)
   }
   ```
3. Check precedence from `PRECEDENCE_CORRECTIONS.md` — don't create new precedence groups
4. Implement for all applicable types (Optional, Result, Array, Either, Reader, Publisher, AsyncSequence)
5. Add unit tests verifying operator chaining and edge cases (test the named function directly)
6. Update `IMPLEMENTATION_SUMMARY.md` with the new operator

### Extending a Type with a Type Class

1. Create `Module/Type+TypeClass.swift` in the core module (not Operators)
2. Implement required named functions (e.g., `fmap`, `bind`, `apply`)
3. Add operator implementations in `Module/Type+Operators.swift`
4. Add corresponding test file `Tests/ModuleTests/TypeTests.swift`
5. Test named functions directly (don't test operators in unit tests; verify operator chaining separately)
6. Verify all type class laws pass:
   - **Functor**: identity, composition
   - **Applicative**: identity, composition, homomorphism, interchange
   - **Monad**: left identity, right identity, associativity

### Adding Platform Support

1. Wrap platform-specific code with `#if canImport(FrameworkName)`
2. Implement parallel named functions (with and without the framework) in the same core module file
3. Create corresponding operator files for the platform-specific operators module
4. Update test targets to include platform-specific tests where needed
5. Document minimum version requirements in this file and module comments

### Refactoring: Remove Explicit `return` Statements

The codebase is transitioning to implicit returns throughout. When editing code:
- Single-expression functions: use implicit return
- Switch expressions: use implicit return
- Closures: use implicit return

**Example:**
```swift
// Before
func fmap<B>(_ transform: @escaping (A) -> B) -> Optional<B> {
    return self.map(transform)
}

// After
func fmap<B>(_ transform: @escaping (A) -> B) -> Optional<B> {
    self.map(transform)
}
```
