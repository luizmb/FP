# Make Your Custom Type Work with FP Operators

Help users make their custom types compatible with the FP library's operators for seamless composition.

## Skill Prompt

You are helping a developer make their custom Swift type work with the FP library's operators (`<£>`, `<*>`, `>>-`, etc.) so they can compose it naturally with other types in the library.

**Goal**: Enable the user's custom type to work with existing library operators, not extend the library itself.

### When to Use This

Your custom type should implement type class support when:
- It's a container/wrapper type (wraps other values)
- You want to compose it with Optional, Result, Array, etc.
- You want to use `<£>`, `<*>`, `>>-` operators on your type
- You need functional transformations and compositions

### What You'll Implement

For most container types, you'll implement:
1. **Functor** - Transform wrapped values
2. **Applicative** - Combine multiple wrapped values
3. **Monad** - Chain dependent computations

The library already has these operators defined; you just need to make your type conform to the expected patterns.

### Implementation Guide

#### Step 1: Implement Functor (Transform Values)

Your type needs a `map`-like function:

```swift
struct AsyncResult<T, E: Error> {
    let run: (@escaping (Result<T, E>) -> Void) -> Void

    // Functor: transform success values
    func fmap<U>(_ transform: @escaping (T) -> U) -> AsyncResult<U, E> {
        AsyncResult<U, E> { callback in
            self.run { result in
                callback(result.map(transform))
            }
        }
    }
}

// Now you can use <£> operator:
let doubled = { $0 * 2 } <£> asyncResult
```

#### Step 2: Implement Applicative (Combine Effects)

Provide ways to combine your wrapped values:

```swift
extension AsyncResult {
    // Pure: wrap a value
    static func pure(_ value: T) -> AsyncResult<T, E> {
        AsyncResult { callback in
            callback(.success(value))
        }
    }

    // Apply: apply wrapped function to wrapped value
    func apply<U>(_ transform: AsyncResult<(T) -> U, E>) -> AsyncResult<U, E> {
        AsyncResult<U, E> { callback in
            transform.run { fnResult in
                self.run { valueResult in
                    callback(fnResult.flatMap { fn in
                        valueResult.map(fn)
                    })
                }
            }
        }
    }
}

// Now you can use <*> operator (if defined for your type):
// For types not in the library, you may need to define the operator yourself
```

#### Step 3: Implement Monad (Chain Computations)

Add flatMap for dependent computations:

```swift
extension AsyncResult {
    // Monad: flatMap for chaining
    func flatMap<U>(_ transform: @escaping (T) -> AsyncResult<U, E>) -> AsyncResult<U, E> {
        AsyncResult<U, E> { callback in
            self.run { result in
                switch result {
                case .success(let value):
                    transform(value).run(callback)
                case .failure(let error):
                    callback(.failure(error))
                }
            }
        }
    }
}

// Now you can use >>- operator (if defined for your type):
// asyncResult >>- transform
```

#### Step 4: Define Operators for Your Type (If Needed)

If the library doesn't already have operators for your type, define them:

```swift
// Functor operators
func <£> <T, U, E>(_ transform: @escaping (T) -> U, _ async: AsyncResult<T, E>) -> AsyncResult<U, E> {
    async.fmap(transform)
}

// Monad operators
func >>- <T, U, E>(_ async: AsyncResult<T, E>, _ transform: @escaping (T) -> AsyncResult<U, E>) -> AsyncResult<U, E> {
    async.flatMap(transform)
}

// Kleisli composition
func >=> <T, U, V, E>(
    _ f: @escaping (T) -> AsyncResult<U, E>,
    _ g: @escaping (U) -> AsyncResult<V, E>
) -> (T) -> AsyncResult<V, E> {
    { t in f(t) >>- g }
}
```

### Practical Example: Validated Type

