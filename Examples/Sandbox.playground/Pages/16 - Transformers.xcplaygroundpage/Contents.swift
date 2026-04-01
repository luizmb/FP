import FP

// ============================================================
// MONAD TRANSFORMERS
//
// Transformers stack two monadic contexts. The name convention
// is OuterTInner, e.g.:
//   OptionalTArray      = [A]?          = Optional<Array<A>>
//   EitherTArray        = Either<L,[A]> = Either<L, Array<A>>
//   DeferredTaskTEither = DeferredTask<Either<L,A>>
//
// Each transformer exposes mapT, flatMapT, liftA2T and their
// operator counterparts: <£^>, <&^>, <*^>, >>-^.
//
// Key insight: mapT maps over the INNER type through BOTH layers.
// Regular fmap would map over the OUTER type only.
// ============================================================

// MARK: - OptionalTArray  ([A]?)
// Outer = Optional, Inner = Array
// Use when: you have an optional list and want to map over the elements
//           without unwrapping the Optional first.

// let opt: [Int]? = .some([1, 2, 3])
// let none: [Int]? = .none

// --- mapT: map over inner Array elements, through the Optional ---
// opt.mapT { $0 * 2 }                      // .some([2, 4, 6])
// none.mapT { $0 * 2 }                     // .none

// --- fmapT (curried static) ---
// Optional<[Int]>.fmapT { $0 * 2 }(opt)   // .some([2, 4, 6])

// --- Transformer operator <£^> (fn left) ---
// { $0 * 2 } <£^> opt                      // .some([2, 4, 6])
// { $0 * 2 } <£^> none                     // .none

// --- <&^> (value left) ---
// opt <&^> { $0 * 2 }                      // .some([2, 4, 6])

// --- Compare with regular fmap ---
// { $0.count } <£> opt                     // .some(3) — maps over the Array itself
// { $0 * 2 }  <£^> opt                     // .some([2, 4, 6]) — maps over each Int

// --- flatMapT: each element maps to a new optional list; nil collapses all ---
// opt.flatMapT { n -> [Int]? in n > 1 ? .some([n, n * 10]) : .none }
// // .none — the first element (1) returned .none, so the whole thing collapses

// opt.flatMapT { n -> [Int]? in .some([n, n * 10]) }
// // .some([1, 10, 2, 20, 3, 30])

// --- liftA2T: combine two optional arrays element-by-element (cartesian) ---
// let opt2: [Int]? = .some([10, 20])
// Optional<[Int]>.liftA2T(+)(opt, opt2)    // .some([11, 21, 12, 22, 13, 23])
// Optional<[Int]>.liftA2T(+)(none, opt2)   // .none


// MARK: - OptionalTResult  (Result<E, A>?)
// Outer = Optional, Inner = Result

// let opt: Result<String, Int>? = .some(.success(5))
// let optFail: Result<String, Int>? = .some(.failure("error"))
// let none: Result<String, Int>? = .none

// --- mapT: map over the Success value through Optional and Result ---
// opt.mapT { $0 * 2 }                      // .some(.success(10))
// optFail.mapT { $0 * 2 }                  // .some(.failure("error")) — failure unchanged
// none.mapT { $0 * 2 }                     // .none

// --- Operators ---
// { $0 * 2 } <£^> opt                      // .some(.success(10))
// opt <&^> { $0 * 2 }                      // .some(.success(10))


// MARK: - EitherTArray  (Either<L, [A]>)
// Outer = Either, Inner = Array

// let right: Either<String, [Int]> = .right([1, 2, 3])
// let left:  Either<String, [Int]> = .left("error")

// --- mapTEitherArray: map over inner elements through Either ---
// mapTEitherArray({ $0 * 2 }, right)       // .right([2, 4, 6])
// mapTEitherArray({ $0 * 2 }, left)        // .left("error") — left untouched

// --- fmapTEitherArray (curried) ---
// fmapTEitherArray({ $0 * 2 })(right)      // .right([2, 4, 6])

// --- Operators ---
// { $0 * 2 } <£^> right                    // .right([2, 4, 6])
// right <&^> { $0 * 2 }                    // .right([2, 4, 6])

// --- flatMapT ---
// right.flatMapT { n -> Either<String, [Int]> in
//     n > 1 ? .right([n, n * 10]) : .left("too small")
// }
// // .left("too small") — first element is 1

// right.flatMapT { n -> Either<String, [Int]> in .right([n, n * 10]) }
// // .right([1, 10, 2, 20, 3, 30])


// MARK: - DeferredTaskTEither  (DeferredTask<Either<L, A>>)
// The most common real-world transformer: async operations that can fail.

// let taskRight: DeferredTask<Either<String, Int>> = DeferredTask { .right(42) }
// let taskLeft:  DeferredTask<Either<String, Int>> = DeferredTask { .left("not found") }

// --- mapT: transform the success value inside the async Either ---
// let mapped = taskRight.mapT { $0 * 2 }   // DeferredTask<Either<String, Int>> — still lazy

// --- Operator ---
// let mapped2 = { $0 * 2 } <£^> taskRight  // same

// --- flatMapT: chain async-failable operations ---
// let chained = taskRight.flatMapT { n in
//     DeferredTask { n > 0 ? Either<String, Int>.right(n + 1) : .left("non-positive") }
// }
// // Task { await chained.run() }           // Either<String, Int>.right(43)

// --- Practical: fetch user, then fetch their profile ---
// let fetchUser: DeferredTask<Either<String, Int>> = DeferredTask { .right(1) }
// let fetchProfile: (Int) -> DeferredTask<Either<String, String>> = { id in
//     DeferredTask { id > 0 ? .right("Profile for user \(id)") : .left("Invalid ID") }
// }

// let program = fetchUser.flatMapT(fetchProfile)
// // Task { await program.run() }           // .right("Profile for user 1")


// MARK: - ArrayTOptional  ([A?])
// Outer = Array, Inner = Optional

// let arr: [Int?] = [.some(1), .none, .some(3)]

// --- mapT: map over the present values, leave nils as nils ---
// arr.mapT { $0 * 2 }                      // [.some(2), .none, .some(6)]

// --- Operators ---
// { $0 * 2 } <£^> arr                      // [.some(2), .none, .some(6)]
// arr <&^> { $0 * 2 }                      // [.some(2), .none, .some(6)]

// --- Compare with regular map ---
// arr.map { $0.map { $0 * 2 } }            // same — but more verbose
// { $0 * 2 } <£^> arr                      // concise transformer version


// MARK: - WriterTEither  (Writer<W, Either<L, A>>)
// Logging combined with error handling.

// let wRight = Writer(Either<String, Int>.right(5), ["computed 5"])
// let wLeft  = Writer(Either<String, Int>.left("oops"), ["step failed"])

// --- mapT: transform the Either's right value, keep log ---
// wRight.mapT { $0 * 2 }                   // Writer(.right(10), ["computed 5"])
// wLeft.mapT  { $0 * 2 }                   // Writer(.left("oops"), ["step failed"])

// --- Operators ---
// { $0 * 2 } <£^> wRight                   // Writer(.right(10), ["computed 5"])

//: [Previous](@previous) | [Next](@next)
