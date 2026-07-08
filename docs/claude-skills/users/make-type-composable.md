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

The library follows one consistent naming convention throughout — match it so your type feels native alongside `Optional`, `Array`, `Reader`, etc.:

| Role | Instance form | Static/curried form |
|---|---|---|
| Functor | `.map(_:)` | `static func fmap(_:) -> (Self) -> Self` |
| Monad | `.flatMap(_:)` | `static func bind(_:) -> (Self) -> Self` |
| Applicative | — | `static func pure(_:)`, `static func liftA2(_:)`, `static func apply(_:_:)` |

The library already has the operators (`<£>`, `<*>`, `>>-`, `>=>`) defined generically-adjacent to each type — you just need to add the instance/static methods above and, if your type isn't already covered, the operator overloads that delegate to them.

### Implementation Guide

#### Step 1: Implement Functor (Transform Values)

```swift
struct AsyncResult<T: Sendable, E: Error & Sendable>: Sendable {
    let run: @Sendable (@escaping @Sendable (Result<T, E>) -> Void) -> Void

    // Instance method — what callers actually use most of the time
    func map<U>(_ transform: @escaping @Sendable (T) -> U) -> AsyncResult<U, E> {
        AsyncResult<U, E> { callback in
            self.run { result in
                callback(result.map(transform))
            }
        }
    }

    // Static curried form — what the <£> operator delegates to
    static func fmap<U>(
        _ transform: @escaping @Sendable (T) -> U
    ) -> @Sendable (AsyncResult<T, E>) -> AsyncResult<U, E> {
        { $0.map(transform) }
    }
}

// Operator — delegates to the static curried form, never re-implements the logic
func <£> <T, U, E>(_ transform: @escaping @Sendable (T) -> U, _ async: AsyncResult<T, E>) -> AsyncResult<U, E> {
    AsyncResult.fmap(transform)(async)
}

// Now you can use <£>:
let doubled = { $0 * 2 } <£> asyncResult
```

#### Step 2: Implement Applicative (Combine Effects)

```swift
extension AsyncResult {
    // Pure: wrap a value
    static func pure(_ value: T) -> AsyncResult<T, E> where T: Sendable {
        AsyncResult { callback in
            callback(.success(value))
        }
    }

    // Apply: apply wrapped function to wrapped value
    static func apply<U>(
        _ transform: AsyncResult<@Sendable (T) -> U, E>,
        _ value: AsyncResult<T, E>
    ) -> AsyncResult<U, E> {
        AsyncResult<U, E> { callback in
            transform.run { fnResult in
                value.run { valueResult in
                    callback(fnResult.flatMap { fn in
                        valueResult.map(fn)
                    })
                }
            }
        }
    }
}

// Operator
func <*> <T, U, E>(_ f: AsyncResult<@Sendable (T) -> U, E>, _ v: AsyncResult<T, E>) -> AsyncResult<U, E> {
    AsyncResult.apply(f, v)
}
```

#### Step 3: Implement Monad (Chain Computations)

```swift
extension AsyncResult {
    // Instance method
    func flatMap<U>(_ transform: @escaping @Sendable (T) -> AsyncResult<U, E>) -> AsyncResult<U, E> {
        AsyncResult<U, E> { callback in
            self.run { result in
                switch result {
                case let .success(value):
                    transform(value).run(callback)
                case let .failure(error):
                    callback(.failure(error))
                }
            }
        }
    }

    // Static curried form — matches the library's own `bind`/kleisli naming
    static func bind<U>(
        _ transform: @escaping @Sendable (T) -> AsyncResult<U, E>
    ) -> @Sendable (AsyncResult<T, E>) -> AsyncResult<U, E> {
        { $0.flatMap(transform) }
    }

    static func kleisli<U, V>(
        _ f: @escaping @Sendable (T) -> AsyncResult<U, E>,
        _ g: @escaping @Sendable (U) -> AsyncResult<V, E>
    ) -> @Sendable (T) -> AsyncResult<V, E> {
        { t in f(t).flatMap(g) }
    }
}

// Operators — every forward operator needs its flipped counterpart added in the same change
func >>- <T, U, E>(_ async: AsyncResult<T, E>, _ f: @escaping @Sendable (T) -> AsyncResult<U, E>) -> AsyncResult<U, E> {
    async.flatMap(f)
}

func -<< <T, U, E>(_ f: @escaping @Sendable (T) -> AsyncResult<U, E>, _ async: AsyncResult<T, E>) -> AsyncResult<U, E> {
    async >>- f
}

func >=> <T, U, V, E>(
    _ f: @escaping @Sendable (T) -> AsyncResult<U, E>,
    _ g: @escaping @Sendable (U) -> AsyncResult<V, E>
) -> @Sendable (T) -> AsyncResult<V, E> {
    AsyncResult.kleisli(f, g)
}

func <=< <T, U, V, E>(
    _ g: @escaping @Sendable (U) -> AsyncResult<V, E>,
    _ f: @escaping @Sendable (T) -> AsyncResult<U, E>
) -> @Sendable (T) -> AsyncResult<V, E> {
    f >=> g
}
```

