---
name: fp-library
description: Write, refactor, read and debug Swift code that uses the FP library (modules FP, CoreFP, CoreFPOperators, DataStructure, DataStructureOperators). Covers the operator vocabulary (<£>, <&>, <*>, >>-, >=>, >>>, |>, <|>, <>) and its precedence, tacit helpers (curry, flip, const, ignore, fail, withArg, get), Either / Validation / Reader / Writer / Stateful / Loading, transformer stacks (ReaderTOptional, .readerT, rawValue), Prisms and case key paths, and making your own types work with the operators. Use it whenever Swift code imports FP or one of its modules, when someone asks to make Swift code more functional, point-free or Haskell-like with this library, when an operator chain doesn't compile or groups unexpectedly, when injecting dependencies with Reader, or when migrating from FP 2.x transformer APIs (mapT, <£^>, nested-value operators), even if they don't name the library.
---

# Using the FP library

FP is a Swift library of functional building blocks: named functions in `CoreFP` / `DataStructure`, and operator sugar for them in `CoreFPOperators` / `DataStructureOperators`. `import FP` re-exports all four. The macros (`@Lenses`, `@Prisms`, `@Mock`, …) live in the separate `FPMacros` product.

| Module | What's in it |
|---|---|
| `CoreFP` | Function helpers, optics (`Lens`, `Prism`, `AffineTraversal`, `Iso`), `Semigroup` / `Monoid`, `SumType2`, Optional / Array / Result / Publisher / AsyncStream extensions, the stacks between those types |
| `DataStructure` | `Either`, `Validation`, `Reader`, `Writer`, `Stateful`, `Loading`, `NonEmpty`, `These`, `Zipper`, `IdentifiedArray`, the stacks that involve them |
| `CoreFPOperators` / `DataStructureOperators` | Operators for the above, each one delegating to a named function |

Every operator is sugar over a named function (`<£>` is `map`, `>>-` is `flatMap`, `>=>` is `kleisli`), so when an operator chain gets hard to read, the named form is always available and never wrong.

## How to work

