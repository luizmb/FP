import FP

// ============================================================
// APPLICATIVE
// liftA2 :: (a -> b -> c) -> f a -> f b -> f c
// apply  :: f (a -> b) -> f a -> f b
//
// Applicative extends Functor to support applying a wrapped function
// to a wrapped value, and combining multiple independent effects.
//
// Unlike Monad, the effects are independent — neither depends on
// the result of the other. This enables static analysis and parallelism.
//
// Laws:
//   Identity:     pure id <*> v == v
//   Composition:  pure (.) <*> u <*> v <*> w == u <*> (v <*> w)
//   Homomorphism: pure f <*> pure x == pure (f x)
//   Interchange:  u <*> pure y == pure ($ y) <*> u
// ============================================================

// MARK: - Optional

// let x: Int? = 3
// let y: Int? = 4
// let none: Int? = nil

// --- liftA2: combine two independent optionals with a binary function ---
// Optional<Int>.liftA2(+)(x, y)            // .some(7)
// Optional<Int>.liftA2(+)(x, none)         // .none — any nil propagates
// Optional<Int>.liftA2(+)(none, none)       // .none

// --- apply: wrapped function applied to wrapped value ---
// let wrappedFn: ((Int) -> Int)? = .some { $0 * 2 }
// Optional.apply(wrappedFn, x)             // .some(6)
// Optional.apply(.none, x)                 // .none

// --- Operator <*> ---
// wrappedFn <*> x                          // .some(6)
// wrappedFn <*> none                       // .none

// --- seqRight: run both, discard left, keep right ---
// x.seqRight(y)                            // .some(4)
// none.seqRight(y)                         // .none
// x *> y                                   // .some(4) — operator

// --- seqLeft: run both, keep left, discard right ---
// x.seqLeft(y)                             // .some(3)
// x.seqLeft(none)                          // .none
// x <* y                                   // .some(3) — operator

// --- zip: tuple up two optionals ---
// Optional<(Int, Int)>.zip(x, y)           // .some((3, 4))
// Optional<(Int, Int)>.zip(x, none)        // .none


// MARK: - Array

// let xs = [1, 2, 3]
// let ys = [10, 20]

// --- liftA2: cartesian product mapped through a function ---
// [Int].liftA2(+)(xs, ys)                  // [11, 21, 12, 22, 13, 23]
// // Every element of xs combined with every element of ys

// --- apply: each wrapped function applied to each value ---
// let fns: [(Int) -> Int] = [{ $0 + 1 }, { $0 * 2 }]
// fns <*> xs                               // [2, 3, 4, 2, 4, 6]

// --- seqRight: cartesian product, keep right ---
// xs *> ys                                 // [10, 20, 10, 20, 10, 20]

// --- seqLeft: cartesian product, keep left ---
// xs <* ys                                 // [1, 1, 2, 2, 3, 3]


// MARK: - Result

// let ok1: Result<String, Int> = .success(3)
// let ok2: Result<String, Int> = .success(4)
// let err: Result<String, Int> = .failure("oops")

// --- liftA2 ---
// Result<String, Int>.liftA2(+)(ok1, ok2)  // .success(7)
// Result<String, Int>.liftA2(+)(ok1, err)  // .failure("oops") — short-circuits on first error

// --- apply ---
// let wrappedFn: Result<String, (Int) -> Int> = .success { $0 * 2 }
// wrappedFn <*> ok1                        // .success(6)
// wrappedFn <*> err                        // .failure("oops")

// --- seqRight / seqLeft ---
// ok1 *> ok2                               // .success(4)
// ok1 <* ok2                               // .success(3)
// ok1 *> err                               // .failure("oops")


// MARK: - Either

// let r1: Either<String, Int> = .right(3)
// let r2: Either<String, Int> = .right(4)
// let l1: Either<String, Int> = .left("fail")

// --- liftA2 ---
// Either<String, Int>.liftA2(+)(r1, r2)    // .right(7)
// Either<String, Int>.liftA2(+)(r1, l1)    // .left("fail")

// --- apply ---
// let fn: Either<String, (Int) -> Int> = .right { $0 + 10 }
// fn <*> r1                                // .right(13)
// fn <*> l1                                // .left("fail")

// --- seqRight / seqLeft ---
// r1 *> r2                                 // .right(4)
// r1 <* r2                                 // .right(3)


// MARK: - Validation
// KEY DIFFERENCE: apply accumulates ALL errors rather than short-circuiting on the first.

// let v1: Validation<[String], Int> = .success(3)
// let v2: Validation<[String], Int> = .success(4)
// let e1: Validation<[String], Int> = .failure(["name is empty"])
// let e2: Validation<[String], Int> = .failure(["age is negative"])

// --- liftA2: succeeds only if both succeed, otherwise merges all errors ---
// Validation<[String], Int>.liftA2(+)(v1, v2)   // .success(7)
// Validation<[String], Int>.liftA2(+)(e1, v2)   // .failure(["name is empty"])
// Validation<[String], Int>.liftA2(+)(e1, e2)   // .failure(["name is empty", "age is negative"]) ← both!

// --- zip: accumulate errors from both sides ---
// Validation<[String], (Int, Int)>.zip(v1, v2)  // .success((3, 4))
// Validation<[String], (Int, Int)>.zip(e1, e2)  // .failure(["name is empty", "age is negative"])

// --- zip3: same for three fields ---
// let e3: Validation<[String], String> = .failure(["email is invalid"])
// Validation<[String], (Int, Int, String)>.zip3(e1, e2, e3)
// // .failure(["name is empty", "age is negative", "email is invalid"])


// MARK: - Reader

// struct Env { let base: Int }

// --- liftA2: two independent readers combined ---
// let r1 = Reader<Env, Int> { $0.base }
// let r2 = Reader<Env, Int> { $0.base * 2 }
// let combined = Reader<Env, Int>.liftA2(+)(r1, r2)  // Reader that returns base + base*2 = base*3
// combined.runReader(Env(base: 5))                   // 15

//: [Previous](@previous) | [Next](@next)
