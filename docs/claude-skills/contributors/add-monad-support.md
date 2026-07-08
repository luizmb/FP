# Add Monad Support to Custom Type

Help implement Functor, Applicative, and Monad type classes for a custom Swift type following the FP library's own internal conventions — for someone contributing a new type *to the library itself*, not a user extending the library from their own app. (If that's the goal instead, use the `make-type-composable` skill.)

## Skill Prompt

You are helping a developer add a new type to the FP library, following its established conventions exactly.

### Instructions:

1. **Analyze the type**: Understand the container type structure and what it wraps
2. **Two-layer split**: Named functions go in the core module (`CoreFP` or `DataStructure`); operators go in the companion `*Operators` module (`CoreFPOperators` or `DataStructureOperators`) and must delegate to the named function — never re-implement logic inline
3. **Implement Functor**: `.map(_:)` instance method + `static func fmap(_:)` curried form
4. **Implement Applicative**: `static func pure(_:)`, `static func apply(_:_:)`, `static func liftA2(_:)`
5. **Implement Monad**: `.flatMap(_:)` instance method + `static func bind(_:)` curried form + `static func kleisli(_:_:)`
6. **Add operators, both directions**: every operator with a directional sense (`<£>`/`<&>`, `>>-`/`-<<`, `>=>`/`<=<`) needs its flipped counterpart added in the *same* change — the flipped version delegates to the forward one with arguments swapped, never duplicates logic
7. **Sendable-first**: escaping closures are `@Sendable`; the type itself conforms to `Sendable` (conditionally, if generic) wherever its stored properties allow
8. **Verify Laws**: Functor (identity, composition), Applicative (identity, composition, homomorphism, interchange), Monad (left identity, right identity, associativity)
9. **Write tests in all four targets that apply**: `CoreFPTests`/`DataStructureTests` (named functions, **no operator symbols**) and `CoreFPOperatorsTests`/`DataStructureOperatorsTests` (must exercise the operator symbol itself) — both sets are mandatory, not optional

### Pattern to Follow:

**Functor** (core module — e.g. `Sources/DataStructure/CustomType/CustomType+Functor.swift`):
```swift
public extension CustomType {
    /// Instance method — most call sites use this directly.
    func map<B>(_ transform: @escaping @Sendable (A) -> B) -> CustomType<B> {
        // Transform wrapped value
    }

    /// Static curried form — what the `<£>` operator delegates to.
    static func fmap<B>(
        _ transform: @escaping @Sendable (A) -> B
    ) -> @Sendable (CustomType<A>) -> CustomType<B> {
        { $0.map(transform) }
    }
}
```

**Applicative** (core module):
```swift
public extension CustomType {
    static func pure(_ value: A) -> CustomType<A> where A: Sendable {
        // Wrap value in minimal context
    }

    static func apply<B>(
        _ f: CustomType<@Sendable (A) -> B>,
        _ fa: CustomType<A>
    ) -> CustomType<B> {
        // Apply wrapped function to wrapped value
    }

    static func liftA2<B, C>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> @Sendable (CustomType<A>, CustomType<B>) -> CustomType<C> {
        { fa, fb in
            CustomType.apply(fa.map { a in { @Sendable b in fn(a, b) } }, fb)
        }
    }
}
```

**Monad** (core module):
```swift
public extension CustomType {
    func flatMap<B>(_ transform: @escaping @Sendable (A) -> CustomType<B>) -> CustomType<B> {
        // Transform and flatten
    }

    static func bind<B>(
        _ transform: @escaping @Sendable (A) -> CustomType<B>
    ) -> @Sendable (CustomType<A>) -> CustomType<B> {
        { $0.flatMap(transform) }
    }

    /// Named Kleisli composition — the `>=>`/`<=<` operators delegate to this,
    /// never inline `{ a in fn1(a).flatMap(fn2) }` directly in the operator body.
    static func kleisli<B, C>(
        _ f: @escaping @Sendable (A) -> CustomType<B>,
        _ g: @escaping @Sendable (B) -> CustomType<C>
    ) -> @Sendable (A) -> CustomType<C> {
        { a in f(a).flatMap(g) }
    }
}
```

