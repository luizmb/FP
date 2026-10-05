# Operators: vocabulary, precedence, reading a chain

The DocC article `OperatorVocabulary` (`Sources/FP/FP.docc/Articles/OperatorVocabulary.md`) is the full catalogue. This file is the working subset, what actually parses when operators are mixed in your code, and a method for explaining and debugging a composition.

## Contents

- Vocabulary
- Precedence: what mixes without parentheses
- Explaining a chain, step by step
- Worked examples
- Common errors and fixes

## Vocabulary

| Operator | Haskell | Meaning | Precedence group | Assoc |
|---|---|---|---|---|
| `<£>` | `<$>` | functor map, function left | `FunctorOps` | left |
| `£>` / `<£` | `$>` / `<$` | replace the value with a constant, container left / value left | `FunctorOps` | left |
| `<*>` | `<*>` | applicative apply | `FunctorOps` | left |
| `*>` / `<*` | `*>` / `<*` | sequence, keep right / keep left | `FunctorOps` | left |
| `<&>` | `<&>` | functor map, container left | `MonadBindLeft` | left |
| `>>-` | `>>=` | bind, container left | `MonadBindLeft` | left |
| `->>` | `=>>` | comonad extend, container left | `MonadBindLeft` | left |
| `-<<` | `=<<` | bind, function left | `KleisliCompositionRight` | right |
| `>=>` / `<=<` | `>=>` / `<=<` | Kleisli composition | `KleisliCompositionRight` | right |
| `<<-` | flip of `=>>` | comonad extend, function left | `KleisliCompositionRight` | right |
| `<>` | `<>` | semigroup append | `ConcatPrecedence` | right |
| `<\|>` | `<\|>` | alternative, first success | `AlternativePrecedence` | left |
| `>>>` / `<<<` | `>>>` / `<<<` | function and optic composition | `FunctionComposition…` | right |
| `<\|` | `$` | application, function left | `LowPrecedenceFunctionCallRight` | right |
| `\|>` | (F# pipe) | application, value left | `LowPrecedenceFunctionCallLeft` | left |
| `^` prefix | | key path to `Lens`, or a `@Sendable` getter | | |
| `≅` | | flipped `~=` (`value ≅ range`) | `ComparisonPrecedence` | none |
| `±`, `+/-` | | `center ± delta` builds a `ClosedRange` | `RangeFormationPrecedence` | none |

`£` is a pound sign, standing in for Haskell's `$` (Swift reserves `$`). Not in the library: `•`, infix `^` power (use `power(_:_:)`), `++` (use `<>`), a bare `£` (use `<|`), `<£^>` / `<&^>` (use a transformer stack).

## Precedence: what mixes without parentheses

The library's groups form one total order that follows Haskell's fixities, highest to lowest: composition (`>>>`, then `<<<`), `<>`, the functor family (`<£>`, `<*>`, `£>`, `<£`, `*>`, `<*`), `<|>`, Kleisli (`>=>`, `<=<`, `-<<`), bind (`>>-`, `<&>`, `->>`), `<|`, and finally `|>`. Any two of them mix without parentheses and group by that order, so `f <£> xs >>- g` is `(f <£> xs) >>- g` and `x |> f >>> g` is `x |> (f >>> g)`. The same order is in the DocC article and the README table.

The rows below are all the same rule, with the Swift stdlib operators slotted in:

| Combination | Groups as |
|---|---|
| `>>>` / `<<<` with anything else | composition binds tightest (`>>>` is above `<<<`) |
| `<>` with the functor family, `<\|>`, Kleisli, bind, application | `<>` binds tighter |
| `<£>`, `<*>`, `£>`, `<£`, `*>`, `<*` with each other | left to right (`f <£> a <*> b` is `(f <£> a) <*> b`) |
| the functor family with `<\|>`, Kleisli, bind, application, `&&`, `\|\|` | the functor family binds tighter |
| the functor family with `*`, `+`, `??` | the stdlib operator binds tighter: `f <£> x ?? y` is `f <£> (x ?? y)` |
| `<\|>` with Kleisli, bind, application | `<\|>` binds tighter |
| `<\|>`, Kleisli, bind, `<\|`, `\|>` with `*`, `+`, `??`, `==`, `&&`, `\|\|` | the stdlib operator binds tighter: `a <\|> b ?? c` is `a <\|> (b ?? c)`, `x == y \|> f` is `(x == y) \|> f` |
| `>=>`, `<=<`, `-<<` with `>>-`, `<&>` | Kleisli binds tighter: `m >>- f >=> g` is `m >>- (f >=> g)` |
| `>>-`, `<&>`, `->>` with each other | left to right |
| `<\|` with `\|>` | `<\|` binds tighter, and both sit below every other library operator |

The only mix that still needs parentheses is the functor family (`<£>`, `<*>`, `£>`, `<£`, `*>`, `<*`) with `==`: Haskell puts them at the same level and rejects it, so Swift does too.

If you hit "adjacent operators are in unordered precedence groups", that's the cause. It never silently groups the wrong way, it just refuses. When a chain gets parenthesized everywhere, that's usually the hint to switch to the named form (`x.map(f).flatMap(g)`) or to give the intermediate step a name.

Associativity, where it applies, follows Haskell: `>>-` is left associative (`m >>- f >>- g` runs `m`, then `f`, then `g`), `>=>` is right associative (`f >=> g >=> h` is one function you call later), `<>` and composition are right associative.

## Explaining a chain, step by step

When asked what a composition does or why it doesn't compile:

1. Write the type of every leaf (each value and each function).
2. Group by the rules above and write the fully parenthesized form. If two adjacent operators are in unordered groups (the functor family against `==`, see the list above), that's the bug: say so and add the parentheses.
3. Evaluate the innermost group first, writing the resulting type after each step.
4. If it still fails, find the first step where the types disagree. That's nearly always the container on the wrong side of `<£>`, a nested value treated as if it were a stack (or the other way around), or a closure that isn't `@Sendable`.
5. Offer the fix, and when it helps, the named-function form as a readability check.

## Worked examples

### Map, then bind

```swift
import FP

let numbers = [1, 2, 3]
let double: @Sendable (Int) -> Int = 2 |> curry(*)
let neighbours: @Sendable (Int) -> [Int] = { [$0, $0 + 1] }

// `<£>` binds tighter than `>>-`, so no parentheses are needed
// [1, 2, 3]  -> double <£>      -> [2, 4, 6]
//            -> >>- neighbours  -> [2, 3, 4, 5, 6, 7]
let expanded = double <£> numbers >>- neighbours
let expandedNamed = numbers.map(double).flatMap(neighbours)

// `<&>` and `>>-` share a group, so a container-first pipeline reads left to right
let expandedPipeline = numbers <&> double >>- neighbours
```

### Bind sequences values, Kleisli builds functions

```swift
let parse: @Sendable (String) -> Int? = { Int($0) }
let nonZero: @Sendable (Int) -> Int? = { $0 == 0 ? nil : $0 }
let reciprocal: @Sendable (Int) -> Double? = { 1 / Double($0) }

// a value flowing through: (parse("4") >>- nonZero) >>- reciprocal
let quarter = parse("4") >>- nonZero >>- reciprocal  // Optional(0.25)

// a function built once, called later: parse >=> (nonZero >=> reciprocal)
let safeReciprocal = parse >=> nonZero >=> reciprocal
let none = safeReciprocal("0")  // nil

// >=> binds tighter than >>-, so this is Optional(4) >>- (nonZero >=> reciprocal)
let alsoQuarter = Optional(4) >>- nonZero >=> reciprocal
```

### Composition and application

```swift
let increment: @Sendable (Int) -> Int = 1 |> curry(+)
let double: @Sendable (Int) -> Int = 2 |> curry(*)
let describe: @Sendable (Int) -> String = { "value: \($0)" }

// `>>>` binds tighter than `|>`, so the composition happens first
let described = 5 |> increment >>> double >>> describe  // "value: 12"
let pipelined = 5 |> increment |> double |> describe  // same, one step at a time
let applied = describe <| double <| increment <| 5  // <| is right associative
```

### Applicative: combining independent values

```swift
struct Point: Sendable { let x: Int; let y: Int }

let parse: @Sendable (String) -> Int? = { Int($0) }
let makePoint: @Sendable (Int) -> @Sendable (Int) -> Point = { x in { y in Point(x: x, y: y) } }

// (makePoint <£> parse("1")) <*> parse("2"): same group, left associative
let point = makePoint <£> parse("1") <*> parse("2")  // Optional(Point(x: 1, y: 2))
let samePoint = Optional<Point>.liftA2(Point.init)(parse("1"), parse("2"))

// the functor family binds tighter than <|>
let pointOrOrigin = makePoint <£> parse("x") <*> parse("2") <|> Optional(Point(x: 0, y: 0))
```

The function inside `<*>` has to be `@Sendable` (`Optional<@Sendable (Int) -> Point>`), which is why `makePoint` returns a `@Sendable` closure.

### A nested value is not a stack

```swift
struct Config: Sendable { let users: [String: String] }

let lookup: @Sendable (String) -> Reader<Config, String?> = { id in Reader { $0.users[id] } }

// <£> on the bare Reader maps the whole `String?`, so this needs `Optional.map` inside
let shoutedNested = { (name: String?) in name.map { $0.uppercased() } } <£> lookup("1")

// wrapped in its stack, <£> reaches the String directly
let shouted: Reader<Config, String?> = ({ $0.uppercased() } <£> lookup("1").readerT).rawValue
```

## Common errors and fixes

"adjacent operators are in unordered precedence groups": almost always a functor-family operator next to `==`, which is unordered on purpose (see the list above), so add parentheses around the part that should run first.

```swift-sketch
let broken = numbers.first ?? 0 |> double
let fixed = (numbers.first ?? 0) |> double
```

Container on the wrong side of `<£>` (doesn't compile):

```swift-sketch
let wrong = Optional(3) <£> { $0 * 2 }
```

```swift
let right = { $0 * 2 } <£> Optional(3)
let alsoRight = Optional(3) <&> { $0 * 2 }
```

A bare key path where a `@Sendable` function is expected ("converting non-Sendable function value…"):

```swift-sketch
let names = \String.count <£> ["a", "bb"]
```

```swift
let lengths = get(\String.count) <£> ["a", "bb"]
let sameLengths = ^\String.count <£> ["a", "bb"]
```

A non-`@Sendable` closure stored in a `let` and then passed to an operator: give the `let` a `@Sendable` function type, as every example above does.

`??` inside a functor chain: `f <£> x ?? fallback` applies `f` to `x ?? fallback`. Write `(f <£> x) ?? fallback` to default the result instead.