### Practical Example: Validated Type

```swift
// Custom type for accumulating validation errors
struct Validated<T> {
    let value: T?
    let errors: [String]

    func map<U>(_ transform: (T) -> U) -> Validated<U> {
        Validated<U>(
            value: value.map(transform),
            errors: errors
        )
    }

    // Applicative (combines errors from both — this is what makes it worth having
    // alongside the library's own `Validation<E, A>`, which does the same thing generically)
    func apply<U>(_ transform: Validated<(T) -> U>) -> Validated<U> {
        switch (transform.value, value) {
        case let (.some(fn), .some(val)):
            Validated<U>(value: fn(val), errors: transform.errors + errors)
        default:
            Validated<U>(value: nil, errors: transform.errors + errors)
        }
    }
}

func <£> <T, U>(_ transform: @escaping (T) -> U, _ validated: Validated<T>) -> Validated<U> {
    validated.map(transform)
}

func <*> <T, U>(_ transform: Validated<(T) -> U>, _ validated: Validated<T>) -> Validated<U> {
    validated.apply(transform)
}

// Usage
let nameValidation = validateName(input)  // Validated<String>
let ageValidation = validateAge(input)    // Validated<Int>

let makeUser: (String) -> (Int) -> User = { name in { age in User(name: name, age: age) } }
let userValidation = makeUser <£> nameValidation <*> ageValidation
```

Before building a bespoke accumulating type like `Validated` above, check whether the library's own `Validation<E, A>` (with `E: Semigroup`) already covers the need — it has the same shape, a lawful Applicative instance, and full operator/transformer coverage already.

### Integration with Library Types

```swift
// Compose with Optional
let maybeAsync: AsyncResult<Int?, Error> = ...
let doubled = { $0.map { $0 * 2 } } <£> maybeAsync  // Still AsyncResult<Int?, Error>

// Wrap with Reader if the computation also needs dependencies
let withConfig: Reader<Config, AsyncResult<Int, Error>> = Reader { config in
    fetchData(config)
}
```

### Type Class Laws

Make sure your implementations satisfy the laws:

**Functor Laws**:
```swift
// Identity: map id = id
customType.map { $0 } == customType

// Composition: map (g . f) = map g . map f
customType.map { g(f($0)) } == customType.map(f).map(g)
```

**Applicative Laws**:
```swift
// Identity: pure id <*> v = v
CustomType.pure({ $0 }) <*> customValue == customValue
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

Use Swift Testing (`@Suite`/`@Test`/`#expect`), not XCTest — this matches the library's own test suite:

```swift
import Testing

@Suite("CustomType — Functor/Monad laws")
struct CustomTypeTests {
    @Test func functorIdentity() {
        let value = CustomType(wrapped: 42)
        #expect(value.map { $0 } == value)
    }

    @Test func monadLeftIdentity() {
        let a = 42
        let f: (Int) -> CustomType<Int> = { CustomType(wrapped: $0 * 2) }
        #expect(CustomType.pure(a) >>- f == f(a))
    }
}
```

### Common Patterns

**Async computations**:
```swift
struct Future<T: Sendable>: Sendable {
    let run: @Sendable (@escaping @Sendable (T) -> Void) -> Void

    func map<U>(_ transform: @escaping @Sendable (T) -> U) -> Future<U> {
        Future<U> { callback in
            self.run { value in
                callback(transform(value))
            }
        }
    }

    func flatMap<U>(_ transform: @escaping @Sendable (T) -> Future<U>) -> Future<U> {
        Future<U> { callback in
            self.run { value in
                transform(value).run(callback)
            }
        }
    }
}
```

Note: the library's own convention for lazy async work is `DeferredTask<A>`/`DeferredStream<A>` (eager `Task`/`AsyncStream` are avoided by design) — check whether that already covers what a custom `Future` type would do before building one.

### When NOT to Implement This

Don't force type class implementations on:
- Types that aren't containers (simple value types)
- Types where the operations don't make semantic sense
- Types where mutation is essential to their purpose

### Ask the developer:
1. What is your custom type? (Show the definition)
2. What does it wrap or represent?
3. What should `map`/`flatMap` do for your type?
4. How should errors/effects combine?
5. Do you need to compose with Reader monad?

Provide complete, working implementations with clear operator definitions and usage examples.
