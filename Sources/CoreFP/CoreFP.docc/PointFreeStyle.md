# Point-Free Style

Tacit (point-free) programming: defining functions by composing other functions, without ever naming the arguments they act on.

A "point" here is a function's argument — the `x` in `{ x in f(g(x)) }`. Point-free style eliminates that intermediate variable entirely: `f <<< g` *is* the function, with no `x` to name, thread, or accidentally misuse. This library's composition utilities exist to make that style practical in Swift, which — unlike Haskell — has no built-in currying, no `(.)`, and no `$`.

---

## Why tacit style

Every named intermediate (`x`, `result`, `value`) is a small decision: what to call it, whether it shadows an outer name, whether it's still in scope three lines later. Point-free composition removes the decision by removing the variable:

```swift
// Pointful — "value" exists only to be threaded from one call to the next
let shout: (String) -> String = { value in
    let trimmed = value.trimmingCharacters(in: .whitespaces)
    let upper = trimmed.uppercased()
    return upper + "!"
}

// Point-free — the same three steps, composed directly
let shout2 = trim >>> uppercased >>> exclaim
```

The tacit version reads as a *pipeline*, not a sequence of assignments — which is also why it composes: `trim >>> uppercased` is itself a function, reusable anywhere a `(String) -> String` is expected, without unwrapping it back into a closure first. Named functions compose; closures merely nest.

This is the same motivation behind the project's own house style (see the root `CLAUDE.md`): opening a closure just to immediately call a single named function through it is redundant work once the composition operators are in scope. `{ $0.uppercased() }` and `uppercased` (a top-level named function, or `String.uppercased` via method-to-function reference) carry identical meaning; only one of them composes with `>>>` without an intermediate step.

---

## Worked example: refactoring a closure pipeline

Start with a typical closure-heavy function — given a list of people, return the uppercased names of adults:

```swift
struct Person { let name: String; let age: Int }

func adultNames(_ people: [Person]) -> [String] {
    people
        .filter { person in person.age >= 18 }
        .map { person in person.name.uppercased() }
}
```

Every closure here exists to extract a property and immediately hand it to something else. Refactor one closure at a time.

**Step 1 — replace field access with key paths.** A key path *is* a function (`\Person.age : (Person) -> Int`), so the projection needs no closure:

```swift
func adultNames(_ people: [Person]) -> [String] {
    people
        .filter { $0.age >= 18 }
        .map { \.name >>> uppercased $0 }   // not yet valid — see step 2
}
```

**Step 2 — replace the comparison with `flip`.** `$0.age >= 18` is really "is `age` at least 18" — a fixed predicate with one still-free argument. `>=` is `(Int, Int) -> Bool`; `flip` swaps which side gets applied first, so fixing `18` produces a reusable predicate:

```swift
let isAdult: (Int) -> Bool = flip(>=)(18)   // (Int) -> Bool — "is at least 18"
```

**Step 3 — compose the predicate with the key path, and the transform with `>>>`.** Both `filter` and `map` still need a `(Person) -> _` function; composition builds one from the parts:

```swift
let adultNames: ([Person]) -> [String] = {
    $0.filter(\.age >>> isAdult)
      .map(\.name >>> uppercased)
}
```

The predicate and the transform are now fully point-free — built from `flip`, `>>>`, and key paths, with no closure body anywhere inside them. The single `{ $0. … }` wrapper at the top remains only because `filter`/`map` are *methods*, not free functions this library provides a point-free entry point for — `£`/`|>` compose free functions, not method calls. That outer wrapper is exactly the boundary discussed below.

**Using `£` / `|>` for the call itself:**

```swift
let people = [Person(name: "Ada", age: 16), Person(name: "Alan", age: 25)]

adultNames £ people        // fn-left application
people |> adultNames       // value-left, pipeline-friendly
```

---

## Reference

Every function below is a **named function** in `CoreFP`; each has a corresponding entry (or delegates directly to it) in the operator vocabulary described in `README.md`.

| Function | Signature (essence) | Example |
|---|---|---|
| `id` | `(A) -> A` | `id("hello") // "hello"` — replaces `{ $0 }` |
| `const` | `(Return) -> (A) -> Return` (0…4+ ignored args) | `[1, 2, 3].map(const(0)) // [0, 0, 0]` |
| `ignore` | `(A) -> Void` (0…4+ args) | `tasks.forEach(ignore)` — discard results |
| `curry` | `((A, B) -> C) -> (A) -> (B) -> C` | `curry(+)(2)(3) // 5` |
| `curryT` | `(((A, B)) -> C) -> (A) -> (B) -> C` | `curryT { $0.0 + $0.1 }(2)(3) // 5` |
| `uncurry` | `((A) -> (B) -> C) -> (A, B) -> C` | `uncurry(curry(+))(2, 3) // 5` |
| `partialApply` | `((A, B) -> C, A) -> (B) -> C` | `partialApply(*, 3)(7) // 21` |
| `flip` | `((A, B) -> C) -> (B) -> (A) -> C` | `flip(-)(3)(10) // 7` (`10 - 3`) |
| `flipU` | `((A, B) -> C) -> (B, A) -> C` | `flipU(-)(3, 10) // 7` (uncurried swap) |
| `partialApplyFlip` | `((A, B) -> C, B) -> (A) -> C` | `partialApplyFlip(/, 2)(10) // 5` (fixes the *second* arg) |
| `tuple` | `(A, B) -> (A, B)`, or `((A,B)->C) -> ((A,B))->C` | `tuple(1, "a") // (1, "a")` |
| `untuple` | `(((A, B)) -> C) -> (A, B) -> C` | `untuple { $0.0 + $0.1 }(3, 4) // 7` |
| `withArg` | picks one tuple slot into a unary function | `withArg(\.1)(\.count)(42, "hi") // 2` |
| `fail` | `(String) -> (…) -> T`, calls `fatalError` | `init(fn: fail("Mock not implemented"))` |
| `compose` | `((A)->B, (B)->C) -> (A)->C` | `compose(trim, uppercased)("  hi ") // "HI"` |
| `compose3` / `compose4` | 3-/4-step chains | `compose3(trim, uppercased, exclaim)(" hi ")` |
| `call` | `((A)->B, A) -> B` | `call(uppercased, "hi") // "HI"` |
| `fanout` | `(repeat (Input)->Output) -> (Input) -> (repeat Output)` | `fanout(\.min, \.max)([3,1,4]) // (1, 4)` (n-ary, via parameter packs) |
| `fanout(keypaths:into:)` | `(repeat KeyPath<Root, T>, (repeat T)->Out) -> (Root)->Out` | `fanout(keypaths: \.badge, \.save, into: Env.init)` (fan-out straight into a multi-arg `init`) |
| `mapTuple2` / `mapTuple3` | `((A)->B) -> (A,A)->(B,B)` (or 3-ary) | `mapTuple2(uppercased)("a", "b") // ("A", "B")` |

