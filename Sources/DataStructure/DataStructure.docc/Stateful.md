# ``Stateful``

`Stateful<S, A>` is a wrapper for a function `(inout S) -> A`.

It solves the **state threading** problem: instead of manually passing a mutable state value in and out of every function, you describe computations that *need* state and compose them freely. The state is threaded through the chain automatically. Nothing executes until you call `runStateful`, `eval`, or `exec`.

```swift
import DataStructure

// A counter that increments and returns the new value
let increment = Stateful<Int, Int> { state in
    state += 1
    return state
}

increment.eval(0)            // 1  (runs computation, returns value, discards final state)
increment.exec(0)            // 1  (runs computation, returns final state, discards value)
increment.runStateful(0)     // (1, 1)  (returns both value and final state)
```

---

## `<£>` and `<&>` — Map

Transform the produced value without changing what state it threads.

```swift
let twice: @Sendable (Int) -> Int = { $0 * 2 }

let doubledValue = twice <£> increment   // Stateful<Int, Int> that increments then doubles
doubledValue.eval(0)   // 2   (state went 0→1, value is 1*2=2)

increment <&> twice  // same

// Named functions
increment.map(twice)
increment.mapStateful(twice)
```

---

## `£>` and `<£` — Replace

Replace the produced value with a constant.

```swift
let incrementVoid = increment £> ()   // Stateful<Int, Void> — increments but produces nothing
incrementVoid.exec(0)   // 1  (state still advances, value is ())

() <£ increment  // same
```

---

## `<*>` — Apply

Combine two stateful computations that share the same state type: one producing a function, one producing a value. The state threads through both sequentially.

```swift
let addN = Stateful<Int, @Sendable (Int) -> Int>.pure { n in n }  // produces the identity function
let value = Stateful<Int, Int> { s in s * 2 }

(addN <*> value).eval(3)   // 6  (state threads through addN first, then value)

// Named functions
Stateful<Int, Int>.apply(addN, value)
Stateful<Int, (Int, Int)>.zip(increment, increment).eval(0)   // (1, 2)  — state is 0→1→2
Stateful<Int, Int>.liftA2 { (a: Int, b: Int) in a + b }(increment, increment).eval(0)  // 3  (1 + 2)
```

---

## `*>` and `<*` — Sequence

Run two stateful computations in sequence (state threads through both), keeping only one result.

```swift
let logStep = Stateful<Int, String> { _ in "logged" }
let twiceState = Stateful<Int, Int> { s in s * 2 }

(logStep *> twiceState).eval(5)   // 10  (logStep runs but "logged" is discarded)
(twiceState <* logStep).eval(5)   // 10  (twiceState result kept, logStep runs for state effect)

// Named functions
twiceState.seqRight(logStep)
twiceState.seqLeft(logStep)
```

---

## `>>-` and `-<<` — Bind (flatMap)

Chain stateful computations where the next computation depends on the output of the previous one. The state threads through both.

```swift
// read the current state, then push a scaled version
let scaleAndStore: Stateful<Int, Int> = Stateful<Int, Int>.get >>- { n in
    Stateful<Int, Void>.put(n * 10) *> Stateful<Int, Int>.pure(n * 10)
}

scaleAndStore.runStateful(3)   // (30, 30)  — value is 30, new state is 30

let chain = increment >>- { n in
    Stateful<Int, String> { _ in "Got \(n)" }
}
chain.eval(0)   // "Got 1"

// Named functions
increment.flatMap { n in Stateful<Int, Int>.pure(n * 100) }
Stateful<Int, Int>.bind { n in Stateful<Int, Int>.pure(n * 2) }(increment)
```

---

## `>=>` — Kleisli composition

Compose two functions that each return a `Stateful`.

