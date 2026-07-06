# Stateful

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
let doubled = { $0 * 2 } <£> increment   // Stateful<Int, Int> that increments then doubles
doubled.eval(0)   // 2   (state went 0→1, value is 1*2=2)

increment <&> { $0 * 2 }  // same

// Named functions
increment.mapStateful { $0 * 2 }
increment.fmap { $0 * 2 }
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
let addN = Stateful<Int, (Int) -> Int>.pure { n in n }  // produces a function from state
let value = Stateful<Int, Int> { s in s * 2 }

(addN <*> value).eval(3)   // 6  (state threads through addN first, then value)

// Named functions
Stateful.apply(addN, value)
Stateful.zip(increment, increment).eval(0)   // (1, 2)  — state is 0→1→2
Stateful.liftA2(+)(increment, increment).eval(0)  // 3  (1 + 2)
```

---

## `*>` and `<*` — Sequence

Run two stateful computations in sequence (state threads through both), keeping only one result.

```swift
let log    = Stateful<Int, String> { _ in "logged" }
let double = Stateful<Int, Int>    { s in s * 2 }

(log *> double).eval(5)   // 10  (log runs but "logged" is discarded)
(double <* log).eval(5)   // 10  (double result kept, log runs for state effect)

// Named functions
double.seqRight(log)
double.seqLeft(log)
```

---

## `>>-` and `-<<` — Bind (flatMap)

Chain stateful computations where the next computation depends on the output of the previous one. The state threads through both.

```swift
// read the current state, then push a scaled version
let scaleAndStore: Stateful<Int, Int> = Stateful.get >>- { n in
    Stateful.put(n * 10) *> Stateful.pure(n * 10)
}

scaleAndStore.runStateful(3)   // (30, 30)  — value is 30, new state is 30

let chain = increment >>- { n in
    Stateful<Int, String> { _ in "Got \(n)" }
}
chain.eval(0)   // "Got 1"

// Named functions
increment.flatMap { n in Stateful.pure(n * 100) }
Stateful.bind { n in Stateful.pure(n * 2) }(increment)
```

---

## `>=>` — Kleisli composition

Compose two functions that each return a `Stateful`.

```swift
let step1: (Int) -> Stateful<[Int], Int> = { n in
    Stateful { log in log.append(n); return n * 2 }
}
let step2: (Int) -> Stateful<[Int], String> = { n in
    Stateful { log in log.append(n); return "Result: \(n)" }
}

let pipeline = step1 >=> step2
pipeline(3).runStateful([])   // ("Result: 6", [3, 6])

// Named function
Stateful.kleisli(step1, step2)(3).runStateful([])
```

---

## State primitives

```swift
// get — produces the current state as the value
Stateful<Int, Int>.get.eval(42)              // 42

// gets — project a value out of the state
Stateful.gets(\.description).eval(42)        // "42"

// put — replace the state, produce Void
Stateful<Int, Void>.put(99).exec(0)          // 99

// modify — transform the state in place
Stateful<Int, Void>.modify { $0 + 1 }.exec(10)   // 11

// modifyInPlace — mutating version (same effect)
Stateful<Int, Void>.modifyInPlace { $0 *= 2 }.exec(5)  // 10

// Combining primitives
let program: Stateful<[String], String> =
    Stateful.modify { $0 + ["step 1"] } *>
    Stateful.modify { $0 + ["step 2"] } *>
    Stateful.gets { $0.joined(separator: ", ") }

program.eval([])   // "step 1, step 2"
```

---

## Monad Transformers

Stateful participates in transformer stacks either as the **outer** layer or as the **inner** layer.

### `StatefulTOptional` — `Stateful<S, A?>` (outer = Stateful, inner = Optional)

State threads through regardless of whether a value is present.

```swift
let maybeIncrement = Stateful<Int, Int?> { s in
    s > 0 ? (s += 1; return s) : nil   // increments state even when returning nil
}
// Note: state mutation happens either way

{ $0 * 2 } <£^> maybeIncrement   // Stateful<Int, Int?> — maps inside the Optional
```

### `StatefulTEither` — `Stateful<S, Either<L, A>>` (outer = Stateful, inner = Either)

```swift
let safeIncrement = Stateful<Int, Either<String, Int>> { s in
    s < 100 ? (s += 1; return .right(s)) : .left("overflow")
}

{ $0 * 2 } <£^> safeIncrement   // Stateful<Int, Either<String, Int>>
```

### `StatefulTResult` — `Stateful<S, Result<A, E>>` (outer = Stateful, inner = Result)

```swift
let result: Stateful<Int, Result<Int, MyError>> =
    increment.fmap { .success($0) }

{ $0 * 2 } <£^> result   // Stateful<Int, Result<Int, MyError>>
```

### `StatefulTWriter` — `Stateful<S, Writer<W, A>>` (outer = Stateful, inner = Writer)

Threads state while also accumulating a log.

```swift
let logged: Stateful<Int, Writer<[String], Int>> = increment.fmap { n in
    Writer(n, ["incremented to \(n)"])
}
{ $0 * 2 } <£^> logged  // Stateful<Int, Writer<[String], Int>>
```

### `OptionalTStateful` — `Stateful<S, A>?` (outer = Optional, inner = Stateful)

```swift
let s: Stateful<Int, Int>? = .some(increment)
s?.fmap { $0 * 2 }         // Optional(Stateful)
```

### `ArrayTStateful` — `[Stateful<S, A>]` (outer = Array, inner = Stateful)

```swift
let steps: [Stateful<Int, Int>] = [increment, increment, increment]
// Run all steps by folding:
let combined = steps.reduce(Stateful.pure(())) { acc, step in acc *> step.void() }
combined.exec(0)  // 3
```

---

## Module

```swift
import DataStructure          // Stateful type + named functions
import DataStructureOperators // Operators (<£>, <*>, >>-, >=>…)
```
