# FP

Functional Programming utilities for Swift, inspired by Haskell and other functional languages.

## Overview

This library provides a comprehensive functional programming toolkit for Swift, including:

- **Core type classes**: Functor, Applicative, Monad
- **Foundation type extensions**: Optional, Result, Array, Either
- **Reader monad**: Environment-based computations
- **ReaderT transformers**: Compose Reader with other monads
- **Concurrency support**: AsyncSequence functors and monads
- **Combine integration**: Publisher functors and monads (Apple platforms)
- **Functional operators**: Haskell-style operators with correct precedence

## Modules

### Core Modules

- **FP**: Foundation types (Optional, Result, Array) with Functor/Applicative/Monad
- **Either**: Sum type with Functor/Applicative/Monad
- **Reader**: Reader monad for dependency injection
- **Operators**: Operators for core types (`<£>`, `<*>`, `>>-`, `>=>`, etc.)

### Reader Transformers

- **ReaderOperators**: ReaderT operators for Optional, Result, Array, nested Reader
- **ReaderEither**: ReaderT + Either implementations
- **ReaderEitherOperators**: Operators for Either transformers

### Concurrency

- **ConcurrencyFP**: AsyncSequence Functor, Applicative, Monad
- **ConcurrencyOperators**: Operators for async sequences
- **ReaderConcurrencyFP**: ReaderT + AsyncSequence transformers
- **ReaderConcurrencyOperators**: Operators for async transformers

### Combine (Apple Platforms)

- **CombineFP**: Publisher Functor, Applicative, Monad
- **CombineOperators**: Operators for publishers
- **CombineEither**: Publisher + Either bridge
- **ReaderCombineFP**: ReaderT + Publisher transformers
- **ReaderCombineOperators**: Operators for publisher transformers

### Specialized

- **EitherOperators**: Functor/Applicative/Monad operators for Either

## Features

### Functors

Transform values inside containers:

```swift
[1, 2, 3] <£> { $0 * 2 }           // [2, 4, 6]
Optional(5) <£> { $0 * 2 }         // Optional(10)
Result.success(5) <£> { $0 * 2 }   // .success(10)
```

### Applicatives

Apply functions in containers to values in containers:

```swift
let add: (Int, Int) -> Int = (+)
liftA2(add)([1, 2], [10, 20])      // [11, 21, 12, 22]

let optAdd = liftA2Optional(add)
optAdd(.some(5), .some(3))          // .some(8)
```

### Monads

Chain computations that may fail or have effects:

```swift
// Optional chaining
Optional(5) >>- { x in
    guard x > 0 else { return nil }
    return .some(x * 2)
}  // Optional(10)

// Result chaining
Result.success(5) >>- { x in
    guard x > 0 else { return .failure(MyError()) }
    return .success(x * 2)
}  // .success(10)

// Array flatMap
[1, 2, 3] >>- { [$0, $0 * 2] }     // [1, 2, 2, 4, 3, 6]
```

### Kleisli Composition

Compose monadic functions:

```swift
let validate: (Int) -> Int? = { $0 > 0 ? .some($0) : nil }
let double: (Int) -> Int? = { .some($0 * 2) }

let composed = validate >=> double
composed(5)   // Optional(10)
composed(-1)  // nil
```

### Reader Monad

Environment-based computations:

```swift
struct Config {
    let multiplier: Int
    let offset: Int
}

let computation = Reader<Config, Int> { env in
    env.multiplier * 2 + env.offset
}

computation(Config(multiplier: 5, offset: 3))  // 13
```

### ReaderT Transformers

Compose Reader with other monads:

```swift
// ReaderT + Optional
let readerOpt: Reader<Config, Int?> = Reader { env in
    guard env.multiplier > 0 else { return nil }
    return .some(env.multiplier * 2)
}

let result = readerOpt.mapT { $0 * 3 }
result(Config(multiplier: 5, offset: 0))  // Optional(30)

// ReaderT + AsyncSequence
let readerAsync: Reader<Config, AsyncStream<Int>> = Reader { env in
    AsyncStream { continuation in
        continuation.yield(env.multiplier)
        continuation.yield(env.multiplier * 2)
        continuation.finish()
    }
}

let mapped = readerAsync.mapT { $0 * 2 }
```

### Function Composition & Tacit Programming

The library encourages point-free (tacit) style with utilities like `curry`, `flip`, and composition operators:

```swift
import FP  // For curry, flip, compose utilities

// Tacit style with curry
let double = curry(*)(2)  // (Int) -> Int
let increment = curry(+)(1)  // (Int) -> Int

// Composition
let addOneThenDouble = increment >>> double
addOneThenDouble(5)  // 12

// Pipe operator for data flow
5 |> increment |> double  // 12

// With operators (operators first!)
let array = [1, 2, 3]

// ❌ Avoid: Methods with lambdas
array.map { $0 + 1 }.map { $0 * 2 }

// ✅ Better: Operators
{ $0 + 1 } <£> array <£> { $0 * 2 }

// ✅✅ Best: Tacit + operators
increment <£> array <£> double
// Or composed:
(increment >>> double) <£> array  // [4, 6, 8]

// Currying for partial application
let multiply = curry(*)
let multiplyBy3 = multiply(3)
multiplyBy3 <£> [1, 2, 3]  // [3, 6, 9]
```

