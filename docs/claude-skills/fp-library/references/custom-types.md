# Making your own type work with the operators

Swift has no higher-kinded types, so there's no `Functor` or `Monad` protocol to conform to. Every type in the library gets its own concrete `map` / `flatMap` / `pure` / `apply` and its own operator overloads, and your type does the same. Following the library's naming makes your type feel native next to `Optional`, `Reader` and friends.

Before writing one, check that the library doesn't already have it: accumulating errors is `Validation`, async UI state is `Loading`, dependency injection is `Reader`, state threading is `Stateful`, logging is `Writer`, a non-empty list is `NonEmpty`.

## Contents

- The shape to follow
- Example: a tiny parser
- Operators
- Checking the laws

## The shape to follow

| Role | Instance | Static, curried |
|---|---|---|
| Functor | `map(_:)` | `fmap(_:) -> @Sendable (Self<A>) -> Self<B>` |
| Applicative | | `pure(_:)`, `apply(_:_:)`, `liftA2(_:)` |
| Monad | `flatMap(_:)` | `bind(_:)`, `kleisli(_:_:)` |

Rules the library follows, and that keep your operators unambiguous:

- Closures are `@escaping @Sendable`, the type is `Sendable` (conditionally when generic).
- `apply` takes the wrapped function as `Self<@Sendable (A) -> B>`.
- The operators only call the named functions. All logic lives in the named ones.
- Every directional operator gets its flipped partner (`<£>` with `<&>`, `>>-` with `-<<`, `>=>` with `<=<`), delegating with the arguments swapped.
- Only implement what's lawful. If `flatMap` can't satisfy the monad laws for your type, stop at applicative (that's what `Validation` does).

## Example: a tiny parser

```swift
import FP

struct Parser<A>: Sendable {
    let run: @Sendable (Substring) -> (A, Substring)?
}

extension Parser {
    func map<B>(_ transform: @escaping @Sendable (A) -> B) -> Parser<B> {
        Parser<B> { input in run(input).map { value, rest in (transform(value), rest) } }
    }

    static func fmap<B>(_ transform: @escaping @Sendable (A) -> B) -> @Sendable (Parser<A>) -> Parser<B> {
        { $0.map(transform) }
    }

    func flatMap<B>(_ transform: @escaping @Sendable (A) -> Parser<B>) -> Parser<B> {
        Parser<B> { input in run(input).flatMap { value, rest in transform(value).run(rest) } }
    }

    static func bind<B>(_ transform: @escaping @Sendable (A) -> Parser<B>) -> @Sendable (Parser<A>) -> Parser<B> {
        { $0.flatMap(transform) }
    }

    static func kleisli<B, C>(
        _ first: @escaping @Sendable (A) -> Parser<B>,
        _ second: @escaping @Sendable (B) -> Parser<C>
    ) -> @Sendable (A) -> Parser<C> {
        { first($0).flatMap(second) }
    }
}

extension Parser where A: Sendable {
    static func pure(_ value: A) -> Parser<A> {
        Parser { input in (value, input) }
    }

    static func apply<Input>(_ function: Parser<@Sendable (Input) -> A>, _ value: Parser<Input>) -> Parser<A> {
        function.flatMap { fn in value.map(fn) }
    }

    static func liftA2<A1: Sendable, A2>(_ fn: @escaping @Sendable (A1, A2) -> A) -> @Sendable (Parser<A1>, Parser<A2>) -> Parser<A> {
        { first, second in first.flatMap { a1 in second.map { a2 in fn(a1, a2) } } }
    }
}

let digit = Parser<Int> { input in
    input.first.flatMap { $0.wholeNumberValue }.map { ($0, input.dropFirst()) }
}
```

## Operators

The operator declarations (precedence and associativity) come from the library; you only add overloads for your type, each delegating to a named function:

```swift
func <£> <A, B>(_ transform: @escaping @Sendable (A) -> B, _ parser: Parser<A>) -> Parser<B> {
    Parser.fmap(transform)(parser)
}

func <&> <A, B>(_ parser: Parser<A>, _ transform: @escaping @Sendable (A) -> B) -> Parser<B> {
    transform <£> parser
}

func <*> <A, B: Sendable>(_ function: Parser<@Sendable (A) -> B>, _ value: Parser<A>) -> Parser<B> {
    Parser.apply(function, value)
}

func >>- <A, B>(_ parser: Parser<A>, _ transform: @escaping @Sendable (A) -> Parser<B>) -> Parser<B> {
    parser.flatMap(transform)
}

func -<< <A, B>(_ transform: @escaping @Sendable (A) -> Parser<B>, _ parser: Parser<A>) -> Parser<B> {
    parser >>- transform
}

func >=> <A, B, C>(
    _ first: @escaping @Sendable (A) -> Parser<B>,
    _ second: @escaping @Sendable (B) -> Parser<C>
) -> @Sendable (A) -> Parser<C> {
    Parser.kleisli(first, second)
}

func <=< <A, B, C>(
    _ second: @escaping @Sendable (B) -> Parser<C>,
    _ first: @escaping @Sendable (A) -> Parser<B>
) -> @Sendable (A) -> Parser<C> {
    first >=> second
}

let twoDigits: Parser<Int> = Parser<Int>.liftA2 { tens, units in tens * 10 + units }(digit, digit)
let doubledDigit: Parser<Int> = { $0 * 2 } <£> digit
let digitThenSame: Parser<Int> = digit >>- { first in digit.flatMap { $0 == first ? .pure($0) : Parser { _ in nil } } }
```

Add `£>` / `<£`, `*>` / `<*` and `<|>` the same way if your type has them (`<|>` needs a notion of failure and choice, which a parser does have).

## Checking the laws

Write the laws as tests (Swift Testing), comparing by running the values when the type wraps a function:

```swift
import Testing

func parsed<A>(_ parser: Parser<A>, _ input: String) -> A? { parser.run(Substring(input))?.0 }

@Test func functorIdentity() {
    #expect(parsed(digit.map { $0 }, "7") == parsed(digit, "7"))
}

@Test func monadLeftIdentity() {
    let next: @Sendable (Int) -> Parser<Int> = { value in digit.map { value + $0 } }
    #expect(parsed(Parser.pure(1).flatMap(next), "2") == parsed(next(1), "2"))
}

@Test func monadAssociativity() {
    let plusDigit: @Sendable (Int) -> Parser<Int> = { value in digit.map { value + $0 } }
    let lhs = digit.flatMap(plusDigit).flatMap(plusDigit)
    let rhs = digit.flatMap { plusDigit($0).flatMap(plusDigit) }
    #expect(parsed(lhs, "123") == parsed(rhs, "123"))
}
```

Functor: identity and composition. Applicative: identity, composition, homomorphism, interchange. Monad: left identity, right identity, associativity. A law that fails means the instance is wrong, not that the test is too strict.
