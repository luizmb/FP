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

func optionalTArray() {
    let opt: [Int]?  = .some([1, 2, 3])
    let none: [Int]? = .none

    // mapT — map over inner Array elements, through the Optional
    opt.mapT { $0 * 2 } as Any    // Optional([2, 4, 6])
    none.mapT { $0 * 2 } as Any   // nil

    // fmapT (curried)
    Optional<[Int]>.fmapT { $0 * 2 }(opt) as Any   // Optional([2, 4, 6])

    // Operators
    ({ $0 * 2 } <£^> opt) as Any                    // Optional([2, 4, 6])
    (opt <&^> { $0 * 2 }) as Any                    // Optional([2, 4, 6])

    // Compare with regular fmap (maps over the Array, not its elements)
    ({ arr in arr.count } <£> opt) as Any            // Optional(3) — not element-wise

    // flatMapT — each element maps to optional list; nil collapses all
    opt.flatMapT { n -> [Int]? in .some([n, n * 10]) } as Any
    // Optional([1, 10, 2, 20, 3, 30])
    opt.flatMapT { n -> [Int]? in n > 1 ? .some([n]) : .none } as Any
    // nil — first element returned nil, collapses everything

    // liftA2T — cartesian product through Optional
    let opt2: [Int]? = .some([10, 20])
    Optional<[Int]>.liftA2T(+)(opt, opt2) as Any    // Optional([11, 21, 12, 22, 13, 23])
    Optional<[Int]>.liftA2T(+)(none, opt2) as Any   // nil
}
// learn(optionalTArray)

// MARK: - OptionalTResult  (Result<E, A>?)

func optionalTResult() {
    let opt:  Result<Int, AnyError>? = .some(.success(5))
    let fail: Result<Int, AnyError>? = .some(.failure(AnyError("err")))
    let none: Result<Int, AnyError>? = .none

    // mapT — map over Success through Optional and Result
    opt.mapT  { $0 * 2 } as Any   // Optional(success(10))
    fail.mapT { $0 * 2 } as Any   // Optional(failure(AnyError("err")))
    none.mapT { $0 * 2 } as Any   // nil

    ({ $0 * 2 } <£^> opt) as Any  // Optional(success(10))
    (opt <&^> { $0 * 2 }) as Any  // Optional(success(10))
}
// learn(optionalTResult)

// MARK: - EitherTArray  (Either<L, [A]>)

func eitherTArray() {
    let right: Either<String, [Int]> = .right([1, 2, 3])
    let left:  Either<String, [Int]> = .left("error")

    // mapT — map over inner elements through Either
    mapTEitherArray({ $0 * 2 }, right)    // right([2, 4, 6])
    mapTEitherArray({ $0 * 2 }, left)     // left("error")

    // fmapT (curried)
    fmapTEitherArray({ $0 * 2 })(right)   // right([2, 4, 6])

    // Operators
    _ = { $0 * 2 } <£^> right             // right([2, 4, 6])
    right <&^> { $0 * 2 }                 // right([2, 4, 6])

    // flatMapT
    right.flatMapT { n -> Either<String, [Int]> in .right([n, n * 10]) }
    // right([1, 10, 2, 20, 3, 30])
    right.flatMapT { n -> Either<String, [Int]> in n > 1 ? .right([n]) : .left("too small") }
    // left("too small") — first element triggered the left
}
// learn(eitherTArray)

// MARK: - DeferredTaskTEither  (DeferredTask<Either<L, A>>)

func deferredTaskTEither() async {
    let taskRight: DeferredTask<Either<String, Int>> = DeferredTask { .right(42) }
    let taskLeft:  DeferredTask<Either<String, Int>> = DeferredTask { .left("not found") }

    // mapT — transform the success value inside the async Either
    let mapped = taskRight.mapT { $0 * 2 }                   // still lazy
    let withOp = { $0 * 2 } <£^> taskRight

    await mapped.run()                              // right(84)
    await withOp.run()                              // right(84)
    await taskLeft.mapT { $0 * 2 }.run()           // left("not found")

    // flatMapT — chain async-failable steps
    let chained = taskRight.flatMapT { n in
        DeferredTask { n > 0 ? Either<String, Int>.right(n + 1) : .left("non-positive") }
    }

    await chained.run()   // right(43)
}
// learn(deferredTaskTEither)

// MARK: - ArrayTOptional  ([A?])

func arrayTOptional() {
    let arr: [Int?] = [.some(1), .none, .some(3)]

    // mapT — map over present values, nil stays nil
    arr.mapT { $0 * 2 }      // [Optional(2), nil, Optional(6)]

    _ = { $0 * 2 } <£^> arr  // [Optional(2), nil, Optional(6)]
    arr <&^> { $0 * 2 }      // [Optional(2), nil, Optional(6)]
}
// learn(arrayTOptional)

//: [Previous](@previous) | [Next](@next)
