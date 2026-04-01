import FP

// ============================================================
// FUNCTOR
// fmap :: (a -> b) -> f a -> f b
//
// A Functor is any context f that supports mapping a pure function
// over its wrapped value without changing the structure.
//
// Laws:
//   Identity:    fmap id == id
//   Composition: fmap (f . g) == fmap f . fmap g
// ============================================================

// MARK: - Optional


let x: Int? = 5
let none: Int? = nil

// --- Named function (curried static) ---
Optional<Int>.fmap { $0 * 2 }(x)        // .some(10)
Optional<Int>.fmap { $0 * 2 }(none)      // .none

// --- Instance method ---
x.map { $0 * 2 }                         // .some(10)

// --- Operators ---
{ $0 * 2 } <£> x                         // .some(10) — fn left
x <&> { $0 * 2 }                         // .some(10) — value left
x £> "hello"                             // .some("hello") — replace, keep structure
"hello" <£ x                             // .some("hello") — flipped replace

// MARK: - Array

// let arr = [1, 2, 3]

// --- Named function (curried static) ---
// [Int].fmap { $0 * 2 }(arr)               // [2, 4, 6]
// let double = [Int].fmap { $0 * 2 }
// double(arr)                              // [2, 4, 6]

// --- Instance method ---
// arr.map { $0 * 2 }                       // [2, 4, 6]

// --- Operators ---
// { $0 * 2 } <£> arr                       // [2, 4, 6] — fn left
// arr <&> { $0 * 2 }                       // [2, 4, 6] — value left
// arr £> 0                                 // [0, 0, 0] — replace each element


// MARK: - Result

// let ok: Result<String, Int> = .success(5)
// let err: Result<String, Int> = .failure("oops")

// --- Named function (curried static) ---
// Result<String, Int>.fmap { $0 * 2 }(ok)  // .success(10)
// Result<String, Int>.fmap { $0 * 2 }(err) // .failure("oops") — structure preserved

// --- Instance method ---
// ok.map { $0 * 2 }                        // .success(10)

// --- Operators ---
// { $0 * 2 } <£> ok                        // .success(10)
// ok <&> { $0 * 2 }                        // .success(10)
// ok £> "done"                             // .success("done")


// MARK: - Either

// let right: Either<String, Int> = .right(5)
// let left: Either<String, Int> = .left("error")

// --- Named function (curried static) ---
// Either<String, Int>.fmap { $0 * 2 }(right) // .right(10)
// Either<String, Int>.fmap { $0 * 2 }(left)  // .left("error") — left untouched

// --- Operators ---
// { $0 * 2 } <£> right                     // .right(10)
// right <&> { $0 * 2 }                     // .right(10)

// --- Bifunctor: map both sides independently ---
// right.mapRight { $0 * 2 }                // .right(10)
// right.mapLeft  { "[\($0)]" }             // .right(5) — left side unchanged
// left.mapLeft   { "[\($0)]" }             // .left("[error]")
// right.bimap({ "[\($0)]" }, { $0 * 2 })  // .right(10)


// MARK: - Reader

// struct AppConfig { let multiplier: Int }

// --- Named function ---
// let r = Reader<AppConfig, Int> { config in 3 * config.multiplier }
// r.mapReader { $0 + 1 }                   // Reader that returns 3*m + 1

// --- Operators ---
// let r2 = Reader<AppConfig, Int> { $0.multiplier }
// { $0 + 10 } <£> r2                       // Reader that adds 10 to the multiplier


// MARK: - Writer

// let w = Writer(42, ["computed value"])    // Writer<[String], Int>

// --- Named function ---
// w.fmap { $0 * 2 }                        // Writer(84, ["computed value"])

// --- Operators ---
// { $0 * 2 } <£> w                         // Writer(84, ["computed value"])


// MARK: - Stateful

// let s = Stateful<Int, String> { state in "count: \(state)" }

// --- Named function ---
// s.fmap { $0.uppercased() }               // Stateful that returns "COUNT: ..."

// --- Operators ---
// { $0.uppercased() } <£> s                // same via operator


// MARK: - DeferredTask

// let task = DeferredTask { 42 }

// --- Named function ---
// task.fmap { $0 * 2 }                     // DeferredTask { 84 } — still lazy!

// --- Operators ---
// { $0 * 2 } <£> task                      // DeferredTask { 84 }
// task <&> { $0 * 2 }                      // same, value left

//: [Next](@next)
