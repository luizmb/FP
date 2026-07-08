# Operator Vocabulary

Every operator in `CoreFPOperators` and `DataStructureOperators` delegates to a named function
in `CoreFP` or `DataStructure` — the operator is sugar, never logic. This article catalogs the
full symbol set, the precedence hierarchy that makes them compose without parentheses, and a
short guide to picking the right one.

```swift
import FP

let parsed = "42"
    |> Int.init        // Optional<Int>
    <£> { $0 * 2 }      // functor map → Optional<Int>
    ?? 0                // 84
```

---

## The operator reference

| Operator | Haskell | Meaning | Precedence group | Associativity |
|---|---|---|---|---|
| `<£>` | `<$>` | Functor map, function on the left | `FunctorOps` | left |
| `<&>` | `<&>` | Functor map, container on the left | `MonadBindLeft` | left |
| `£>` | `$>` | Replace every element with a constant, container left | `FunctorOps` | left |
| `<£` | `<$` | Replace every element with a constant, value left | `FunctorOps` | left |
| `<£^>` | — | Transformer-only `fmap` (`mapT`), function left | `FunctorOps` | left |
| `<&^>` | — | Transformer-only `fmap` (`mapT`), container left | `MonadBindLeft` | left |
| `<*>` | `<*>` | Applicative apply | `FunctorOps` | left |
| `*>` | `*>` | Sequence, discard the left result | `FunctorOps` | left |
| `<*` | `<*` | Sequence, discard the right result | `FunctorOps` | left |
| `>>-` | `>>=` | Monadic bind, container left, function right | `MonadBindLeft` | left |
| `-<<` | `=<<` | Monadic bind, function left, container right | `KleisliCompositionRight` | right |
| `>=>` | `>=>` | Kleisli composition, left to right | `KleisliCompositionRight` | right |
| `<=<` | `<=<` | Kleisli composition, right to left | `KleisliCompositionRight` | right |
| `->>` | `=>>` | Comonad extend/`coflatMap`, container left | `MonadBindLeft` | left |
| `<<-` | flip of `=>>` | Comonad extend/`coflatMap`, function left | `KleisliCompositionRight` | right |
| `<>` | `<>` | Semigroup/Monoid append | `ConcatPrecedence` | right |
| `<\|>` | `<\|>` | Alternative / first-success fallback | `AlternativePrecedence` | left |
| `++` | `++` | List/sequence concatenation | `AppendToList` | right |
| `>>>` | `>>>` (`Control.Category`) | Function/optic composition, left to right | `FunctionCompositionForward` | right |
| `<<<` | `<<<` (`Control.Category`) | Function/optic composition, right to left | `FunctionCompositionBackwards` | right |
| `£` / `<\|` | `$` | Function application, function on the left | `LowPrecedenceFunctionCallRight` | right |
| `\|>` | — (F#/Elixir pipeline) | Function application, value on the left (pipeline) | `LowPrecedenceFunctionCallLeft` | left |
| `^` (infix) | `^` | Numeric power, `BinaryFloatingPoint` only | `AdditionPrecedence` (stdlib — shared with `+`/`-`/`\|`/bitwise XOR) | left |
| `^` (prefix) | — | Lift a `KeyPath`/`WritableKeyPath` into a `Lens` (or a `@Sendable` getter) | n/a (prefix) | n/a |
| `≅` | — | Flipped pattern match / range membership (`value ≅ range`) | `ComparisonPrecedence` (stdlib) | none (non-associative) |
| `±` / `+/-` | — | Symmetric range construction, `center ± delta` | `RangeFormationPrecedence` (stdlib) | none (non-associative) |

A few things worth calling out explicitly:

- **`£` is a pound sign, not a typo for `$`.** Haskell's `$` can't be reused because `$` is
  reserved for Swift string interpolation delimiters, so the library uses `£` (and offers the
  ASCII-friendly `<|` as an alias for the exact same operator).
- **`<£^>`/`<&^>` have no base-type overload, on purpose.** They exist solely for transformer
  (`mapT`) calls — `Writer<W, Either<L, A>>`, `Either<L, Result<A, E>>`, and so on. `<£>`/`<&>`
  already carry a large number of overloads across every base `Functor` in the library (`Array`,
  `Optional`, `Result`, `Either`, `Reader`, …). The `<£^>` doc comment in `Operators.swift` states
  the reason directly: unlike `<£>`, it has no base-type overload at all — only transformer-specific
  ones — "so Swift can always resolve the correct overload with zero ambiguity." Piling every
  transformer combination onto the same `<£>` symbol as the base overloads has, in practice, also
  tripped up SourceKit (the editor's live type checker) with false-positive errors on code that
  `swift build`/`swift test` compile and pass without issue — giving transformer `fmap` its own
  symbol sidesteps that too.
- **`^` the infix operator only works on `BinaryFloatingPoint`.** Swift's standard library already
  declares `^` as bitwise XOR on `BinaryInteger` types; declaring a second `^` with a different
  precedence group for the same operator name is an "ambiguous operator declarations" compiler
  error, so this library cannot give integers a power operator. Use the named function
  `power(_:_:)` for integer exponentiation; `^` the operator is reserved for `Double`/`Float`/etc.,
  which have no conflicting stdlib meaning.
- **`≅` and `±`/`+/-` are not in Haskell.** `≅` is a flipped alias of Swift's pattern-matching
  `~=` (`value ≅ range` reads better than `range ~= value` at a call site); `±`/`+/-` build a
  `ClosedRange` from a center and a delta (`5.0 ± 0.5` → `4.5...5.5`), generalized over
  `Strideable` so it also works for `Date`.
- **`•` does not exist.** Some of this library's older internal notes list a third composition
  spelling, `•` (meant to mirror Haskell's `.`), alongside `>>>`/`<<<`. It was never implemented —
  there is no `infix operator •` anywhere in `CoreFPOperators`. Function composition in this
  library is `>>>`/`<<<` only.

---

## The precedence hierarchy

Highest to lowest, with Swift standard-library groups included for context (their operators are
fixed and cannot be changed; the custom groups slot around them):

```
9     FunctionCompositionForward      >>>                     right
9     FunctionCompositionBackwards    <<<                     right
8.5   BitwiseShiftPrecedence          (stdlib: >>, <<)
7     MultiplicationPrecedence        (stdlib: *, /, %)
6     ConcatPrecedence                <>                      right
6     AdditionPrecedence              (stdlib: +, -, |)  ^ (infix, floating-point only)   left
5     AppendToList                    ++                      right
4.8   RangeFormationPrecedence        (stdlib: ..., ..<)  ±  +/-
4.5   CastingPrecedence               (stdlib: as?)
4.2   NilCoalescingPrecedence         (stdlib: ??)
4     ComparisonPrecedence            (stdlib: ==, <=)  ≅
4     FunctorOps                      <£>  £>  <£  <*>  *>  <*  <£^>       left
3     AlternativePrecedence           <|>                                  left
3     LogicalConjunctionPrecedence    (stdlib: &&)
2     LogicalDisjunctionPrecedence    (stdlib: ||)
1     KleisliCompositionRight         >=>  <=<  -<<  <<-                   right
1     MonadBindLeft                   >>-  <&>  ->>  <&^>                  left
0.5   TernaryPrecedence               (stdlib: ?:)
0     LowPrecedenceFunctionCallRight  £  <|                                right
0     LowPrecedenceFunctionCallLeft   |>                                   left
-1    AssignmentPrecedence            (stdlib: =)
```

`FunctorOps` and `ComparisonPrecedence` sit at the same numeric level (4) because `FunctorOps` is
declared `lowerThan: NilCoalescingPrecedence, higherThan: AlternativePrecedence` — the same slot
Swift's own comparison operators occupy — rather than being ordered directly against them.

### Why the associativity choices matter

Two decisions are deliberately matched to Haskell rather than to "whatever Swift defaults to":

**`>=>` is right-associative, like Haskell's `infixr 1 >=>`.** Kleisli composition builds a
pipeline of functions, and right-associativity means `f >=> g >=> h` groups as
`f >=> (g >=> h)` — each stage is composed once, lazily, and the whole chain behaves as a single
function you can pass around or call later, exactly like nested `.` composition in Haskell's
`Control.Category`.

**`>>-` is left-associative, like Haskell's `infixl 1 >>=`.** Bind sequences *effects*, not
functions: `m >>- f >>- g` groups as `(m >>- f) >>- g` — run `m`, feed its result to `f`, then
feed *that* result to `g`. Left-associativity matches the imperative reading "do this, then this,
then this," which is exactly how `do`-notation desugars in Haskell.

Because `>>-` (bind) and `>=>`/`-<<` (Kleisli composition / flipped bind) need *opposite*
associativity to match their Haskell counterparts, they cannot share one precedence group — hence
the split into `MonadBindLeft` (left, for `>>-`/`<&>`/`->>`/`<&^>`) and `KleisliCompositionRight`
(right, for `>=>`/`<=<`/`-<<`/`<<-`), at adjacent precedence levels so they still interleave
correctly in mixed expressions.

`<&>` also sits in `MonadBindLeft` rather than alongside `<£>` in `FunctorOps` — matching
Haskell's own `infixl 1 <&>`, which is lower precedence than `infixl 4 <$>` (`<£>`'s Haskell
counterpart, `Data.Functor`'s `<$>`) despite both being "functor map." `<&^>`, the transformer
counterpart of `<&>`, follows it into the same group for the same reason.

---

## Which operator do I need?

- **Transform a value inside a container, function first** → `<£>` (`<&>` if the container reads
  more naturally first, e.g. mid-pipeline).
- **Transform the value one layer inside a transformer stack** (`Writer<W, Either<L, A>>`,
  `Either<L, Result<A, E>>`, …) → `<£^>` / `<&^>`.
- **Combine two independent wrapped values with a function that takes both** → `<*>`, or
  `liftA2`-style named functions for a curried n-ary version.
- **Run two effects in sequence but only care about one result** → `*>` (keep the right) / `<*`
  (keep the left). Both effects still run; only the *value* is discarded.
- **Chain a computation whose next step depends on the previous result** → `>>-` (or `-<<` if the
  function reads better first).
- **Compose two functions that each return a wrapped value, before calling either** → `>=>` (or
  `<=<` for right-to-left reading). Use this over manual `>>-` chaining when you're building a
  reusable pipeline rather than running one immediately.
- **Fall back to an alternative if the first effect "fails"** → `<|>`.
- **Concatenate two monoidal values** (arrays, strings, logs, `Endo` chains, …) → `<>`
  (`++` specifically for sequence/list concatenation).
- **Chain plain functions, or compose optics (`Lens`/`Prism`/`AffineTraversal`/`Iso`)** → `>>>` /
  `<<<`.
- **Apply a function to a value with minimal parentheses** → `£` / `<|` (function first) or `|>`
  (value first, pipeline style).
- **Extend a comonadic computation over its whole context** (`Writer`, `Reader` with a `Monoid`
  environment) → `->>` / `<<-`.
- **Check membership without writing `range ~= value` backwards, or build a tolerance range** →
  `≅` / `±` (`+/-`).

---

## For Haskell developers

Because this whole article *is* the Haskell mapping (the table above gives the `Data.Functor` /
`Control.Applicative` / `Control.Monad` / `Control.Category` equivalent for nearly every symbol),
the more useful note here is where behavior **diverges** from Haskell rather than where it lines
up.

**`&&` and `||` are left-associative here, where Haskell's are right-associative.** Haskell
declares `infixr 3 &&` and `infixr 2 ||`; Swift's standard library declares
`LogicalConjunctionPrecedence`/`LogicalDisjunctionPrecedence` as left-associative, and this is a
Swift standard-library default this codebase cannot override (redeclaring `&&`/`||` would
conflict with the existing stdlib declarations, the same conflict that blocks a custom
integer-`^`). In practice the impact is minimal: `&&` and `||` are each associative operations in
the boolean case (`(a && b) && c` and `a && (b && c)` always agree), so the difference in grouping
never changes the result — it only matters if you were relying on short-circuit *evaluation
order* in a context with side effects, which this library's purity rules discourage in the first
place.

**`^` is narrower here than Haskell's `^`.** Haskell's `(^) :: (Num a, Integral b) => a -> b -> a`
works for any numeric base with an integral exponent, including `Int`. Here, `^` only exists for
`BinaryFloatingPoint` bases, because Swift's stdlib already owns `^` as bitwise XOR on
`BinaryInteger` types and a second declaration would be ambiguous — so `2 ^ 10` (integers) isn't
available as an operator at all; reach for `power(_:_:)` there.

For the canonical fixity reference this library's precedence groups were checked against, see:
- [The Haskell 2010 Report §4.4.2 (fixity declarations)](https://www.haskell.org/onlinereport/haskell2010/haskellch4.html#x10-820061) — the standard's table of `infixl`/`infixr`/`infix` declarations for every base operator this library mirrors.
- [`Data.Functor` on Hackage](https://hackage.haskell.org/package/base/docs/Data-Functor.html) — `<$>`, `<&>`, `$>`, `<$`.
- [`Control.Monad` on Hackage](https://hackage.haskell.org/package/base/docs/Control-Monad.html) — `>>=`, `=<<`, `>=>`, `<=<`.

---

## Module

```swift
import CoreFPOperators         // Operators for CoreFP types (Array, Optional, Result, functions, …)
import DataStructureOperators  // Operators for DataStructure types (Either, Validation, Reader, Writer, Stateful, …)
```
