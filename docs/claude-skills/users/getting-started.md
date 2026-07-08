# Getting Started with FP Library

Help developers get started using the FP library's operators and tacit programming style in their Swift projects.

## Skill Prompt

You are helping a developer learn and use the FP library for functional programming in Swift. The library provides operators for common functional patterns and utilities for tacit (point-free) programming.

### Key Principles

1. **Operators First**: Use `<£>` not `.map()`, use `>>-` not `.flatMap()`
2. **Tacit When Clear**: Use `curry(*)(2)` not `{ $0 * 2 }`
3. **Compose Everything**: Build complex functions from simple pieces with `>>>`, `<<<`, `|>`

When using this library:
- ✅ **Import operator modules**: `import CoreFPOperators`, `import DataStructureOperators`, or the umbrella `import FP` for everything
- ✅ **Use operators**: `<£>`, `<*>`, `>>-`, `>=>` for composition
- ✅ **Prefer tacit style**: Use library utilities like `curry`, `flip`, `compose` instead of explicit lambdas
- ❌ **Avoid method versions when an operator is available**: prefer `<£>` over `.map()` in call sites, though `.map`/`.flatMap` are the real instance methods the operators delegate to
- ❌ **Avoid explicit lambdas**: Don't use `{ $0 + 1 }` when `curry(+)(1)` reads more clearly

Swift does **not** support Haskell-style operator sections like `(+1)` or `(*2)` — always use `curry(_:)` for partial application of an operator, or a lambda for anything more complex.

### Quick Start Guide

#### Step 1: Import Modules

The library ships as five products:

```swift
import FP  // umbrella: everything below, re-exported

// Or import exactly what you need:
import CoreFP                  // Optics, Semigroup/Monoid, SumType2, function utilities
import CoreFPOperators         // Operator syntax for CoreFP
import DataStructure           // Either, Validation, Reader, Writer, Stateful, NonEmpty,
                                // Loading, IdentifiedArray, These, Zipper
import DataStructureOperators   // Operator syntax for DataStructure
```

There is no per-type module (no `import Either`, no `import Reader`) — everything lives in one of the four modules above, grouped by whether it's a core/stdlib-adjacent type or a `DataStructure` type, and whether it's the named-function surface or the operator surface.

#### Step 2: Tacit Programming Utilities

Before using operators, learn the utilities for point-free style (from `CoreFP`):

```swift
import CoreFP
import CoreFPOperators  // for |>, >>>, <<<

// curry: Convert multi-parameter function to curried form
let add: (Int, Int) -> Int = (+)
let addCurried: (Int) -> (Int) -> Int = curry(add)
let add5 = addCurried(5)  // (Int) -> Int
add5(3)  // 8

// Preferred: Use |> to apply the first argument (cleaner than nested parens)
let double = 2 |> curry(*)      // (Int) -> Int
let increment = 1 |> curry(+)   // (Int) -> Int

// compose: Chain functions
let addOneThenDouble = increment >>> double  // (Int) -> Int
addOneThenDouble(5)  // 12

// |> pipe operator: Apply a value to a function (or chain of functions)
let result = 5 |> increment |> double  // 12

// flip: Reverse parameter order
let subtractFrom10 = 10 |> curry(-)          // subtracts FROM 10
subtractFrom10(3)  // 7 (10 - 3)

let subtract10 = flip(curry(-))(10)          // subtracts 10 from its argument
subtract10(15)  // 5 (15 - 10)
```

**Use tacit style when it's clearer**:
```swift
// ❌ Explicit lambda (harder to read for a simple transform)
array.map { $0 * 2 }

// ✅ Tacit (clearer intent)
let double = 2 |> curry(*)
double <£> array

// ❌ Nested lambdas
array.map { $0 + 1 }.map { $0 * 2 }

// ✅ Composition
let increment = 1 |> curry(+)
let double = 2 |> curry(*)
(increment >>> double) <£> array
```

#### Step 3: Basic Operators

**Functor** (`<£>`) — Transform values in containers:
```swift
import DataStructure
import DataStructureOperators

// Optional - tacit style with |> curry
let double = 2 |> curry(*)
let doubled = double <£> Optional(5)  // Optional(10)

// Array - a lambda is fine for anything beyond a single arithmetic op
let squared = { $0 * $0 } <£> [1, 2, 3]  // [1, 4, 9]

// Result
let uppercased = { $0.uppercased() } <£> Result<String, Error>.success("hello")

// KeyPath — Swift's implicit KeyPath-to-function conversion is NOT @Sendable,
// so lift it explicitly with `get(_:)` (CoreFP) or prefix `^` (CoreFPOperators)
// before passing it where the library expects a @Sendable closure:
let lengths = get(\.count) <£> ["hello", "world"]  // [5, 5]
// or, with the operator: (^\.count) <£> ["hello", "world"]
```