```swift
let step1: @Sendable (Int) -> Stateful<[Int], Int> = { n in
    Stateful { log in
        log.append(n)
        return n * 2
    }
}
let step2: @Sendable (Int) -> Stateful<[Int], String> = { n in
    Stateful { log in
        log.append(n)
        return "Result: \(n)"
    }
}

let pipeline = step1 >=> step2
pipeline(3).runStateful([])   // ("Result: 6", [3, 6])

// Named function
Stateful<[Int], Int>.kleisli(step1, step2)(3).runStateful([])
```

---

## State primitives

```swift
// get — produces the current state as the value
Stateful<Int, Int>.get.eval(42)              // 42

// gets — project a value out of the state
Stateful<Int, String>.gets { $0.description }.eval(42)   // "42"

// put — replace the state, produce Void
Stateful<Int, Void>.put(99).exec(0)          // 99

// modify — transform the state in place
Stateful<Int, Void>.modify { $0 + 1 }.exec(10)   // 11

// modifyInPlace — mutating version (same effect)
Stateful<Int, Void>.modifyInPlace { $0 *= 2 }.exec(5)  // 10

// Combining primitives
let program: Stateful<[String], String> =
    Stateful<[String], Void>.modify { $0 + ["step 1"] } *>
    Stateful<[String], Void>.modify { $0 + ["step 2"] } *>
    Stateful<[String], String>.gets { $0.joined(separator: ", ") }

program.eval([])   // "step 1, step 2"
```

---

## Monad Transformers

Stateful participates in transformer stacks either as the **outer** layer (`StatefulT{Inner}`: `MaybeT` / `ExceptT` / `WriterT` over `State s`, so the state survives a failure; `StatefulTWriter` is isomorphic to `StateT s (Writer w)`) or as the **inner** layer (`{Outer}TStateful`). Each stack is its own struct around the nested value: lift in with `stateful.statefulT` (or `optional.optionalT`, `array.arrayT`, …, or the stack's `init(_:)`), use `map` / `apply` / `flatMap` / the operators, and leave with `.rawValue`. The escape hatch is `mapStateT` on the Stateful-outer stacks.

### `StatefulTOptional` (wraps `Stateful<S, A?>`, outer = Stateful, inner = Optional)

The state survives a missing value: this is `MaybeT (State s)`, not `StateT s Maybe` (which would lose the state on failure).

```swift
let maybeIncrement = Stateful<Int, Int?> { s in
    guard s > 0 else { return nil }
    s += 1
    return s
}
// Note: when the guard fails the state is left alone, and when it passes the state advances

maybeIncrement.statefulT.map { $0 * 2 }   // StatefulTOptional<Int, Int>, maps inside the Optional
```

### `StatefulTEither` (wraps `Stateful<S, Either<L, A>>`, outer = Stateful, inner = Either)

```swift
let safeIncrement = Stateful<Int, Either<String, Int>> { s in
    guard s < 100 else { return .left("overflow") }
    s += 1
    return .right(s)
}

safeIncrement.statefulT.map { $0 * 2 }   // StatefulTEither<Int, String, Int>
```

### `StatefulTResult` (wraps `Stateful<S, Result<A, E>>`, outer = Stateful, inner = Result)

```swift
enum CounterError: Error, Sendable { case overflow }

let counted: Stateful<Int, Result<Int, CounterError>> =
    increment.map { .success($0) }

counted.statefulT.map { $0 * 2 }   // StatefulTResult<Int, CounterError, Int>
```

### `StatefulTWriter` (wraps `Stateful<S, Writer<W, A>>`, outer = Stateful, inner = Writer)

Threads state while also accumulating a log.

```swift
let logged: StatefulTWriter<Int, [String], Int> = increment.map { n in
    Writer(n, ["incremented to \(n)"])
}.statefulT
logged.map { $0 * 2 }  // StatefulTWriter<Int, [String], Int>

// Bind (StateT s (Writer w)): the continuation returns the whole stack, so it can
// touch the state and emit its own log. State threads left to right, logs append.
let doubledLog = logged.flatMap { n in
    StatefulTWriter(Stateful<Int, Writer<[String], Int>> { state in
        state *= 2
        return Writer(n, ["doubled state"])
    })
}
doubledLog.rawValue.runStateful(1)  // (Writer(2, ["incremented to 2", "doubled state"]), 4)
```

### `OptionalTStateful` (wraps `Stateful<S, A>?`, outer = Optional, inner = Stateful)

Functor and Applicative only (the outer Optional is decided before the state runs).

```swift
let maybeStep: Stateful<Int, Int>? = .some(increment)
maybeStep.optionalT.map { $0 * 2 }.rawValue   // Optional(Stateful)
```

### `ArrayTStateful` (wraps `[Stateful<S, A>]`, outer = Array, inner = Stateful)

```swift
let steps: [Stateful<Int, Int>] = [increment, increment, increment]
// Run all steps by folding:
let combined = steps.reduce(Stateful<Int, Void>.pure(())) { acc, step in acc *> step.void() }
combined.exec(0)  // 3
```

---

## Module

```swift-sketch
import DataStructure          // Stateful type, named functions and the StatefulT* / *TStateful stack structs
import DataStructureOperators // Operators (<£>, <*>, >>-, >=>…), also for the stacks
```

---

## For Haskell developers

`Stateful<S, A>` is the same state-threading monad as `Control.Monad.State`'s `State s a` (a wrapper for `s -> (a, s)`, just with the return order flipped to `(inout S) -> A` to match Swift's mutation idiom). There is no general `StateT s m`, since Swift's lack of higher-kinded types rules out a fully generic transformer. The stacks above (`StatefulTOptional`, `StatefulTEither`, …, each a newtype over the nested `Stateful`) are written out concretely, and they are not `StateT s Maybe` or `StateT s (Either l)`: `Stateful<S, A?>` is `MaybeT (State s)` and `Stateful<S, Either<L, A>>` is `ExceptT l (State s)`, so the state is kept when the inner layer fails. Only `StatefulTWriter` is isomorphic to `StateT s (Writer w)`.

