import FP

// ============================================================
// MONAD TRANSFORMERS
//
// Stack two monadic contexts. Naming: OuterTInner.
//   OptionalTArray      = [A]?              Optional<Array<A>>
//   EitherTArray        = Either<L, [A]>
//   DeferredTaskTEither = DeferredTask<Either<L, A>>
//
// mapT / flatMapT / liftA2T map over the INNER type through
// BOTH layers. Operators: <£^> (fn left), <&^> (value left).
// ============================================================

// MARK: - OptionalTArray  ([A]?)

func learnOptionalTArray() {
    let opt: [Int]?  = .some([1, 2, 3])
    let none: [Int]? = .none

    // mapT — map over inner Array elements, through the Optional
    print(opt.mapT { $0 * 2 } as Any)                       // Optional([2, 4, 6])
    print(none.mapT { $0 * 2 } as Any)                      // nil

    // fmapT (curried)
    print(Optional<[Int]>.fmapT { $0 * 2 }(opt) as Any)     // Optional([2, 4, 6])

    // Operators
    print(({ $0 * 2 } <£^> opt) as Any)                     // Optional([2, 4, 6])
    print((opt <&^> { $0 * 2 }) as Any)                     // Optional([2, 4, 6])

    // Compare with regular fmap (maps over the Array, not its elements)
    print(({ arr in arr.count } <£> opt) as Any)             // Optional(3) — not element-wise

    // flatMapT — each element maps to optional list; nil collapses all
    print(opt.flatMapT { n -> [Int]? in .some([n, n * 10]) } as Any)
    // Optional([1, 10, 2, 20, 3, 30])
    print(opt.flatMapT { n -> [Int]? in n > 1 ? .some([n]) : .none } as Any)
    // nil — first element returned nil, collapses everything

    // liftA2T — cartesian product through Optional
    let opt2: [Int]? = .some([10, 20])
    print(Optional<[Int]>.liftA2T(+)(opt, opt2) as Any)     // Optional([11, 21, 12, 22, 13, 23])
    print(Optional<[Int]>.liftA2T(+)(none, opt2) as Any)    // nil
}
// learnOptionalTArray()

// MARK: - OptionalTResult  (Result<E, A>?)

func learnOptionalTResult() {
    let opt: Result<String, Int>?  = .some(.success(5))
    let fail: Result<String, Int>? = .some(.failure("err"))
    let none: Result<String, Int>? = .none

    // mapT — map over Success through Optional and Result
    print(opt.mapT  { $0 * 2 } as Any)                      // Optional(success(10))
    print(fail.mapT { $0 * 2 } as Any)                      // Optional(failure("err"))
    print(none.mapT { $0 * 2 } as Any)                      // nil

    print(({ $0 * 2 } <£^> opt) as Any)                     // Optional(success(10))
    print((opt <&^> { $0 * 2 }) as Any)                     // Optional(success(10))
}
// learnOptionalTResult()

// MARK: - EitherTArray  (Either<L, [A]>)

func learnEitherTArray() {
    let right: Either<String, [Int]> = .right([1, 2, 3])
    let left:  Either<String, [Int]> = .left("error")

    // mapT — map over inner elements through Either
    print(mapTEitherArray({ $0 * 2 }, right))                // right([2, 4, 6])
    print(mapTEitherArray({ $0 * 2 }, left))                 // left("error")

    // fmapT (curried)
    print(fmapTEitherArray({ $0 * 2 })(right))               // right([2, 4, 6])

    // Operators
    print({ $0 * 2 } <£^> right)                             // right([2, 4, 6])
    print(right <&^> { $0 * 2 })                             // right([2, 4, 6])

    // flatMapT
    print(right.flatMapT { n -> Either<String, [Int]> in .right([n, n * 10]) })
    // right([1, 10, 2, 20, 3, 30])
    print(right.flatMapT { n -> Either<String, [Int]> in n > 1 ? .right([n]) : .left("too small") })
    // left("too small") — first element triggered the left
}
// learnEitherTArray()

// MARK: - DeferredTaskTEither  (DeferredTask<Either<L, A>>)

func learnDeferredTaskTEither() {
    let taskRight: DeferredTask<Either<String, Int>> = DeferredTask { .right(42) }
    let taskLeft:  DeferredTask<Either<String, Int>> = DeferredTask { .left("not found") }

    // mapT — transform the success value inside the async Either
    let mapped = taskRight.mapT { $0 * 2 }                   // still lazy
    let withOp = { $0 * 2 } <£^> taskRight

    Task {
        print(await mapped.run())                             // right(84)
        print(await withOp.run())                            // right(84)
        print(await taskLeft.mapT { $0 * 2 }.run())         // left("not found")
    }

    // flatMapT — chain async-failable steps
    let chained = taskRight.flatMapT { n in
        DeferredTask { n > 0 ? Either<String, Int>.right(n + 1) : .left("non-positive") }
    }

    Task {
        print(await chained.run())                            // right(43)
    }
}
// learnDeferredTaskTEither()

// MARK: - ArrayTOptional  ([A?])

func learnArrayTOptional() {
    let arr: [Int?] = [.some(1), .none, .some(3)]

    // mapT — map over present values, nil stays nil
    print(arr.mapT { $0 * 2 })                               // [Optional(2), nil, Optional(6)]

    print({ $0 * 2 } <£^> arr)                               // [Optional(2), nil, Optional(6)]
    print(arr <&^> { $0 * 2 })                               // [Optional(2), nil, Optional(6)]
}
// learnArrayTOptional()

//: [Previous](@previous) | [Next](@next)
