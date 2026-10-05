# Adding functor / applicative / monad support to a library type

The worked example is a minimal `Box<A>` (a value plus nothing), so the shape of each file is visible without the type's own logic in the way. Swap in the real type and keep the shape. All blocks below compile together.

## Contents

- Checklist
- The type
- Functor
- Applicative
- Monad
- Operators
- Named-function tests
- Operator tests
- Extra surfaces

## Checklist

1. Decide which instances are lawful for the type. Write that down before coding; it decides which operators exist.
2. Named functions in the core module, one file per instance (`Sources/DataStructure/Box/Box+Functor.swift`, `+Applicative`, `+Monad`, …).
3. Operators in the operator module (`Sources/DataStructureOperators/Box/Box+Operators.swift`), every directional one with its flip.
4. Tests in both targets (named, operators), including the laws.
5. `Sendable` conformance, DocC comments with the Haskell signature, CHANGELOG entry, DocC article if the type has one.
6. If the type also needs `Prism`s (enums) follow the hand-written prism pattern of `Either` / `Loading` and keep it in sync with what `@Prisms` generates (see CONTRIBUTING).

## The type

```swift
import FP

public struct Box<A> {
    public let value: A

    public init(_ value: A) {
        self.value = value
    }
}

extension Box: Sendable where A: Sendable {}
extension Box: Equatable where A: Equatable {}
```

## Functor

```swift
public extension Box {
    /// fmap :: (a -> b) -> f a -> f b
    func map<B>(_ fn: (A) -> B) -> Box<B> {
        Box<B>(fn(value))
    }

    /// Curried, point-free form of ``map(_:)``.
    static func fmap<B>(_ fn: @escaping @Sendable (A) -> B) -> @Sendable (Box<A>) -> Box<B> {
        { $0.map(fn) }
    }
}
```

Instance methods that run the closure immediately can take it non-escaping (like stdlib `map`); anything that stores or returns it takes `@escaping @Sendable`.

## Applicative

```swift
public extension Box {
    /// pure :: a -> f a
    static func pure(_ value: A) -> Box<A> {
        Box(value)
    }

    /// (<*>) :: f (a -> b) -> f a -> f b
    static func apply<Input>(_ fn: Box<@Sendable (Input) -> A>, _ input: Box<Input>) -> Box<A> {
        Box(fn.value(input.value))
    }

    /// liftA2 :: (a -> b -> c) -> f a -> f b -> f c
    static func liftA2<A1, A2>(_ fn: @escaping @Sendable (A1, A2) -> A) -> @Sendable (Box<A1>, Box<A2>) -> Box<A> {
        { first, second in Box(fn(first.value, second.value)) }
    }

    /// (*>) :: f a -> f b -> f b
    func seqRight<B>(_ rhs: Box<B>) -> Box<B> {
        rhs
    }

    /// (<*) :: f a -> f b -> f a
    func seqLeft<B>(_: Box<B>) -> Box<A> {
        self
    }
}
```

## Monad

```swift
public extension Box {
    /// (>>=) :: m a -> (a -> m b) -> m b
    func flatMap<B>(_ fn: (A) -> Box<B>) -> Box<B> {
        fn(value)
    }

    /// Curried, point-free form of ``flatMap(_:)``.
    static func bind<B>(_ fn: @escaping @Sendable (A) -> Box<B>) -> @Sendable (Box<A>) -> Box<B> {
        { $0.flatMap(fn) }
    }

    /// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
    static func kleisli<B, C>(
        _ first: @escaping @Sendable (A) -> Box<B>,
        _ second: @escaping @Sendable (B) -> Box<C>
    ) -> @Sendable (A) -> Box<C> {
        { first($0).flatMap(second) }
    }

    /// (<=<) :: (b -> m c) -> (a -> m b) -> a -> m c
    static func kleisliBack<B, C>(
        _ second: @escaping @Sendable (B) -> Box<C>,
        _ first: @escaping @Sendable (A) -> Box<B>
    ) -> @Sendable (A) -> Box<C> {
        kleisli(first, second)
    }
}

/// join :: m (m a) -> m a
public func join<A>(_ nested: Box<Box<A>>) -> Box<A> {
    nested.flatMap(id)
}
```

## Operators

Operator overloads only delegate. The flipped one calls the forward one (or the same named function) with the arguments swapped:

