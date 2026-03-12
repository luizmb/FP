# Add Monad Support to Custom Type

Help implement Functor, Applicative, and Monad type classes for a custom Swift type following the FP library patterns.

## Skill Prompt

You are helping a developer add functional programming support to their custom type using the FP library patterns.

### Instructions:

1. **Analyze the type**: Understand the container type structure and what it wraps
2. **Implement Functor**: Create `fmap` method to transform wrapped values
3. **Implement Applicative**: Create `pure`, `apply`, and `liftA2` functions
4. **Implement Monad**: Create `flatMap`, `bind`, `kleisli` functions
5. **Add Operators**: Create operator overloads for `<£>`, `<*>`, `>>-`, etc.
6. **Verify Laws**: Ensure implementations satisfy:
   - Functor laws: identity, composition
   - Applicative laws: identity, composition, homomorphism, interchange
   - Monad laws: left identity, right identity, associativity
7. **Write Tests**: Generate comprehensive tests for all laws and operators

### Pattern to Follow:

**Functor** (in separate module):
```swift
public extension CustomType {
    func fmap<B>(_ transform: @escaping (A) -> B) -> CustomType<B> {
        // Transform wrapped value
    }

    static func fmap<B>(
        _ transform: @escaping (A) -> B
    ) -> (CustomType<A>) -> CustomType<B> {
        { $0.fmap(transform) }
    }
}
```

**Applicative** (in separate module):
```swift
public func pure<A>(_ value: A) -> CustomType<A> {
    // Wrap value in minimal context
}

public func apply<A, B>(
    _ f: CustomType<(A) -> B>,
    _ fa: CustomType<A>
) -> CustomType<B> {
    // Apply wrapped function to wrapped value
}

public func liftA2<A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (CustomType<A>, CustomType<B>) -> CustomType<C> {
    { fa, fb in
        apply(fa.fmap { a in { b in fn(a, b) } }, fb)
    }
}
```

**Monad** (in separate module):
```swift
public extension CustomType {
    func flatMap<B>(_ transform: @escaping (A) -> CustomType<B>) -> CustomType<B> {
        // Transform and flatten
    }

    static func bind<B>(
        _ transform: @escaping (A) -> CustomType<B>
    ) -> (CustomType<A>) -> CustomType<B> {
        { $0.flatMap(transform) }
    }
}

public func kleisli<A, B, C>(
    _ f: @escaping (A) -> CustomType<B>,
    _ g: @escaping (B) -> CustomType<C>
) -> (A) -> CustomType<C> {
    { a in f(a).flatMap(g) }
}
```

**Operators** (in Operators module):
```swift
// Functor
public func <£> <A, B>(_ transform: @escaping (A) -> B, _ fa: CustomType<A>) -> CustomType<B> {
    fa.fmap(transform)
}

// Applicative
public func <*> <A, B>(_ f: CustomType<(A) -> B>, _ fa: CustomType<A>) -> CustomType<B> {
    apply(f, fa)
}

// Monad
public func >>- <A, B>(_ fa: CustomType<A>, _ f: @escaping (A) -> CustomType<B>) -> CustomType<B> {
    fa.flatMap(f)
}

public func >=> <A, B, C>(
    _ f: @escaping (A) -> CustomType<B>,
    _ g: @escaping (B) -> CustomType<C>
) -> (A) -> CustomType<C> {
    kleisli(f, g)
}
```

**Tests**:
```swift
final class CustomTypeTests: XCTestCase {
    // Functor Laws
    func testFunctorIdentity() {
        let value = CustomType(/* ... */)
        XCTAssertEqual(value.fmap { $0 }, value)
    }

    func testFunctorComposition() {
        let f: (Int) -> Int = { $0 * 2 }
        let g: (Int) -> Int = { $0 + 1 }
        let value = CustomType(/* ... */)

        XCTAssertEqual(
            value.fmap(f).fmap(g),
            value.fmap { g(f($0)) }
        )
    }

    // Applicative Laws
    func testApplicativeIdentity() {
        let value = CustomType(/* ... */)
        XCTAssertEqual(pure({ $0 }) <*> value, value)
    }

    // Monad Laws
    func testMonadLeftIdentity() {
        let a = 5
        let f: (Int) -> CustomType<Int> = { pure($0 * 2) }

        XCTAssertEqual(pure(a) >>- f, f(a))
    }

    func testMonadRightIdentity() {
        let m = CustomType(/* ... */)
        XCTAssertEqual(m >>- pure, m)
    }

    func testMonadAssociativity() {
        let m = CustomType(/* ... */)
        let f: (Int) -> CustomType<Int> = { pure($0 * 2) }
        let g: (Int) -> CustomType<Int> = { pure($0 + 1) }

        XCTAssertEqual(
            (m >>- f) >>- g,
            m >>- { a in f(a) >>- g }
        )
    }
}
```

### Ask the developer:
1. What is the custom type they want to add support for?
2. What does the type wrap (if it's a container)?
3. How should composition work for their type?
4. Should it support Sendable for concurrency?
5. Does it need platform availability annotations?

Generate complete, working code following FP library conventions.