| This library | Haskell (`Control.Monad.State` / `mtl`) |
|---|---|
| `Stateful<S, A>` | `State s a` (no general `StateT s m`) |
| `.eval(_:)` | `evalState` |
| `.exec(_:)` | `execState` |
| `.runStateful(_:)` | `runState` |
| `Stateful.get` | `get` |
| `Stateful.gets` | `gets` |
| `Stateful.put` | `put` |
| `Stateful.modify` / `.modifyInPlace` | `modify` / `modify'` |
| `<£>` / `<&>` (`.fmap`) | `fmap` / `<$>` |
| `<*>` (`.apply`, `.zip`, `.liftA2`) | `<*>` / `liftA2` |
| `*>` / `<*` | `*>` / `<*` |
| `>>-` / `-<<` (`.flatMap`) | `>>=` / `=<<` |
| `>=>` (`.kleisli`) | `>=>` |
| `Lens.zoom(_:)` / `Prism.zoom(_:)` / `AffineTraversal.zoom(_:)` | the `lens` package's `zoom` for composing an optic with `State` |

The naming parallel between `get`/`put`/`modify`/`gets` here and the `MonadState` methods in `mtl` is exact and intentional — code written against one reads almost line-for-line against the other.

One structural difference worth flagging: `Stateful` is **not** a Profunctor here — the state type `S` appears in both the input and output position of the wrapped function (`inout S`), so it's invariant rather than contravariant/covariant in the way `Reader`'s environment is. Haskell's `State` is in the same boat (it isn't a `Profunctor` either, for the same reason); only the *pair* `(->) s` used contravariantly and the result type used covariantly separately would justify calling it profunctor-like, but the "threaded" shape of `State`/`Stateful` doesn't decompose that way.

**References:**
- [`Control.Monad.State`](https://hackage.haskell.org/package/mtl/docs/Control-Monad-State.html) (`mtl`)
- [`Control.Lens.zoom`](https://hackage.haskell.org/package/lens/docs/Control-Lens-Zoom.html) (`lens`)
