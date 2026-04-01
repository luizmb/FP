import FP

// ============================================================
// MONAD
// bind     :: m a -> (a -> m b) -> m b   (flatMap)
// join     :: m (m a) -> m a             (flatten)
// (>=>)    :: (a -> m b) -> (b -> m c) -> (a -> m c)  (Kleisli)
//
// A Monad extends Applicative with bind (flatMap), which allows
// the next effect to depend on the result of the previous one.
// This is what makes sequencing and branching possible.
//
// Kleisli composition (>=>) is function composition in the Kleisli
// category — composing functions that return monadic values.
// It's derived from bind the same way (.) is derived from ($).
//
// Laws:
//   Left identity:  return a >>= f  == f a
//   Right identity: m >>= return    == m
//   Associativity:  (m >>= f) >>= g == m >>= (\x -> f x >>= g)
// ============================================================

// MARK: - Optional

// let x: Int? = 5
// let none: Int? = nil

// --- flatMap (instance) ---
// x.flatMap { $0 > 3 ? .some($0 * 2) : .none }   // .some(10)
// x.flatMap { $0 > 10 ? .some($0 * 2) : .none }   // .none — branch on value

// --- bind (curried static) ---
// let safeDivide: (Int) -> Int? = { $0 == 0 ? .none : .some(100 / $0) }
// Optional<Int>.bind(safeDivide)(x)        // .some(20)
// Optional<Int>.bind(safeDivide)(none)     // .none

// --- Operators ---
// x >>- safeDivide                         // .some(20) — value left
// safeDivide -<< x                         // .some(20) — fn left

// --- join: flatten nested optionals ---
// let nested: Int?? = .some(.some(42))
// Optional<Int>.join(nested)               // .some(42)
// let nested2: Int?? = .some(.none)
// Optional<Int>.join(nested2)              // .none

// --- Kleisli: compose two (a -> m b) functions ---
// let parsePositive: (String) -> Int? = { Int($0).flatMap { $0 > 0 ? $0 : nil } }
// let safeSqrt: (Int) -> Double? = { $0 >= 0 ? .some(Double($0).squareRoot()) : .none }
// let composed = Optional<Int>.kleisli(parsePositive, safeSqrt)
// composed("16")                           // .some(4.0)
// composed("-1")                           // .none
// composed("abc")                          // .none

// --- Kleisli operators (>=> and <=<) ---
// let composed2 = parsePositive >=> safeSqrt   // left-to-right
// composed2("9")                               // .some(3.0)
// let composed3 = safeSqrt <=< parsePositive   // right-to-left (same result)
// composed3("9")                               // .some(3.0)


// MARK: - Array

// --- flatMap: expand each element into an array, then flatten ---
// [1, 2, 3].flatMap { [$0, $0 * 10] }     // [1, 10, 2, 20, 3, 30]

// --- bind (curried) ---
// let expand: (Int) -> [Int] = { [$0, -$0] }
// [Int].bind(expand)([1, 2, 3])            // [1, -1, 2, -2, 3, -3]
// [1, 2, 3] >>- expand                    // [1, -1, 2, -2, 3, -3]

// --- join: flatten nested array ---
// [Int].join([[1, 2], [3], [4, 5]])        // [1, 2, 3, 4, 5]

// --- Kleisli ---
// let digits: (Int) -> [Int] = { n in n < 10 ? [n] : [n / 10, n % 10] }
// let doubled: (Int) -> [Int] = { [$0, $0 * 2] }
// let split = digits >=> doubled
// split(12)                                // [1, 2, 2, 4]


// MARK: - Result

// let ok: Result<String, Int> = .success(5)
// let err: Result<String, Int> = .failure("bad input")

// --- flatMap (instance) ---
// ok.flatMap { $0 > 3 ? .success($0 * 2) : .failure("too small") }  // .success(10)
// ok.flatMap { _ in Result.failure("always fails") }                 // .failure("always fails")

// --- bind (curried) ---
// let validate: (Int) -> Result<String, Int> = { $0 > 0 ? .success($0) : .failure("non-positive") }
// Result<String, Int>.bind(validate)(ok)   // .success(5)
// Result<String, Int>.bind(validate)(err)  // .failure("bad input")
// ok >>- validate                         // .success(5)

// --- Kleisli ---
// let parse: (String) -> Result<String, Int> = { Int($0).map(Result.success) ?? .failure("not a number") }
// let positive: (Int) -> Result<String, Int> = { $0 > 0 ? .success($0) : .failure("not positive") }
// let parsePositive = parse >=> positive
// parsePositive("42")                      // .success(42)
// parsePositive("-1")                      // .failure("not positive")
// parsePositive("abc")                     // .failure("not a number")


// MARK: - Either

// let r: Either<String, Int> = .right(5)
// let l: Either<String, Int> = .left("fail")

// --- flatMap (instance) ---
// r.flatMap { .right($0 * 2) }             // .right(10)
// r.flatMap { _ in Either<String, Int>.left("next step failed") }  // .left("next step failed")

// --- bind (curried) ---
// let step: (Int) -> Either<String, Int> = { $0 > 0 ? .right($0) : .left("non-positive") }
// Either<String, Int>.bind(step)(r)        // .right(5)
// r >>- step                              // .right(5)
// l >>- step                              // .left("fail") — left propagates


// MARK: - Reader (flatMap for dependency injection)

// struct Config { let factor: Int; let offset: Int }

// --- flatMap: each step can request the environment independently ---
// let r1 = Reader<Config, Int> { config in config.factor }
// let r2 = r1.flatMap { factor in Reader { config in factor + config.offset } }
// r2.runReader(Config(factor: 3, offset: 10))  // 13

// --- bind (curried) ---
// let pipeline = Reader<Config, Int>.bind { n in Reader { config in n * config.factor } }
// pipeline(Reader { $0.offset }).runReader(Config(factor: 3, offset: 10))  // 30


// MARK: - Writer (flatMap accumulates log via Monoid)

// let step1 = Writer(5, ["step 1: got 5"])
// let result = step1.flatMap { n in Writer(n * 2, ["step 2: doubled to \(n * 2)"]) }
// result.runWriter()                       // (10, ["step 1: got 5", "step 2: doubled to 10"])
// result.evalWriter()                      // 10
// result.execWriter()                      // ["step 1: got 5", "step 2: doubled to 10"]


// MARK: - Stateful (flatMap threads state through)

// let increment = Stateful<Int, Void> { state in state += 1 }
// let readAndDouble = Stateful<Int, Int> { state in
//     let value = state
//     state *= 2
//     return value
// }

// --- flatMap: first run increment, then readAndDouble ---
// let pipeline = increment.flatMap { _ in readAndDouble }
// pipeline.runStateful(5)                  // (5, 12) — value was 5 (before *2), state is now 12


// MARK: - DeferredTask (flatMap sequences async work lazily)

// let fetch = DeferredTask { 42 }
// let process = fetch.flatMap { n in DeferredTask { n * 2 } }
// // Nothing runs yet! Only when .run() is called:
// // await process.run()                   // 84

// --- Kleisli: compose async steps ---
// let step1: (String) -> DeferredTask<Int> = { s in DeferredTask { s.count } }
// let step2: (Int) -> DeferredTask<String> = { n in DeferredTask { "length: \(n)" } }
// let pipeline = step1 >=> step2
// // await pipeline("hello").run()         // "length: 5"

//: [Previous](@previous) | [Next](@next)
