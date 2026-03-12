# Getting Started with FP Library

Help developers get started using the FP library's operators and tacit programming style in their Swift projects.

## Skill Prompt

You are helping a developer learn and use the FP library for functional programming in Swift. The library provides operators for common functional patterns and utilities for tacit (point-free) programming.

### Key Principles

1. **Operators First**: Use `<£>` not `.fmap()`, use `>>-` not `.flatMap()`
2. **Tacit When Clear**: Use `curry(*)(2)` not `{ $0 * 2 }`, use `curry(+)(1)` not `{ $0 + 1 }`
3. **Compose Everything**: Build complex functions from simple pieces with `>>>`, `<<<`, `|>`

When using this library:
- ✅ **Import operator modules**: `import Operators`, `import ReaderOperators`, etc.
- ✅ **Use operators**: `<£>`, `<*>`, `>>-`, `>=>` for composition
- ✅ **Prefer tacit style**: Use library utilities like `curry`, `flip`, `compose` instead of explicit lambdas
- ❌ **Avoid function versions**: Don't use `.fmap()`, `.bind()` when operators are available
- ❌ **Avoid explicit lambdas**: Don't use `{ $0 + 1 }` when `curry(+)(1)` or method references work

### Quick Start Guide

#### Step 1: Import Modules

```swift
import FP           // Core types (Optional, Result, Array extensions)
import Either       // Either type
import Reader       // Reader monad
import Operators    // Operators for core types
```

For specific features:
```swift
import ReaderOperators        // Reader + ReaderT operators
import ConcurrencyFP          // AsyncSequence support
import ConcurrencyOperators   // Async operators
import CombineFP              // Publisher support (Apple platforms)
import CombineOperators       // Combine operators
```

#### Step 2: Tacit Programming Utilities

Before using operators, learn the utilities for point-free style:

```swift
import FP  // Contains curry, flip, compose, etc.

// curry: Convert multi-parameter function to curried form
let add: (Int, Int) -> Int = (+)
let addCurried: (Int) -> (Int) -> Int = curry(+)
let add5 = addCurried(5)  // (Int) -> Int
add5(3)  // 8

// Preferred: Use |> to apply first argument (cleaner than nested parens)
let double = 2 |> curry(*)  // (Int) -> Int
let increment = 1 |> curry(+)  // (Int) -> Int

// Note: Swift doesn't support operator sections like Haskell's (+1) or (*2)
// Use |> curry pattern for partial application

// compose: Chain functions
let addOneThenDouble = increment >>> double  // (Int) -> Int
addOneThenDouble(5)  // 12

// |> pipe operator: Apply value to functions
let result = 5 |> increment |> double  // 12

// flip: Reverse parameter order
let subtractFrom10 = 10 |> curry(-)  // Subtracts FROM 10
subtractFrom10(3)  // 7 (10 - 3)

let subtract10 = 10 |> flip(curry(-))  // Subtracts 10
subtract10(15)  // 5 (15 - 10)
```

**Use tacit style when it's clearer**:
```swift
// ❌ Explicit lambda (harder to read)
array.map { $0 * 2 }

// ✅ Tacit (clearer intent)
let double = 2 |> curry(*)
double <£> array

// ❌ Nested lambdas
array.map { $0 + 1 }.map { $0 * 2 }

// ✅ Composition
let increment = 1 |> curry(+)
let double = 2 |> curry(*)
increment >>> double <£> array
```

#### Step 3: Basic Operators

**Functor** (`<£>`) - Transform values in containers:
```swift
// Optional - tacit style with |> curry
let double = 2 |> curry(*)
let doubled = double <£> Optional(5)  // Optional(10)

// Array - tacit style
let squared = { $0 * $0 } <£> [1, 2, 3]  // [1, 4, 9]
// Note: Swift doesn't have built-in square function, so lambda is fine

// Result - using method reference
let uppercased = String.uppercased <£> Result<String, Error>.success("hello")

// Or with key path
let lengths = (\.count) <£> ["hello", "world"]  // [5, 5]
```

**Applicative** (`<*>`) - Apply wrapped functions:
```swift
// Combine two Optionals
let add = { $0 + $1 }
let result = liftA2Optional(add)(.some(5), .some(3))  // Optional(8)

// Or using pure + apply:
let wrappedAdd = pureOptional { $0 + $1 }
let result = wrappedAdd <*> .some(5) <*> .some(3)  // Optional(8)
```