`curry`, `partialApply`, `flip`, `partialApplyFlip`, and `lazy` each ship an additional `Sendable`-constrained overload (see the root `CLAUDE.md` Sendable Contract) — the compiler picks whichever one type-checks at the call site, so no extra syntax is needed to opt in.

### Fanning a value into a multi-argument initializer

A common shape is narrowing one large value into a smaller one whose `init` takes the pieces as separate
arguments — e.g. deriving a feature's `Environment` from a big `World`. `fanout` produces the tuple; a
multi-argument `init` consumes the arguments. Because Swift (since SE-0110) treats a *tuple* argument and a
*multi-argument* parameter list as distinct types, plain composition would need a manual splat — so there
are two point-free spellings, pick by taste:

```swift
struct Env: Sendable { init(badge: Int, save: Int) { … } }

// With the operator — a variadic `>>>` overload bridges the tuple to the multi-arg init:
let a: @Sendable (World) -> Env = fanout(\.badge, \.save) >>> Env.init

// Symbol-free — `fanout(keypaths:into:)` closes the loop in one call:
let b: @Sendable (World) -> Env = fanout(keypaths: \.badge, \.save, into: Env.init)
```

The variadic `>>>` coexists with the single-argument overload without ambiguity: a single-output function
composes through the plain overload, a tuple-output `fanout` through the variadic one. The mirror `<<<`
works too (`Env.init <<< fanout(\.badge, \.save)`).

---

## When point-free hurts

Point-free is a tool for *removing noise*, not a mandate to eliminate every named value. Two symptoms mean it has gone too far:

- **Composition chains that no longer name a concept.** `\.age >>> flip(>=)(18)` reads fine inline once — as `isAdult` it reads as a concept everywhere it's reused. If a composed pipeline has a name in the domain, give it one; point-free composes the *implementation* of `isAdult`, it doesn't forbid the binding.
- **Operator soup.** Nesting `£`/`<|`/`|>`/`>>>`/`<<<` three or four deep to avoid a two-line closure usually reads worse than the closure it replaced. This library's own convention (see `CLAUDE.md`) is: prefer the point-free form when a named function or operator is *already* in scope and directly applicable — don't manufacture composition just to avoid `{ $0 }`.

The rule of thumb used throughout this library: point-free where it removes an unnecessary intermediate name; a short closure (or a named `let`) where the intermediate name *is* the documentation.

---

## For Haskell developers

| This library | Haskell | Notes |
|---|---|---|
| `const` | `const` | identical semantics; this library adds 0–4+-arg overloads since Swift has no currying by default |
| `flip` | `flip` | identical; `flipU` is the uncurried variant Haskell doesn't need (Haskell functions are curried natively) |
| `curry` / `uncurry` | `curry` / `uncurry` | identical names and semantics |
| `id` | `id` | identical |
| `>>>` / `<<<` | `Control.Category`'s `(>>>)` / `(<<<)` (`(<<<)` = `(.)`) | Haskell's bare `(.)` is right-to-left, matching `<<<`; `>>>` is the left-to-right dual from `Control.Category` |
| `£` / `<\|` | `($)` | function application, low precedence, right-associative — same role as Haskell's `$` |
| `\|>` | `(&)` from `Data.Function` | value-first application, left-associative — Haskell's pipeline operator |
| `withArg` | closest is `Data.Function.on`, though `on` transforms the *comparator*, not the argument position | no exact equivalent — `withArg` is Swift-specific plumbing for adapting arity around key paths |

For general background on the style itself — not specific to this library — see the Haskell Wiki's [Pointfree](https://wiki.haskell.org/Pointfree) page, and Gabriel Gonzalez's [Point-Free or Die: Tacit Programming in Haskell and Beyond](https://www.haskellforall.com/2014/03/point-free-or-die-tacit-programming-in.html) for a deeper argument on when tacit style helps and when it doesn't.

---

## Module

```swift
import FP        // Named functions (curry, flip, compose, fanout…)
import CoreFPOperators  // Operators (>>>, <<<, £, <|, |>…)
```