**Operators** (companion `*Operators` module — every forward operator paired with its flip, added together):
```swift
// Functor
public func <£> <A, B>(_ transform: @escaping @Sendable (A) -> B, _ fa: CustomType<A>) -> CustomType<B> {
    CustomType.fmap(transform)(fa)
}
public func <&> <A, B>(_ fa: CustomType<A>, _ transform: @escaping @Sendable (A) -> B) -> CustomType<B> {
    transform <£> fa
}

// Applicative (symmetric — no flip)
public func <*> <A, B>(_ f: CustomType<@Sendable (A) -> B>, _ fa: CustomType<A>) -> CustomType<B> {
    CustomType.apply(f, fa)
}

// Monad
public func >>- <A, B>(_ fa: CustomType<A>, _ f: @escaping @Sendable (A) -> CustomType<B>) -> CustomType<B> {
    fa.flatMap(f)
}
public func -<< <A, B>(_ f: @escaping @Sendable (A) -> CustomType<B>, _ fa: CustomType<A>) -> CustomType<B> {
    fa >>- f
}

// Kleisli composition
public func >=> <A, B, C>(
    _ f: @escaping @Sendable (A) -> CustomType<B>,
    _ g: @escaping @Sendable (B) -> CustomType<C>
) -> @Sendable (A) -> CustomType<C> {
    CustomType.kleisli(f, g)
}
public func <=< <A, B, C>(
    _ g: @escaping @Sendable (B) -> CustomType<C>,
    _ f: @escaping @Sendable (A) -> CustomType<B>
) -> @Sendable (A) -> CustomType<C> {
    f >=> g
}
```

**Tests — the four-target split is mandatory**:

`CoreFPTests`/`DataStructureTests` (named functions only, **no custom operator symbols** — catch yourself if you write `value <£> f` here, use `CustomType.map(value, f)` instead... actually since `map` is an instance method here, call it as `value.map(f)`):
```swift
import Testing

@Suite("CustomType — Functor/Monad laws (named functions)")
struct CustomTypeCoreTests {
    @Test func functorIdentity() {
        let value = CustomType(/* ... */)
        #expect(value.map { $0 } == value)
    }

    @Test func functorComposition() {
        let f: (Int) -> Int = { $0 * 2 }
        let g: (Int) -> Int = { $0 + 1 }
        let value = CustomType(/* ... */)
        #expect(value.map(f).map(g) == value.map { g(f($0)) })
    }

    @Test func monadLeftIdentity() {
        let a = 5
        let f: (Int) -> CustomType<Int> = { .pure($0 * 2) }
        #expect(CustomType.pure(a).flatMap(f) == f(a))
    }

    @Test func monadRightIdentity() {
        let m = CustomType(/* ... */)
        #expect(m.flatMap(CustomType.pure) == m)
    }

    @Test func monadAssociativity() {
        let m = CustomType(/* ... */)
        let f: (Int) -> CustomType<Int> = { .pure($0 * 2) }
        let g: (Int) -> CustomType<Int> = { .pure($0 + 1) }
        #expect(m.flatMap(f).flatMap(g) == m.flatMap { a in f(a).flatMap(g) })
    }
}
```

`CoreFPOperatorsTests`/`DataStructureOperatorsTests` (must exercise the operator symbol itself, thin by design — only verifying the syntax delegates correctly):
```swift
import Testing

@Suite("CustomType — operator delegation")
struct CustomTypeOperatorsTests {
    @Test func fmapOperatorMatchesNamedFunction() {
        let value = CustomType(/* ... */)
        let f: @Sendable (Int) -> Int = { $0 * 2 }
        #expect((f <£> value) == value.map(f))
    }

    @Test func bindOperatorMatchesNamedFunction() {
        let value = CustomType(/* ... */)
        let f: @Sendable (Int) -> CustomType<Int> = { .pure($0 * 2) }
        #expect((value >>- f) == value.flatMap(f))
    }

    @Test func kleisliOperatorMatchesNamedFunction() {
        let f: @Sendable (Int) -> CustomType<Int> = { .pure($0 * 2) }
        let g: @Sendable (Int) -> CustomType<Int> = { .pure($0 + 1) }
        #expect((f >=> g)(3) == CustomType.kleisli(f, g)(3))
    }
}
```

### Ask the developer:
1. What is the custom type they want to add support for?
2. What does the type wrap (if it's a container)?
3. How should composition work for their type?
4. Does it already need a monad transformer combo with an existing library type (`ReaderT`, `WriterT`, etc.)? If so, use the `create-readert-transformer` skill instead/as well.
5. Does it need platform availability annotations?

Generate complete, working code following FP library conventions — named function + operator + both test sets + `Sendable`-first, every time.
