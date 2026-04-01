import FP

// ============================================================
// FUNCTION UTILITIES
//
// Building blocks for point-free, tacit programming.
// These are the combinators that make function composition
// and partial application ergonomic.
// ============================================================

// MARK: - id (identity)
// Returns its argument unchanged. Useful as a no-op in pipelines.

// id(42)                                   // 42
// id("hello")                              // "hello"
// [1, 2, 3].map(id)                        // [1, 2, 3]
// Optional<Int>.join(.some(.some(5)))       // 5 — join uses id internally


// MARK: - const (constant function)
// Returns a function that ignores its input and returns a fixed value.

// const(42)("ignored")                     // 42
// const(42)(true, "also ignored")          // 42
// [1, 2, 3].map(const("x"))               // ["x", "x", "x"]
// Optional<Int>.fmap(const(0))(.some(5))   // .some(0)


// MARK: - ignore
// Discards its argument and returns Void. Point-free void.

// [1, 2, 3].map(ignore)                    // [(), (), ()]
// let task = DeferredTask { 42 }.fmap(ignore)  // DeferredTask<Void>


// MARK: - curry / uncurry
// curry:   (A, B) -> C   becomes   (A) -> (B) -> C
// uncurry: (A) -> (B) -> C   becomes   (A, B) -> C

// func add(_ a: Int, _ b: Int) -> Int { a + b }

// let curriedAdd = curry(add)              // (Int) -> (Int) -> Int
// curriedAdd(3)(4)                         // 7
// let add3 = curriedAdd(3)                 // (Int) -> Int — partial application
// add3(10)                                 // 13
// [1, 2, 3].map(add3)                      // [4, 5, 6] — point-free map

// let uncurriedAdd = uncurry(curriedAdd)   // (Int, Int) -> Int
// uncurriedAdd(3, 4)                       // 7


// MARK: - flip
// Swap the first two arguments of a curried or uncurried function.

// func subtract(_ a: Int, _ b: Int) -> Int { a - b }
// let flippedSubtract = flip(subtract)     // (Int) -> (Int) -> Int, but b first
// flippedSubtract(3)(10)                   // 10 - 3 = 7 (was subtract(10, 3))

// let divide: (Double) -> (Double) -> Double = { a in { b in a / b } }
// let divideBy = flip(divide)              // now: divisor first
// let divideBy2 = divideBy(2.0)           // (Double) -> Double — divide by 2
// [10.0, 20.0, 30.0].map(divideBy2)        // [5.0, 10.0, 15.0]


// MARK: - partialApply
// Apply one argument of a two-argument function. Like curry + apply.

// func greet(_ greeting: String, _ name: String) -> String { "\(greeting), \(name)!" }
// let sayHello = partialApply(greet, "Hello")  // (String) -> String
// sayHello("Alice")                        // "Hello, Alice!"
// sayHello("Bob")                          // "Hello, Bob!"
// ["Alice", "Bob"].map(sayHello)           // ["Hello, Alice!", "Hello, Bob!"]


// MARK: - Function composition (>>> and <<<)
// >>>  left-to-right:  (f >>> g)(x) = g(f(x))
// <<<  right-to-left:  (f <<< g)(x) = f(g(x))

// let addOne:  (Int) -> Int = { $0 + 1 }
// let double:  (Int) -> Int = { $0 * 2 }
// let negate:  (Int) -> Int = { -$0 }

// --- Forward: addOne, then double, then negate ---
// let pipeline = addOne >>> double >>> negate
// pipeline(3)                              // -(( 3+1 )*2) = -8

// --- Backward: same order written right-to-left ---
// let pipeline2 = negate <<< double <<< addOne
// pipeline2(3)                             // -8 (same)

// --- Point-free map pipeline ---
// [1, 2, 3].map(addOne >>> double)         // [4, 6, 8]
// [1, 2, 3].map(negate <<< double)         // [-2, -4, -6]


// MARK: - Function application (£, <|, |>)
// £  / <|  — fn left, value right  (like Haskell's $)
// |>        — value left, fn right  (pipe operator)

// let addOne: (Int) -> Int = { $0 + 1 }

// --- £ / <| ---
// addOne £ 5                               // 6 — same as addOne(5)
// addOne <| 5                              // 6
// negate <| double <| addOne <| 3          // -8 — right-associative, reads right-to-left

// --- |> (pipe, value left) ---
// 3 |> addOne                              // 4
// 3 |> addOne |> double |> negate          // -8 — left-associative, reads left-to-right


// MARK: - lazy / unlazy
// lazy: wrap a value or function in a zero-argument closure
// unlazy: apply the Void argument

// let lazyValue = lazy(42)                 // () -> Int
// lazyValue()                              // 42

// let lazyAdd = lazy(addOne)               // () -> (Int) -> Int
// lazyAdd()(5)                             // 6

// let lazyFn: (Int) -> () -> String = { n in lazy("value: \(n)") }
// unlazy(lazyFn)(5)                        // "value: 5"


// MARK: - Endo (see also: Monoid and Semigroup page)
// A named wrapper for (A) -> A. Its Monoid is function composition.

// let trim    = Endo<String> { $0.trimmingCharacters(in: .whitespaces) }
// let lower   = Endo<String> { $0.lowercased() }
// let addBang = Endo<String> { $0 + "!" }

// --- Free constructor ---
// let exclaim = endo { (s: String) in s + "!" }

// --- Combine via <> or mconcat ---
// let normalize = trim <> lower <> addBang
// normalize.runEndo("  HELLO  ")           // "hello!"
// normalize("  HELLO  ")                   // "hello!" — callAsFunction

// --- mconcat from a dynamic list of transforms ---
// let rules: [Endo<String>] = [trim, lower, addBang]
// mconcat(rules)("  WORLD  ")             // "world!"

//: [Previous](@previous)