**Applicative** (`<*>`) — Apply wrapped functions:
```swift
// Combine two Optionals — liftA2/pure/apply are static methods on the concrete type
let result = Optional<Int>.liftA2(+)(.some(5), .some(3))  // Optional(8)

// Or using pure + apply:
let wrappedAdd: ((Int) -> Int)? = Optional.pure { $0 + 3 }
let result2 = wrappedAdd <*> .some(5)  // Optional(8)
```

**Monad** (`>>-`) — Chain operations:
```swift
// Optional chaining
let result = Optional(5) >>- { x in
    guard x > 0 else { return nil }
    return .some(x * 2)
}  // Optional(10)

// Result chaining
let validated = Result<String, ValidationError>.success("hello") >>- { text in
    guard !text.isEmpty else {
        return .failure(.empty)
    }
    return .success(text.uppercased())
}  // .success("HELLO")
```

**Kleisli Composition** (`>=>`) — Compose functions:
```swift
let parse: (String) -> Int? = { Int($0) }
let validate: (Int) -> Int? = { $0 > 0 ? .some($0) : nil }
let double: (Int) -> Int? = { .some($0 * 2) }

let pipeline = parse >=> validate >=> double
pipeline("5")   // Optional(10)
pipeline("-1")  // nil
```

#### Step 4: Combining Operators and Tacit Style

The real power comes from combining operators with tacit programming:

```swift
// Example: transform and expand array
let array = [1, 2, 3]

// ❌ Imperative
array.map { $0 * 2 }.flatMap { [$0, $0 + 1] }

// ✅ Better: Operators with lambdas
{ $0 * 2 } <£> array >>- { [$0, $0 + 1] }

// ✅✅ Best: Tacit + operators (define functions with |> curry)
let double = 2 |> curry(*)
let expand: (Int) -> [Int] = { [$0, $0 + 1] }
double <£> array >>- expand
// Result: [2, 3, 4, 5, 6, 7]
```

**Tacit style decision tree**:
- Simple arithmetic? Use tacit: `2 |> curry(*)`, `1 |> curry(+)`, `5 |> curry(-)`
- Function composition? Use tacit: `f >>> g`, `increment >>> double`
- Complex logic? A lambda is fine: `{ guard $0 > 0 else { return nil }; return $0 }`

#### Step 5: Common Patterns

**Pattern 1: Replace nested if-let**

Before:
```swift
if let a = optA {
    if let b = optB {
        if let c = process(a, b) {
            return c.uppercased()
        }
    }
}
return nil
```

With operators:
```swift
optA >>- { a in
    optB >>- { b in
        process(a, b)
    }
} <£> { $0.uppercased() }
```

**Pattern 2: Transform arrays**

Before:
```swift
array.compactMap { $0.value }.map { $0 * 2 }.filter { $0 > 10 }
```

With operators:
```swift
array
    <£> { $0.value }
    >>- { x in x.map { $0 * 2 } }
    .filter { $0 > 10 }
```

**Pattern 3: Error handling**

Before:
```swift
do {
    let data = try fetch()
    let parsed = try parse(data)
    return .success(process(parsed))
} catch {
    return .failure(error)
}
```

With operators (`fetch`/`parse` returning `Result`, not `throws`):
```swift
fetchResult() >>- parseResult <£> process
// Returns Result<ProcessedData, Error>
```

**Pattern 4: Alternative/Fallback**

```swift
// Try multiple options — <|> is defined for Optional/Result/Array
let config = userConfig <|> defaultConfig <|> fallbackConfig
```

### Essential Operators Reference

| Operator | Name | Type | Example |
|----------|------|------|---------|
| `<£>` | fmap | `(A -> B) -> F A -> F B` | `{ $0 * 2 } <£> optional` |
| `£>` | replace right | `F A -> B -> F B` | `optional £> 42` |
| `<£` | replace left | `A -> F B -> F A` | `42 <£ optional` |
| `<&>` | flipped fmap | `F A -> (A -> B) -> F B` | `optional <&> { $0 * 2 }` |
| `<*>` | apply | `F (A -> B) -> F A -> F B` | `fnOpt <*> valueOpt` |
| `*>` | sequence right | `F A -> F B -> F B` | `optA *> optB` |
| `<*` | sequence left | `F A -> F B -> F A` | `optA <* optB` |
| `>>-` | bind | `M A -> (A -> M B) -> M B` | `opt >>- transform` |
| `-<<` | flipped bind | `(A -> M B) -> M A -> M B` | `transform -<< opt` |
| `>=>` | Kleisli comp | `(A -> M B) -> (B -> M C) -> (A -> M C)` | `f >=> g` |
| `<=<` | flipped Kleisli | `(B -> M C) -> (A -> M B) -> (A -> M C)` | `g <=< f` |
| `<|>` | alternative | `F A -> F A -> F A` | `opt1 <|> opt2` |
| `>>>` | forward comp | `(A -> B) -> (B -> C) -> (A -> C)` | `f >>> g` |
| `<<<` | backward comp | `(B -> C) -> (A -> B) -> (A -> C)` | `g <<< f` |
| `\|>` | pipe | `A -> (A -> B) -> B` | `5 \|> double` |
| `<>` | semigroup | `A -> A -> A` | `arr1 <> arr2` |