```swift
public func <£> <A, B>(_ fn: @escaping @Sendable (A) -> B, _ box: Box<A>) -> Box<B> {
    Box.fmap(fn)(box)
}

public func <&> <A, B>(_ box: Box<A>, _ fn: @escaping @Sendable (A) -> B) -> Box<B> {
    fn <£> box
}

public func £> <A, B: Sendable>(_ box: Box<A>, _ value: B) -> Box<B> {
    box.map(const(value))
}

public func <£ <A, B: Sendable>(_ value: B, _ box: Box<A>) -> Box<B> {
    box £> value
}

public func <*> <A, B>(_ fn: Box<@Sendable (A) -> B>, _ box: Box<A>) -> Box<B> {
    Box.apply(fn, box)
}

public func *> <A, B>(_ lhs: Box<A>, _ rhs: Box<B>) -> Box<B> {
    lhs.seqRight(rhs)
}

public func <* <A, B>(_ lhs: Box<A>, _ rhs: Box<B>) -> Box<A> {
    lhs.seqLeft(rhs)
}

public func >>- <A, B>(_ box: Box<A>, _ fn: @escaping @Sendable (A) -> Box<B>) -> Box<B> {
    Box.bind(fn)(box)
}

public func -<< <A, B>(_ fn: @escaping @Sendable (A) -> Box<B>, _ box: Box<A>) -> Box<B> {
    box >>- fn
}

public func >=> <A, B, C>(
    _ first: @escaping @Sendable (A) -> Box<B>,
    _ second: @escaping @Sendable (B) -> Box<C>
) -> @Sendable (A) -> Box<C> {
    Box.kleisli(first, second)
}

public func <=< <A, B, C>(
    _ second: @escaping @Sendable (B) -> Box<C>,
    _ first: @escaping @Sendable (A) -> Box<B>
) -> @Sendable (A) -> Box<C> {
    Box.kleisliBack(second, first)
}
```

## Named-function tests

In `DataStructureTests` (or `CoreFPTests`): named functions only, not one custom operator symbol. Laws first, then behaviour.

```swift
import Testing

@Suite("Box laws (named functions)")
struct BoxLawTests {
    let double: @Sendable (Int) -> Int = { $0 * 2 }
    let increment: @Sendable (Int) -> Int = { $0 + 1 }
    let half: @Sendable (Int) -> Box<Int> = { Box($0 / 2) }
    let negate: @Sendable (Int) -> Box<Int> = { Box(-$0) }

    @Test func functorIdentity() {
        #expect(Box(3).map(id) == Box(3))
    }

    @Test func functorComposition() {
        #expect(Box(3).map(double).map(increment) == Box(3).map(compose(double, increment)))
    }

    @Test func applicativeHomomorphism() {
        #expect(Box.apply(Box<@Sendable (Int) -> Int>.pure(double), Box.pure(3)) == Box.pure(double(3)))
    }

    @Test func monadLeftIdentity() {
        #expect(Box.pure(8).flatMap(half) == half(8))
    }

    @Test func monadRightIdentity() {
        #expect(Box(8).flatMap(Box.pure) == Box(8))
    }

    @Test func monadAssociativity() {
        #expect(Box(8).flatMap(half).flatMap(negate) == Box(8).flatMap { half($0).flatMap(negate) })
    }

    @Test func kleisliMatchesFlatMap() {
        #expect(Box.kleisli(half, negate)(8) == half(8).flatMap(negate))
    }
}
```

## Operator tests

In `DataStructureOperatorsTests` (or `CoreFPOperatorsTests`): thin, one per operator, each using the symbol and comparing with the named function.

```swift
@Suite("Box operators")
struct BoxOperatorTests {
    let double: @Sendable (Int) -> Int = { $0 * 2 }
    let half: @Sendable (Int) -> Box<Int> = { Box($0 / 2) }

    @Test func fmapOperators() {
        #expect((double <£> Box(3)) == Box(3).map(double))
        #expect((Box(3) <&> double) == Box(3).map(double))
        #expect((Box(3) £> "x") == Box("x"))
        #expect(("x" <£ Box(3)) == Box("x"))
    }

    @Test func applicativeOperators() {
        #expect((Box<@Sendable (Int) -> Int>(double) <*> Box(3)) == Box.apply(Box(double), Box(3)))
        #expect((Box(1) *> Box(2)) == Box(2))
        #expect((Box(1) <* Box(2)) == Box(1))
    }

    @Test func monadOperators() {
        #expect((Box(8) >>- half) == Box(8).flatMap(half))
        #expect((half -<< Box(8)) == Box(8).flatMap(half))
        #expect((half >=> half)(8) == Box.kleisli(half, half)(8))
        #expect((half <=< half)(8) == Box.kleisli(half, half)(8))
    }
}
```

## Extra surfaces

Same two-layer pattern for each, only when lawful:

- `Semigroup` / `Monoid`: conform (the protocols refine `Sendable`), `combine` and `identity`; `<>` already works through the generic overload.
- Alternative: static `alt(_:_:)` with an `@autoclosure` right side, then `<|>` delegating to it.
- Comonad: `extract`, `extend` / `duplicate`, with `->>` / `<<-`.
- Foldable / traversable: concrete `fold`, `traverse` per applicative (`traverse` into `Optional`, `Result`, `Validation`), since there's no generic `Traversable`.
- A new sum type conforms to `SumType2` instead of re-implementing `match` / `a` / `b` / `isA` / `isB`.
