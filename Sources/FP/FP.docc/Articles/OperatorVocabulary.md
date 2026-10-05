# Operator Vocabulary

Every operator in `CoreFPOperators` and `DataStructureOperators` delegates to a named function
in `CoreFP` or `DataStructure` — the operator is sugar, never logic. This article catalogs the
full symbol set, the precedence hierarchy that makes them compose without parentheses, and a
short guide to picking the right one.

```swift
import FP

let parsed = ({ $0 * 2 } <£> Int("42")) ?? 0   // 84
```

The parentheses matter: `??` binds tighter than `<£>`, so without them `{ $0 * 2 } <£> Int("42") ?? 0`
would parse as `{ $0 * 2 } <£> (Int("42") ?? 0)`.

---

## The operator reference

| Operator | Haskell | Meaning | Precedence group | Associativity |
|---|---|---|---|---|
| `<£>` | `<$>` | Functor map, function on the left | `FunctorOps` | left |
| `<&>` | `<&>` | Functor map, container on the left | `MonadBindLeft` | left |
| `£>` | `$>` | Replace every element with a constant, container left | `FunctorOps` | left |
| `<£` | `<$` | Replace every element with a constant, value left | `FunctorOps` | left |
| `<*>` | `<*>` | Applicative apply | `FunctorOps` | left |
| `*>` | `*>` | Sequence, discard the left result | `FunctorOps` | left |
| `<*` | `<*` | Sequence, discard the right result | `FunctorOps` | left |
| `>>-` | `>>=` | Monadic bind, container left, function right | `MonadBindLeft` | left |
| `-<<` | `=<<` | Monadic bind, function left, container right | `KleisliCompositionRight` | right |
| `>=>` | `>=>` | Kleisli composition, left to right | `KleisliCompositionRight` | right |
| `<=<` | `<=<` | Kleisli composition, right to left | `KleisliCompositionRight` | right |
| `->>` | `=>>` | Comonad extend/`coflatMap`, container left | `MonadBindLeft` | left |
| `<<-` | `<<=` | Comonad extend/`coflatMap`, function left | `KleisliCompositionRight` | right |
| `<>` | `<>` | Semigroup/Monoid append | `ConcatPrecedence` | right |
| `<\|>` | `<\|>` | Alternative / first-success fallback | `AlternativePrecedence` | left |
| `>>>` | `>>>` (`Control.Category`) | Function/optic composition, left to right | `FunctionCompositionForward` | right |
| `<<<` | `<<<` (`Control.Category`) | Function/optic composition, right to left | `FunctionCompositionBackwards` | right |
| `<\|` | `$` | Function application, function on the left | `LowPrecedenceFunctionCallRight` | right |
| `\|>` | — (F#/Elixir pipeline) | Function application, value on the left (pipeline) | `LowPrecedenceFunctionCallLeft` | left |
| `^` (prefix) | — | Lift a `KeyPath`/`WritableKeyPath` into a `Lens` (or a `@Sendable` getter) | n/a (prefix) | n/a |
| `≅` | — | Range membership (`value ≅ range`, the five range types, `T: Comparable`) | `ComparisonPrecedence` (stdlib) | none (non-associative) |
| `±` / `+/-` | — | Symmetric range construction, `center ± delta` | `RangeFormationPrecedence` (stdlib) | none (non-associative) |

A few things worth calling out explicitly:

- **`£` is a pound sign, not a typo for `$`.** Haskell's `$` can't be reused because `$` is
  reserved for Swift string interpolation delimiters, so `<$>`/`$>`/`<$` become `<£>`/`£>`/`<£`.
  Plain `$` (function application) is spelled `<|`; there is no standalone `£` operator.
- **Transformer stacks use the same operators.** A stack is its own struct (`ReaderTArray`,
  `WriterTEither`, …), so `<£>`, `£>`, `<*>`, `>>-`, `>=>` on it act on the innermost value. On a
  bare nested value (`Reader<Env, [A]>`) they are the outer type's operators, so `reader £> x`
  replaces the whole output; wrap it first (`reader.readerT £> x`) to replace each element.
- **There is no infix power operator.** Swift's standard library declares `^` (bitwise XOR) in
  `AdditionPrecedence`, and a second declaration with another precedence group is an
  "ambiguous operator declarations" error, so a power `^` would bind like `+`
  (`2.0 * 3.0 ^ 2 == 36`). Use the named function `power(_:_:)` for every numeric type.
- **`≅` and `±`/`+/-` are not in Haskell.** `≅` is range membership, `value ≅ range`, with
  overloads for `ClosedRange`, `Range`, `PartialRangeFrom`, `PartialRangeThrough` and
  `PartialRangeUpTo` (it is not a general alias of `~=`); `±`/`+/-` build a
  `ClosedRange` from a center and a delta (`5.0 ± 0.5` → `4.5...5.5`), generalized over
  `Strideable` so it also works for `Date`.
- **`•` does not exist.** Some of this library's older internal notes list a third composition
  spelling, `•` (meant to mirror Haskell's `.`), alongside `>>>`/`<<<`. It was never implemented —
  there is no `infix operator •` anywhere in `CoreFPOperators`. Function composition in this
  library is `>>>`/`<<<` only.

### Removed in 3.0

Some operators from 2.x are gone, each with a plain replacement:

| Removed | Use instead |
|---|---|
| `a ++ b` | `a <> b` |
| `f £ x` (infix) | `f <\| x` |
| `x ^ n` (infix power) | `power(x, n)` |
| `f <£^> x`, `x <&^> f` | `f <£> x.readerT` (wrap the value in its stack, then use `<£>`) |
| transformer `£>` / `<£` on a bare nested value | `stack £> v` on the stack struct |

---

## The precedence hierarchy

Highest to lowest, with Swift standard-library groups included for context (their operators are
fixed and cannot be changed; the custom groups slot around them):

```
9.5   FunctionCompositionForward      >>>                     right
9     FunctionCompositionBackwards    <<<                     right
8.5   BitwiseShiftPrecedence          (stdlib: >>, <<)
7     MultiplicationPrecedence        (stdlib: *, /, %)
6.5   ConcatPrecedence                <>                      right
6     AdditionPrecedence              (stdlib: +, -, |, ^)                 left
4.8   RangeFormationPrecedence        (stdlib: ..., ..<)  ±  +/-
4.5   CastingPrecedence               (stdlib: as?)
4.2   NilCoalescingPrecedence         (stdlib: ??)
4     ComparisonPrecedence            (stdlib: ==, <=)  ≅
4     FunctorOps                      <£>  £>  <£  <*>  *>  <*             left
3     AlternativePrecedence           <|>                                  left
3     LogicalConjunctionPrecedence    (stdlib: &&)
2     LogicalDisjunctionPrecedence    (stdlib: ||)
1.5   KleisliCompositionRight         >=>  <=<  -<<  <<-                   right
1     MonadBindLeft                   >>-  <&>  ->>                        left
0.5   TernaryPrecedence               (stdlib: ?:)
0     LowPrecedenceFunctionCallRight  <|                                   right
0     LowPrecedenceFunctionCallLeft   |>                                   left
-1    AssignmentPrecedence            (stdlib: =)
```

The numbers are only a reading aid, the real ordering is the `higherThan`/`lowerThan` chain in
`PrecedenceGroups.swift`. Note that `>>>` is higher than `<<<`, so mixing them without parentheses
compiles and groups `>>>` first (`f >>> g <<< h` is `(f >>> g) <<< h`); parenthesise anyway.
`<>` binds tighter than `+`, and `>=>`/`<=<`/`-<<` bind tighter than `>>-`/`<&>`.

The library's own groups are chained into one total order (each custom group is declared `higherThan` the
next one in this module, because Swift won't order two groups through another module's), so any two
library operators mix without parentheses: `f <£> xs >>- g` is `(f <£> xs) >>- g` and `x |> f >>> g` is
`x |> (f >>> g)`. What stays unordered is a library operator against some stdlib ones, such as `|>`,
`>>-` or `<|>` next to `==`, `+` or `??`; those need parentheses.

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
the split into `MonadBindLeft` (left, for `>>-`/`<&>`/`->>`) and `KleisliCompositionRight`
(right, for `>=>`/`<=<`/`-<<`/`<<-`), at adjacent precedence levels so they still interleave
correctly in mixed expressions.

`<&>` also sits in `MonadBindLeft` rather than alongside `<£>` in `FunctorOps` — matching
Haskell's own `infixl 1 <&>`, which is lower precedence than `infixl 4 <$>` (`<£>`'s Haskell
counterpart, `Data.Functor`'s `<$>`) despite both being "functor map."

---

## Which operator do I need?

- **Transform a value inside a container, function first** → `<£>` (`<&>` if the container reads
  more naturally first, e.g. mid-pipeline).
- **Transform the value one layer inside a nested value** (`Writer<W, Either<L, A>>`,
  `Either<L, Result<A, E>>`, …) → wrap it in its stack and use `<£>` as usual
  (`f <£> writer.writerT`, then `.rawValue` to leave).
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
- **Concatenate two monoidal values** (arrays, strings, logs, `Endo` chains, …) → `<>`.
- **Chain plain functions, or compose optics (`Lens`/`Prism`/`AffineTraversal`/`Iso`)** → `>>>` /
  `<<<`.
- **Apply a function to a value with minimal parentheses** → `<|` (function first) or `|>`
  (value first, pipeline style).
- **Extend a comonadic computation over its whole context** (`NonEmpty`, `Zipper`, `Writer`, `Reader` with a `Monoid`
  environment) → `->>` / `<<-`.
- **Check membership without writing `range ~= value` backwards, or build a tolerance range** →
  `≅` / `±` (`+/-`).

---

## For Haskell developers

Because this whole article *is* the Haskell mapping (the table above gives the `Data.Functor` /
`Control.Applicative` / `Control.Monad` / `Control.Category` equivalent for nearly every symbol),
the more useful note here is where behavior **diverges** from Haskell rather than where it lines
up.

**`>>>` and `<<<` bind like Haskell's `.`, not like `Control.Category`.** In Haskell they are
`infixr 1`, here they are the highest custom precedence (9.5 and 9), the same slot Haskell gives
`.` (`infixr 9`).

**`&&` and `||` are left-associative here, where Haskell's are right-associative.** Haskell
declares `infixr 3 &&` and `infixr 2 ||`; Swift's standard library declares
`LogicalConjunctionPrecedence`/`LogicalDisjunctionPrecedence` as left-associative, and this is a
Swift standard-library default this codebase cannot override (redeclaring `&&`/`||` would
conflict with the existing stdlib declarations, the same conflict that rules out a
power `^`). In practice the impact is minimal: `&&` and `||` are each associative operations in
the boolean case (`(a && b) && c` and `a && (b && c)` always agree), so the difference in grouping
never changes the result — it only matters if you were relying on short-circuit *evaluation
order* in a context with side effects, which this library's purity rules discourage in the first
place.

**There is no `^` power operator here.** Haskell's `(^) :: (Num a, Integral b) => a -> b -> a`
is an operator; in this library exponentiation is only the named function `power(_:_:)`, because
Swift's stdlib owns `^` as bitwise XOR in `AdditionPrecedence`.

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