1. Figure out which effect each value lives in (`Optional`, `Result`, `Either`, `Validation`, `Reader`, a stack, …). Most confusion with this library comes from a value being one layer deeper or shallower than the code assumes.
2. Pick the operator by what you need to do (table below). The library's operators form one total precedence order, so they mix freely, but a few mixes with stdlib operators need parentheses, so read `references/operators.md` before writing a long chain.
3. Prefer composing small named functions over big closures, but only while it stays readable (a short closure is fine, don't force point-free style where it makes the code harder to follow).
4. Keep everything `Sendable`. The library takes `@Sendable` closures almost everywhere, so a closure stored in a `let` should be typed `@Sendable (A) -> B`.

## Which operator

| I want to | Operator | Named function |
|---|---|---|
| transform the value inside a container, function first | `f <£> x` | `x.map(f)` |
| same, container first (reads better mid pipeline) | `x <&> f` | `x.map(f)` |
| replace the value with a constant | `x £> v`, `v <£ x` | `x.map(const(v))` |
| combine independent wrapped values | `f <£> a <*> b` | `T.liftA2(f)(a, b)`, `T.apply` |
| run two effects, keep one result | `a *> b`, `a <* b` | `seqRight`, `seqLeft` |
| chain a step that depends on the previous result | `x >>- f`, `f -<< x` | `x.flatMap(f)` |
| compose two effectful functions before calling them | `f >=> g`, `g <=< f` | `T.kleisli(f, g)` |
| fall back when the first one fails | `a <\|> b` | `T.alt(a, b)` |
| append monoidal values (arrays, strings, logs, `Endo`) | `a <> b` | `S.combine(a, b)` |
| compose plain functions or optics | `f >>> g`, `g <<< f` | `compose` |
| apply a function with fewer parentheses | `x \|> f`, `f <\| x` | `apply`, `call` |
| lift a key path into a `@Sendable` getter or a `Lens` | `^\.name` | `get(\.name)`, `lens(\.name)` |

There is no infix power operator (use `power(_:_:)`), no `++` (use `<>`), no standalone `£` (use `<|`), and no `<£^>` / `<&^>` any more (wrap the value in its stack instead, see below).

## A first taste

```swift
import FP

let double: @Sendable (Int) -> Int = 2 |> curry(*)
let increment: @Sendable (Int) -> Int = 1 |> curry(+)

let doubledThenIncremented = (double >>> increment) <£> [1, 2, 3]  // [3, 5, 7]

let parse: @Sendable (String) -> Int? = { Int($0) }
let positive: @Sendable (Int) -> Int? = { $0 > 0 ? $0 : nil }
let parsePositive = parse >=> positive
let parsed = parsePositive("42")  // Optional(42)
let rejected = parsePositive("-1")  // nil

let total = Optional<Int>.liftA2(+)(parsePositive("2"), parsePositive("3"))  // Optional(5)
let firstAvailable = parsePositive("x") <|> parsePositive("7")  // Optional(7)
```

Swift has no operator sections (`(+1)`, `(*2)` don't exist), so partial application of an operator goes through `curry`: `1 |> curry(+)`. Swift's implicit KeyPath-to-function conversion isn't `@Sendable`, so a bare `\.name` won't go where the library wants a `@Sendable` closure; lift it with `get(\.name)` or `^\.name`.

## Tacit helpers worth knowing

| Helper | Use it for |
|---|---|
| `curry`, `flip`, `uncurry` | partial application and argument order |
| `compose`, `>>>`, `<<<` | function pipelines |
| `const(v)` | a function that ignores its arguments (0 to 4+) and returns `v` |
| `ignore` | a no-op that accepts any arguments, returns `Void` |
| `fail("msg")` | a stub that traps if it's ever called (test fixtures that must be overridden) |
| `withArg(\.0)(f)` | adapt a one-argument function to a two-argument call site |
| `get(\.path)` / `^\.path` | `@Sendable` getter from a key path |
| `id` | identity |

## Transformer stacks (3.0)

A nested value like `Reader<Env, User?>` is just a `Reader`: `<£>` on it maps the whole `User?`. To work one layer inside, wrap it in its stack, a struct named `OuterTInner` (`ReaderTOptional<Env, User>`), via the lifting property named after the outer type (`.readerT`, `.arrayT`, `.optionalT`, `.resultT`, `.eitherT`, `.statefulT`, `.writerT`, `.publisherT`, `.asyncStreamT`, …). Use `map` / `flatMap` / the usual operators on the stack, and leave with `.rawValue`.

```swift
struct Profile: Sendable { let name: String }
struct Env: Sendable { let profiles: [String: Profile] }

let findProfile: @Sendable (String) -> Reader<Env, Profile?> = { id in Reader { $0.profiles[id] } }

let profileName: @Sendable (String) -> Reader<Env, String?> = { id in
    (get(\Profile.name) <£> findProfile(id).readerT).rawValue
}
```

Some stacks have no lawful monad (anything with `Validation`, a list inside a non-commutative layer, `Writer` outside another monad, …), so they only offer `map` and the applicative surface. `references/transformer-stacks.md` has the model, the escape hatches (`mapReaderT`, `mapMaybeT`, `mapExceptT`, …) and the 2.x migration table.

## Pitfalls that come up again and again

- `<£>` wants the function on the left. `x <£> f` doesn't compile; write `f <£> x` or `x <&> f`.
- The library's operator groups are one total order (`>>>` > `<>` > `<£>` family > `<|>` > `>=>` > `>>-` > `<|` > `|>`), so `f <£> xs >>- g` and `x |> f >>> g` compile and group that way. What's still unordered is a library operator against some stdlib ones: `<|>`, `>>-` / `<&>` and `|>` with `==`, `+` and `??` (write `(a ?? b) |> f`). "adjacent operators are in unordered precedence groups" means that. `references/operators.md` has the full list.
- `>>-` is left associative (a sequence of effects), `>=>` is right associative (a pipeline of functions), and `>=>` binds tighter than `>>-`.
- An operator on a nested value acts on the outer layer. After upgrading from 2.x, some nested-value code still compiles with a different meaning (`*>` on a `Stateful<S, Either<L, A>>` no longer skips on `.left`). Wrap in the stack.
- `Reader` is for dependencies that come from outside the computation (API clients, config, feature flags), not for ordinary parameters. `Reader<Int, X>` is usually a smell.
- Need every error, not just the first? That's `Validation` (applicative, accumulates through a `Semigroup`), not `Result` / `Either` (monad, short-circuits).

## References

Read the one that matches the task; each is self-contained.

- `references/operators.md`: the full vocabulary, the precedence table, and how to explain or debug a chain step by step (types at each step, grouping, common errors).
- `references/refactoring.md`: turning imperative Swift (if-let pyramids, try/catch, loops, validation, UI loading state, test fixtures) into FP-library style.
- `references/reader.md`: dependency injection with `Reader` (`ask`, `asks`, `local`, composition, testing) and where it stops being a good idea.
- `references/transformer-stacks.md`: the `OuterTInner` struct model, lifting, escape hatches, which stacks are monads, and migrating 2.x code.
- `references/custom-types.md`: giving your own container type `map` / `flatMap` / `pure` / `apply` and the operators, following the library's conventions.

For optics (`Lens`, `Prism`, `@Lenses`, `@Prisms`), the DocC articles `Optics` and `Macros` are the source of truth; the short version is that `\.caseName` on a `@Prisms` enum is a composable `PrismKeyPath`, `Prism(\.a.b)` recovers the prism, and optics compose with `>>>`.