**Monad** (`>>-`) - Chain operations:
```swift
// Optional chaining
let result = Optional(5) >>- { x in
    guard x > 0 else { return nil }
    return .some(x * 2)
}  // Optional(10)

// Result chaining
let validated = Result.success("hello") >>- { text in
    guard !text.isEmpty else {
        return .failure(ValidationError.empty)
    }
    return .success(text.uppercased())
}  // .success("HELLO")
```

**Kleisli Composition** (`>=>`) - Compose functions:
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
// Example from user: transform and expand array
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
- Method reference? Use tacit: `String.uppercased`, `\.count`
- Complex logic? Lambda is fine: `{ guard $0 > 0 else { return nil }; return $0 }`

**Prefer `|>` for currying**:
```swift
// ✅ Clean with |>
let double = 2 |> curry(*)

// ❌ Nested parentheses
let double = curry(*)(2)
```

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

Or with Kleisli:
```swift
let getA = { optA }
let getB = { (a: A) in optB }
let pipeline = getA >=> getB >=> process >=> (String.uppercased)
```

**Pattern 2: Transform arrays**

Before:
```swift
array.compactMap { $0.value }.map { $0 * 2 }.filter { $0 > 10 }
```

With operators:
```swift
array <£> (\.value) >>- { x in
    guard x * 2 > 10 else { return [] }
    return [x * 2]
}
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

With operators:
```swift
fetch() >>- parse <£> process
// Returns Result<ProcessedData, Error>
```

**Pattern 4: Alternative/Fallback**

```swift
// Try multiple options
let config = userConfig <|> defaultConfig <|> fallbackConfig

// First success or last failure
let result = tryPrimary() <|> trySecondary() <|> tryFallback()
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
| `<&>` | flipped Kleisli | `(B -> M C) -> (A -> M B) -> (A -> M C)` | `g <&> f` |
| `<|>` | alternative | `F A -> F A -> F A` | `opt1 <|> opt2` |
| `>>>` | forward comp | `(A -> B) -> (B -> C) -> (A -> C)` | `f >>> g` |
| `<<<` | backward comp | `(B -> C) -> (A -> B) -> (A -> C)` | `g <<< f` |
| `\|>` | pipe | `A -> (A -> B) -> B` | `5 \|> double` |
| `<>` | semigroup | `A -> A -> A` | `arr1 <> arr2` |

### Learning Path

1. **Start with Functor** (`<£>`) - Learn to transform values
2. **Add Applicative** (`<*>`) - Learn to combine effects
3. **Master Monad** (`>>-`) - Learn to chain operations
4. **Compose with Kleisli** (`>=>`) - Build pipelines
5. **Learn Reader** - Handle dependencies elegantly
6. **Explore ReaderT** - Combine effects

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
- Passing configuration/dependencies
- Environment-based computation
- Want to avoid parameter threading

### Common Gotchas

❌ **Wrong**: Operator on wrong side
```swift
optional <£> { $0 * 2 }  // Error!
```
✅ **Right**: Function on left
```swift
{ $0 * 2 } <£> optional  // ✅
```

❌ **Wrong**: Using methods when operators available
```swift
optional.fmap { $0 * 2 }  // Discouraged
```
✅ **Right**: Use operators
```swift
{ $0 * 2 } <£> optional  // ✅
```

❌ **Wrong**: Mixing function and operator syntax
```swift
optional.flatMap(f) >>- g  // Inconsistent
```
✅ **Right**: Stick with operators
```swift
optional >>- f >>- g  // ✅
```

### Next Steps

After mastering basic operators:
1. Learn Reader monad (use `reader-monad-guide` skill)
2. Refactor existing code (use `convert-to-functional` skill)
3. Debug compositions (use `explain-operators` skill)
4. Explore advanced patterns (ReaderT transformers)

### Ask the developer:
1. What types are they working with (Optional, Result, Array, etc.)?
2. Are they new to functional programming or coming from Haskell/Scala?
3. What specific problem are they trying to solve?
4. Do they prefer seeing step-by-step transformations or final result?

Provide clear, operator-first examples with explanations.