```swift
// Custom type for accumulating validation errors
struct Validated<T> {
    let value: T?
    let errors: [String]

    // Functor
    func fmap<U>(_ transform: (T) -> U) -> Validated<U> {
        Validated<U>(
            value: value.map(transform),
            errors: errors
        )
    }

    // Applicative (combines errors from both)
    func apply<U>(_ transform: Validated<(T) -> U>) -> Validated<U> {
        switch (transform.value, self.value) {
        case (.some(let fn), .some(let val)):
            return Validated<U>(
                value: fn(val),
                errors: transform.errors + self.errors
            )
        case _:
            return Validated<U>(
                value: nil,
                errors: transform.errors + self.errors
            )
        }
    }

    // Monad (short-circuits on first error)
    func flatMap<U>(_ transform: (T) -> Validated<U>) -> Validated<U> {
        guard let val = value, errors.isEmpty else {
            return Validated<U>(value: nil, errors: errors)
        }
        let result = transform(val)
        return Validated<U>(
            value: result.value,
            errors: result.errors
        )
    }
}

// Define operators
func <£> <T, U>(_ transform: @escaping (T) -> U, _ validated: Validated<T>) -> Validated<U> {
    validated.fmap(transform)
}

func <*> <T, U>(_ transform: Validated<(T) -> U>, _ validated: Validated<T>) -> Validated<U> {
    validated.apply(transform)
}

func >>- <T, U>(_ validated: Validated<T>, _ transform: @escaping (T) -> Validated<U>) -> Validated<U> {
    validated.flatMap(transform)
}

// Usage
let nameValidation = validateName(input) // Validated<String>
let ageValidation = validateAge(input)   // Validated<Int>

let userValidation = liftA2 { (name: String, age: Int) in
    User(name: name, age: age)
} <£> nameValidation <*> ageValidation

// Or with bind:
let result = validateName(input) >>- { name in
    validateAge(input) >>- { age in
        .pure(User(name: name, age: age))
    }
}
```

### Integration with Library Types

Your custom type can compose with library types:

```swift
// Compose with Optional
let maybeAsync: AsyncResult<Int?, Error> = ...
let doubled = { $0 * 2 } <£> maybeAsync // Still AsyncResult<Int?, Error>

// Then use ReaderT if needed
let withConfig: Reader<Config, AsyncResult<Int, Error>> = Reader { config in
    fetchData(config)
}

// Can use ReaderT operators if you implement them for AsyncResult
```

### Type Class Laws

Make sure your implementations satisfy the laws:

**Functor Laws**:
```swift
// Identity: fmap id = id
customType.fmap { $0 } == customType

// Composition: fmap (g . f) = fmap g . fmap f
customType.fmap { g(f($0)) } == customType.fmap(f).fmap(g)
```

**Applicative Laws**:
```swift
// Identity: pure id <*> v = v
pure({ $0 }) <*> customValue == customValue

// Composition: pure (.) <*> u <*> v <*> w = u <*> (v <*> w)
// (Complex, but ensures associativity of effects)
```

**Monad Laws**:
```swift
// Left identity: pure a >>- f = f a
CustomType.pure(a) >>- f == f(a)

// Right identity: m >>- pure = m
customValue >>- CustomType.pure == customValue

// Associativity: (m >>- f) >>- g = m >>- (\x -> f x >>- g)
(customValue >>- f) >>- g == customValue >>- { x in f(x) >>- g }
```

### Testing Your Implementation

```swift
import XCTest

class CustomTypeTests: XCTestCase {
    func testFunctorIdentity() {
        let value = CustomType(wrapped: 42)
        XCTAssertEqual(value.fmap { $0 }, value)
    }

    func testMonadLeftIdentity() {
        let a = 42
        let f: (Int) -> CustomType<Int> = { CustomType(wrapped: $0 * 2) }
        XCTAssertEqual(CustomType.pure(a) >>- f, f(a))
    }

    // ... more tests
}
```

### Common Patterns

**Async computations**:
```swift
struct Future<T> {
    let run: (@escaping (T) -> Void) -> Void

    func fmap<U>(_ transform: @escaping (T) -> U) -> Future<U> {
        Future<U> { callback in
            self.run { value in
                callback(transform(value))
            }
        }
    }

    func flatMap<U>(_ transform: @escaping (T) -> Future<U>) -> Future<U> {
        Future<U> { callback in
            self.run { value in
                transform(value).run(callback)
            }
        }
    }
}
```

**State management**:
```swift
struct State<S, A> {
    let run: (S) -> (A, S)

    func fmap<B>(_ transform: @escaping (A) -> B) -> State<S, B> {
        State<S, B> { state in
            let (value, newState) = self.run(state)
            return (transform(value), newState)
        }
    }

    func flatMap<B>(_ transform: @escaping (A) -> State<S, B>) -> State<S, B> {
        State<S, B> { state in
            let (value, newState) = self.run(state)
            return transform(value).run(newState)
        }
    }
}
```

### When NOT to Implement This

Don't force type class implementations on:
- Types that aren't containers (simple value types)
- Types where the operations don't make semantic sense
- Types where mutation is essential to their purpose

### Ask the developer:
1. What is your custom type? (Show the definition)
2. What does it wrap or represent?
3. What should `map`/`fmap` do for your type?
4. What should `flatMap` do for your type?
5. How should errors/effects combine?
6. Do you need to compose with Reader monad?

Provide complete, working implementations with clear operator definitions and usage examples.