### Semigroup

```swift
[1, 2] <> [3, 4]                   // [1, 2, 3, 4]
"Hello, " <> "World!"              // "Hello, World!"
.some(5) <> nil                    // .some(5)
.success(5) <> .failure(error)     // .success(5)
```

## ReaderT Support

The library provides complete ReaderT (Reader Transformer) implementations for composing Reader with:

- **Optional**: `Reader<Env, A?>` with Functor, Applicative, Monad
- **Result**: `Reader<Env, Result<A, E>>` with Functor, Applicative, Monad
- **Either**: `Reader<Env, Either<L, R>>` with Functor, Applicative, Monad
- **Array**: `Reader<Env, [A]>` with Functor, Applicative, Monad
- **Reader** (nested): `Reader<Env1, Reader<Env2, A>>` with Functor, Applicative, Monad
- **AsyncSequence**: `Reader<Env, AsyncStream<A>>` with Functor, Applicative, Monad
- **Publisher**: `Reader<Env, AnyPublisher<A, E>>` with Functor, Applicative, Monad (Apple platforms)

Each transformer provides:
- Extension methods (`mapT`, `flatMapT`)
- Standalone functions (`applyReaderX`, `liftA2ReaderX`, `bindReaderX`)
- Operators (`<£>`, `<*>`, `>>-`, `>=>`, etc.)

## Operator Reference

### Functor
- `<£>` - fmap (map)
- `£>` - replace right
- `<£` - replace left
- `<&>` - flipped fmap

### Applicative
- `<*>` - apply
- `*>` - sequence right
- `<*` - sequence left

### Monad
- `>>-` - bind (flatMap)
- `-<<` - flipped bind
- `>=>` - Kleisli composition (left-to-right)
- `<&>` - Kleisli composition (right-to-left)

### Alternative
- `<|>` - alternative

### Function
- `>>>` - forward composition
- `<<<` - backward composition
- `•` - composition (alternative symbol)
- `|>` - pipe (forward application)
- `<|` - backward application
- `£` - low-precedence application

### Semigroup
- `<>` - append/concat
- `++` - array/list concatenation

## Platform Support

- **macOS 10.15+**, **iOS 13.0+**, **tvOS 13.0+**, **watchOS 6.0+** for async features
- **macOS 13.0+**, **iOS 16.0+**, **tvOS 16.0+**, **watchOS 9.0+** for parameterized existentials
- **Linux** compatible (Combine features conditionally compiled with `#if canImport(Combine)`)

## Testing

**356 tests** covering:
- Functor laws (identity, composition)
- Applicative laws (identity, composition, homomorphism)
- Monad laws (left identity, right identity, associativity)
- All operator implementations
- ReaderT transformers for all inner types
- AsyncSequence concurrency support
- Combine publisher support

```bash
swift test
# Test Suite 'All tests' passed
# Executed 356 tests, with 0 failures
```

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/luizmb/FP.git", from: "1.0.0")
]
```

Then import the modules you need:

```swift
import FP
import Reader
import Either
import Operators
import ConcurrencyFP
// etc.
```

## Documentation

- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - Complete feature list
- [PRECEDENCE_CORRECTIONS.md](PRECEDENCE_CORRECTIONS.md) - Operator precedence details

## Claude AI Skills

AI-powered development assistance organized by audience:

**For Library Users** (`docs/claude-skills/users/`):
- **getting-started** ⭐ - Learn operators and tacit programming
- **convert-to-functional** - Refactor to operators + point-free style
- **explain-operators** - Debug operator compositions
- **reader-monad-guide** - Dependency injection patterns
- **make-type-composable** - Make custom types work with operators

**For Library Contributors** (`docs/claude-skills/contributors/`):
- **add-monad-support** - Implement type classes in library
- **create-readert-transformer** - Create new transformers

**Philosophy**: Operators first (`<£>`, `>>-`, `>=>`), tacit programming when clear (`(*2)`, `(+1)`), compose everything (`>>>`, `|>`).

See [docs/claude-skills/README.md](docs/claude-skills/README.md) for detailed usage.

## Design Principles

1. **Type Safety**: Leverage Swift's type system with generic constraints
2. **Consistency**: All monads follow the same patterns and naming
3. **Haskell Compatibility**: Operators match Haskell precedence and associativity
4. **Testing**: Comprehensive test coverage ensures correctness
5. **Documentation**: Haskell type signatures in comments for reference
6. **Modularity**: Separate modules for different concerns (FP vs Operators)
7. **Platform Support**: Conditional compilation for platform-specific features

## License

MIT

## Contributing

Contributions welcome! Please ensure:
- All tests pass (`swift test`)
- New features include tests
- Code follows existing patterns
- Documentation is updated