`<&>` is only the flipped Functor map — it has no relation to Kleisli composition. See `<doc:OperatorVocabulary>` for the full, verified table including precedence.

### Prisms and PrismKeyPath — write reusable optics, not hardcoded case-extractors

Any `@Prisms`-annotated enum (and the library's own `Either`, `Loading`, `Validation`, `Optional`, `Result`) exposes `\.caseName` as a composable **`PrismKeyPath`** — not a plain KeyPath, but the same `\.` syntax. The key win: write functions that accept a `PrismKeyPath` as a parameter, instead of hardcoding a specific case inside the function body. That makes the function reusable across *any* case, at *any* nesting depth, including cases the function's author never anticipated.

```swift
// ❌ Hardcoded to one specific case — has to be rewritten for every new case/type
func extractCircleRadius(_ shape: Shape) -> Double? {
    guard case let .circle(r) = shape else { return nil }
    return r
}

// ✅ Reusable — works for any case of any Prismatic type, by taking the path as a parameter
func extract<Root, Value>(_ path: PrismKeyPath<Root, Value>, from root: Root) -> Value? {
    Prism(path).preview(root)
}

extract(\.circle, from: shape)              // Optional(3.14)
extract(\.idle, from: loadingState)          // Void? — works on Loading's own cases too
```

**Dot-composition through nested cases** is the real payoff — `\.a.b.c` composes automatically as long as each intermediate type is itself `Prismatic` (i.e., itself `@Prisms`-annotated, or one of the library's built-ins):

```swift
enum AppState { case loggedOut, loggedIn(Session) }
// @Prisms enum Session { case active(Profile), expired }
// @Prisms enum Profile { case guest, member(name: String) }

extract(\.loggedIn.active.member, from: appState)   // String? — three levels deep, one call
```

This is the same idea as `Lens` composition via `>>>`/`<<<` (see the Optics DocC article), but for enums instead of structs — and, unlike hand-writing `if case let ... = ... , case let ... = ...` chains, it doesn't need to change at all when a new intermediate case is added elsewhere in the hierarchy.

### Learning Path

1. **Start with Functor** (`<£>`) — Learn to transform values
2. **Add Applicative** (`<*>`) — Learn to combine effects
3. **Master Monad** (`>>-`) — Learn to chain operations
4. **Compose with Kleisli** (`>=>`) — Build pipelines
5. **Learn Reader** — Handle dependencies elegantly
6. **Explore transformer stacks** (`OuterTInner`) — Combine effects

### When to Use What

**Use Functor** when:
- Transforming values inside containers
- Simple mapping operations
- No need to change container structure

**Use Applicative** when:
- Combining multiple effects
- Need both values simultaneously
- Independent computations

**Use Monad** when:
- Second computation depends on first result
- Chaining operations
- Short-circuit on failure

**Use Reader** when:
- Passing configuration/dependencies that cross the app's own boundary (API clients, databases, config, feature flags)
- Environment-based computation
- Want to avoid parameter threading
- **Not** when the "environment" is really just an ordinary function parameter — `Reader<Int, X>` for adding a number is a misuse; see `reader-monad-guide` for the full boundary

### Common Gotchas

❌ **Wrong**: Operator on wrong side
```swift
optional <£> { $0 * 2 }  // ❌ Function must be on the left of <£>
```
✅ **Right**: Function on left
```swift
{ $0 * 2 } <£> optional  // ✅
// Or use the flipped form if the value reads better first:
optional <&> { $0 * 2 }  // ✅
```

❌ **Wrong**: Mixing method and operator syntax inconsistently
```swift
optional.flatMap(f) >>- g  // Works, but inconsistent style
```
✅ **Right**: Stick with one style per expression
```swift
optional >>- f >>- g  // ✅
```

### Next Steps

After mastering basic operators:
1. Learn Reader monad (use `reader-monad-guide` skill)
2. Refactor existing code (use `convert-to-functional` skill)
3. Debug compositions (use `explain-operators` skill)
4. Explore advanced patterns (monad transformer stacks)

### Ask the developer:
1. What types are they working with (Optional, Result, Array, etc.)?
2. Are they new to functional programming or coming from Haskell/Scala?
3. What specific problem are they trying to solve?
4. Do they prefer seeing step-by-step transformations or final result?

Provide clear, operator-first examples with explanations.
