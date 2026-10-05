// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// Laws for the data-outer newtype stacks, checked on the struct API only.
// Functor identity/composition for every stack; for `MonadT` stacks `<*>` equals the bind-derived `ap`
// plus the three monad laws; for applicative-only stacks applicative identity and homomorphism.
// Each stack also checks its lifting property and its escape hatch.

private enum Boom: Error, Equatable {
    case boom
}

private let inc: @Sendable (Int) -> Int = { $0 + 1 }
private let dbl: @Sendable (Int) -> Int = { $0 * 2 }

/// Runs a counter `Stateful` from state `1`, observing `[value, finalState]`.
private func runAt1(_ stateful: Stateful<Int, Int>) -> [Int] {
    [stateful.eval(1), stateful.exec(1)]
}

private let tick = Stateful<Int, Int> { state in
    state += 1
    return state * 10
}

private func checkFunctor<T, R: Equatable>(
    _ samples: [T],
    map: (T, @escaping @Sendable (Int) -> Int) -> T,
    observe: (T) -> R,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for sample in samples {
        #expect(observe(map(sample) { $0 }) == observe(sample), sourceLocation: sourceLocation)
        #expect(observe(map(map(sample, inc), dbl)) == observe(map(sample) { dbl(inc($0)) }), sourceLocation: sourceLocation)
    }
}

private func checkMonad<T, R: Equatable>(
    _ samples: [T],
    arrows: (pure: @Sendable (Int) -> T, f: @Sendable (Int) -> T, g: @Sendable (Int) -> T),
    flatMap: @escaping @Sendable (T, @escaping @Sendable (Int) -> T) -> T,
    kleisli: (@escaping @Sendable (Int) -> T, @escaping @Sendable (Int) -> T) -> @Sendable (Int) -> T,
    observe: (T) -> R,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    let (pure, f, g) = arrows
    for value in [0, 3] {
        #expect(observe(flatMap(pure(value), f)) == observe(f(value)), sourceLocation: sourceLocation)
    }
    for sample in samples {
        #expect(observe(flatMap(sample, pure)) == observe(sample), sourceLocation: sourceLocation)
        let lhs = flatMap(flatMap(sample, f), g)
        #expect(observe(lhs) == observe(flatMap(sample, kleisli(f, g))), sourceLocation: sourceLocation)
    }
}

private func checkApEqualsBind<T, TF, R: Equatable>(
    _ fns: [TF],
    _ samples: [T],
    apply: (TF, T) -> T,
    derived: (TF, T) -> T,
    observe: (T) -> R,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for fn in fns {
        for sample in samples {
            #expect(observe(apply(fn, sample)) == observe(derived(fn, sample)), sourceLocation: sourceLocation)
        }
    }
}

private func checkApplicative<T, TF, R: Equatable>(
    _ samples: [T],
    pure: (Int) -> T,
    pureFn: (@escaping @Sendable (Int) -> Int) -> TF,
    apply: (TF, T) -> T,
    observe: (T) -> R,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    for sample in samples {
        #expect(observe(apply(pureFn { $0 }, sample)) == observe(sample), sourceLocation: sourceLocation)
    }
    #expect(observe(apply(pureFn(inc), pure(4))) == observe(pure(5)), sourceLocation: sourceLocation)
}

@Suite struct DataOuterStackLawTests {
    // MARK: - ArrayTEither

    @Test func arrayTEitherLaws() {
        typealias Stack = ArrayTEither<String, Int>
        let nested: [Either<String, Int>] = [.right(1), .left("e"), .right(2)]
        let samples = [nested.arrayT, Stack([])]
        let f: @Sendable (Int) -> Stack = { Stack([.right($0), .left("f")]) }
        let g: @Sendable (Int) -> Stack = { Stack([.right($0 + 1)]) }
        let fns = [ArrayTEither<String, @Sendable (Int) -> Int>([.right(inc), .left("nf"), .right(dbl)])]

        #expect(nested.arrayT.rawValue == nested)
        let escaped: Stack = nested.arrayT.mapExceptT { $0 + [.left("x")] }
        #expect(escaped.rawValue == nested + [.left("x")])
        checkFunctor(samples, map: { $0.map($1) }, observe: \.rawValue)
        checkApEqualsBind(fns, samples, apply: Stack.apply, derived: { ff, fa in ff.flatMap { fa.map($0) } }, observe: \.rawValue)
        checkMonad(samples, arrows: (Stack.pure, f, g), flatMap: { $0.flatMap($1) }, kleisli: Stack.kleisli, observe: \.rawValue)
    }

    // MARK: - ArrayTStateful

    @Test func arrayTStatefulLaws() {
        typealias Stack = ArrayTStateful<Int, Int>
        let nested = [tick, Stateful<Int, Int>.pure(7)]
        let samples = [nested.arrayT, Stack([])]
        let observe: (Stack) -> [[Int]] = { $0.rawValue.map(runAt1) }

        #expect(nested.arrayT.rawValue.map(runAt1) == nested.map(runAt1))
        let escaped: Stack = nested.arrayT.mapArrayT { Array($0.prefix(1)) }
        #expect(observe(escaped) == [[20, 2]])
        checkFunctor(samples, map: { $0.map($1) }, observe: observe)
        checkApplicative(
            samples,
            pure: Stack.pure,
            pureFn: ArrayTStateful<Int, @Sendable (Int) -> Int>.pure,
            apply: Stack.apply,
            observe: observe
        )
    }

    // MARK: - ArrayTWriter

    @Test func arrayTWriterLaws() {
        typealias Stack = ArrayTWriter<[String], Int>
        let nested = [Writer(1, ["a"]), Writer(2, ["b"])]
        let samples = [nested.arrayT, Stack([])]
        let f: @Sendable (Int) -> Stack = { Stack([Writer($0, ["f"]), Writer($0 + 1, ["f'"])]) }
        let g: @Sendable (Int) -> Stack = { Stack([Writer($0 * 10, ["g"])]) }
        let fns = [ArrayTWriter<[String], @Sendable (Int) -> Int>([Writer(inc, ["inc"]), Writer(dbl, ["dbl"])])]

        #expect(nested.arrayT.rawValue == nested)
        let escaped: Stack = nested.arrayT.mapWriterT { $0.reversed() }
        #expect(escaped.rawValue == nested.reversed())
        checkFunctor(samples, map: { $0.map($1) }, observe: \.rawValue)
        checkApEqualsBind(fns, samples, apply: Stack.apply, derived: { ff, fa in ff.flatMap { fa.map($0) } }, observe: \.rawValue)
        checkMonad(samples, arrows: (Stack.pure, f, g), flatMap: { $0.flatMap($1) }, kleisli: Stack.kleisli, observe: \.rawValue)
    }

    // MARK: - EitherTArray

    @Test func eitherTArrayLaws() {
        typealias Stack = EitherTArray<String, Int>
        let nested: Either<String, [Int]> = .right([1, 2])
        let samples = [nested.eitherT, Stack(.left("e")), Stack(.right([]))]

        #expect(nested.eitherT.rawValue == nested)
        let escaped: Stack = nested.eitherT.mapEitherT { $0.mapRight { $0 + [9] } }
        #expect(escaped.rawValue == .right([1, 2, 9]))
        checkFunctor(samples, map: { $0.map($1) }, observe: \.rawValue)
        checkApplicative(
            samples,
            pure: Stack.pure,
            pureFn: EitherTArray<String, @Sendable (Int) -> Int>.pure,
            apply: Stack.apply,
            observe: \.rawValue
        )
    }

    // MARK: - EitherTNonEmpty

    @Test func eitherTNonEmptyLaws() {
        typealias Stack = EitherTNonEmpty<String, Int>
        let nested: Either<String, NonEmpty<Int>> = .right(NonEmpty(head: 1, tail: [2]))
        let samples = [nested.eitherT, Stack(.left("e"))]

        #expect(nested.eitherT.rawValue == nested)
        let escaped: Stack = nested.eitherT.mapEitherT { $0.mapRight { NonEmpty(head: $0.head) } }
        #expect(escaped.rawValue == .right(NonEmpty(head: 1)))
        checkFunctor(samples, map: { $0.map($1) }, observe: \.rawValue)
        checkApplicative(
            samples,
            pure: Stack.pure,
            pureFn: EitherTNonEmpty<String, @Sendable (Int) -> Int>.pure,
            apply: Stack.apply,
            observe: \.rawValue
        )
    }

    // MARK: - EitherTOptional

    @Test func eitherTOptionalLaws() {
        typealias Stack = EitherTOptional<String, Int>
        let nested: Either<String, Int?> = .right(1)
        let samples = [nested.eitherT, Stack(.right(nil)), Stack(.left("e"))]
        let f: @Sendable (Int) -> Stack = { Stack($0.isMultiple(of: 2) ? .right(nil) : .right($0 * 2)) }
        let g: @Sendable (Int) -> Stack = { Stack($0 > 1 ? .left("big") : .right($0)) }
        let fns = [EitherTOptional<String, @Sendable (Int) -> Int>(.right(inc)), EitherTOptional(.right(nil)), EitherTOptional(.left("nf"))]

        #expect(nested.eitherT.rawValue == nested)
        let escaped: Stack = nested.eitherT.mapMaybeT(const(Stack.O.left("gone")))
        #expect(escaped.rawValue == .left("gone"))
        checkFunctor(samples, map: { $0.map($1) }, observe: \.rawValue)
        checkApEqualsBind(fns, samples, apply: Stack.apply, derived: { ff, fa in ff.flatMap { fa.map($0) } }, observe: \.rawValue)
        checkMonad(samples, arrows: (Stack.pure, f, g), flatMap: { $0.flatMap($1) }, kleisli: Stack.kleisli, observe: \.rawValue)
    }

    // MARK: - EitherTResult

    @Test func eitherTResultLaws() {
        typealias Stack = EitherTResult<String, Boom, Int>
        let nested: Either<String, Result<Int, Boom>> = .right(.success(1))
        let samples = [nested.eitherT, Stack(.right(.failure(.boom))), Stack(.left("e"))]
        let f: @Sendable (Int) -> Stack = { Stack($0.isMultiple(of: 2) ? .right(.failure(.boom)) : .right(.success($0 * 2))) }
        let g: @Sendable (Int) -> Stack = { Stack($0 > 1 ? .left("big") : .right(.success($0))) }
        let fns = [
            EitherTResult<String, Boom, @Sendable (Int) -> Int>(.right(.success(inc))),
            EitherTResult(.right(.failure(.boom))),
            EitherTResult(.left("nf"))
        ]

        #expect(nested.eitherT.rawValue == nested)
        let escaped: Stack = nested.eitherT.mapExceptT(const(Stack.O.left("gone")))
        #expect(escaped.rawValue == .left("gone"))
        checkFunctor(samples, map: { $0.map($1) }, observe: \.rawValue)
        checkApEqualsBind(fns, samples, apply: Stack.apply, derived: { ff, fa in ff.flatMap { fa.map($0) } }, observe: \.rawValue)
        checkMonad(samples, arrows: (Stack.pure, f, g), flatMap: { $0.flatMap($1) }, kleisli: Stack.kleisli, observe: \.rawValue)
    }

    // MARK: - EitherTStateful

    @Test func eitherTStatefulLaws() {
        typealias Stack = EitherTStateful<String, Int, Int>
        let nested: Either<String, Stateful<Int, Int>> = .right(tick)
        let samples = [nested.eitherT, Stack(.left("e"))]
        let observe: (Stack) -> Either<String, [Int]> = { $0.rawValue.mapRight(runAt1) }

        #expect(observe(nested.eitherT) == .right([20, 2]))
        let escaped: Stack = nested.eitherT.mapEitherT(const(Stack.O.left("gone")))
        #expect(observe(escaped) == .left("gone"))
        checkFunctor(samples, map: { $0.map($1) }, observe: observe)
        checkApplicative(
            samples,
            pure: Stack.pure,
            pureFn: EitherTStateful<String, Int, @Sendable (Int) -> Int>.pure,
            apply: Stack.apply,
            observe: observe
        )
    }

    // MARK: - EitherTValidation

    @Test func eitherTValidationLaws() {
        typealias Stack = EitherTValidation<String, [String], Int>
        let nested: Either<String, Validation<[String], Int>> = .right(.success(1))
        let samples = [nested.eitherT, Stack(.right(.failure(["v"]))), Stack(.left("e"))]

        #expect(nested.eitherT.rawValue == nested)
        let escaped: Stack = nested.eitherT.mapEitherT(const(Stack.O.left("gone")))
        #expect(escaped.rawValue == .left("gone"))
        checkFunctor(samples, map: { $0.map($1) }, observe: \.rawValue)
        checkApplicative(
            samples,
            pure: Stack.pure,
            pureFn: EitherTValidation<String, [String], @Sendable (Int) -> Int>.pure,
            apply: Stack.apply,
            observe: \.rawValue
        )
    }

    // MARK: - EitherTWriter

    @Test func eitherTWriterLaws() {
        typealias Stack = EitherTWriter<String, [String], Int>
        let nested: Either<String, Writer<[String], Int>> = .right(Writer(1, ["a"]))
        let samples = [nested.eitherT, Stack(.left("e"))]
        let f: @Sendable (Int) -> Stack = { Stack(.right(Writer($0 * 2, ["f"]))) }
        let g: @Sendable (Int) -> Stack = { Stack($0 > 2 ? .left("big") : .right(Writer($0, ["g"]))) }
        let fns = [EitherTWriter<String, [String], @Sendable (Int) -> Int>(.right(Writer(inc, ["inc"]))), EitherTWriter(.left("nf"))]

        #expect(nested.eitherT.rawValue == nested)
        let escaped: Stack = nested.eitherT.mapWriterT(const(Stack.O.left("gone")))
        #expect(escaped.rawValue == .left("gone"))
        checkFunctor(samples, map: { $0.map($1) }, observe: \.rawValue)
        checkApEqualsBind(fns, samples, apply: Stack.apply, derived: { ff, fa in ff.flatMap { fa.map($0) } }, observe: \.rawValue)
        checkMonad(samples, arrows: (Stack.pure, f, g), flatMap: { $0.flatMap($1) }, kleisli: Stack.kleisli, observe: \.rawValue)
    }

    // MARK: - NonEmptyTEither

    @Test func nonEmptyTEitherLaws() {
        typealias Stack = NonEmptyTEither<String, Int>
        let nested = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.left("e"), .right(2)])
        let samples = [nested.nonEmptyT, Stack(NonEmpty(head: .left("only")))]
        let f: @Sendable (Int) -> Stack = { Stack(NonEmpty(head: .right($0), tail: [.left("f")])) }
        let g: @Sendable (Int) -> Stack = { Stack(NonEmpty(head: .right($0 + 1))) }
        let fns = [NonEmptyTEither<String, @Sendable (Int) -> Int>(NonEmpty(head: .right(inc), tail: [.left("nf"), .right(dbl)]))]

        #expect(nested.nonEmptyT.rawValue == nested)
        let escaped: Stack = nested.nonEmptyT.mapExceptT { NonEmpty(head: $0.head) }
        #expect(escaped.rawValue == NonEmpty(head: .right(1)))
        checkFunctor(samples, map: { $0.map($1) }, observe: \.rawValue)
        checkApEqualsBind(fns, samples, apply: Stack.apply, derived: { ff, fa in ff.flatMap { fa.map($0) } }, observe: \.rawValue)
        checkMonad(samples, arrows: (Stack.pure, f, g), flatMap: { $0.flatMap($1) }, kleisli: Stack.kleisli, observe: \.rawValue)
    }

    // MARK: - NonEmptyTOptional

    @Test func nonEmptyTOptionalLaws() {
        typealias Stack = NonEmptyTOptional<Int>
        let nested = NonEmpty<Int?>(head: 1, tail: [nil, 2])
        let samples = [nested.nonEmptyT, Stack(NonEmpty(head: nil))]
        let f: @Sendable (Int) -> Stack = { Stack(NonEmpty(head: $0, tail: [nil])) }
        let g: @Sendable (Int) -> Stack = { Stack(NonEmpty(head: $0 + 1)) }
        let fns = [NonEmptyTOptional<@Sendable (Int) -> Int>(NonEmpty(head: inc, tail: [nil, dbl]))]

        #expect(nested.nonEmptyT.rawValue == nested)
        let escaped: Stack = nested.nonEmptyT.mapMaybeT { NonEmpty(head: $0.head) }
        #expect(escaped.rawValue == NonEmpty(head: 1))
        checkFunctor(samples, map: { $0.map($1) }, observe: \.rawValue)
        checkApEqualsBind(fns, samples, apply: Stack.apply, derived: { ff, fa in ff.flatMap { fa.map($0) } }, observe: \.rawValue)
        checkMonad(samples, arrows: (Stack.pure, f, g), flatMap: { $0.flatMap($1) }, kleisli: Stack.kleisli, observe: \.rawValue)
    }

    // MARK: - NonEmptyTResult

    @Test func nonEmptyTResultLaws() {
        typealias Stack = NonEmptyTResult<Boom, Int>
        let nested = NonEmpty<Result<Int, Boom>>(head: .success(1), tail: [.failure(.boom), .success(2)])
        let samples = [nested.nonEmptyT, Stack(NonEmpty(head: .failure(.boom)))]
        let f: @Sendable (Int) -> Stack = { Stack(NonEmpty(head: .success($0), tail: [.failure(.boom)])) }
        let g: @Sendable (Int) -> Stack = { Stack(NonEmpty(head: .success($0 + 1))) }
        let fns = [NonEmptyTResult<Boom, @Sendable (Int) -> Int>(NonEmpty(head: .success(inc), tail: [.failure(.boom), .success(dbl)]))]

        #expect(nested.nonEmptyT.rawValue == nested)
        let escaped: Stack = nested.nonEmptyT.mapExceptT { NonEmpty(head: $0.head) }
        #expect(escaped.rawValue == NonEmpty(head: .success(1)))
        checkFunctor(samples, map: { $0.map($1) }, observe: \.rawValue)
        checkApEqualsBind(fns, samples, apply: Stack.apply, derived: { ff, fa in ff.flatMap { fa.map($0) } }, observe: \.rawValue)
        checkMonad(samples, arrows: (Stack.pure, f, g), flatMap: { $0.flatMap($1) }, kleisli: Stack.kleisli, observe: \.rawValue)
    }

    // MARK: - OptionalTEither

    @Test func optionalTEitherLaws() {
        typealias Stack = OptionalTEither<String, Int>
        let nested: Either<String, Int>? = .right(1)
        let samples = [nested.optionalT, Stack(.left("e")), Stack(nil)]
        let f: @Sendable (Int) -> Stack = { Stack($0.isMultiple(of: 2) ? nil : .right($0 * 2)) }
        let g: @Sendable (Int) -> Stack = { Stack($0 > 1 ? .left("big") : .right($0)) }
        let fns = [OptionalTEither<String, @Sendable (Int) -> Int>(.right(inc)), OptionalTEither(.left("nf")), OptionalTEither(nil)]

        #expect(nested.optionalT.rawValue == nested)
        let escaped: Stack = nested.optionalT.mapExceptT(const(Stack.O.none))
        #expect(escaped.rawValue == nil)
        checkFunctor(samples, map: { $0.map($1) }, observe: \.rawValue)
        checkApEqualsBind(fns, samples, apply: Stack.apply, derived: { ff, fa in ff.flatMap { fa.map($0) } }, observe: \.rawValue)
        checkMonad(samples, arrows: (Stack.pure, f, g), flatMap: { $0.flatMap($1) }, kleisli: Stack.kleisli, observe: \.rawValue)
    }

    // MARK: - OptionalTNonEmpty

    @Test func optionalTNonEmptyLaws() {
        typealias Stack = OptionalTNonEmpty<Int>
        let nested: NonEmpty<Int>? = NonEmpty(head: 1, tail: [2])
        let samples = [nested.optionalT, Stack(nil)]
        let f: @Sendable (Int) -> Stack = { Stack($0 > 1 ? nil : NonEmpty(head: $0, tail: [$0 * 10])) }
        let g: @Sendable (Int) -> Stack = { Stack(NonEmpty(head: $0 + 1)) }
        let fns = [OptionalTNonEmpty<@Sendable (Int) -> Int>(NonEmpty(head: inc, tail: [dbl])), OptionalTNonEmpty(nil)]

        #expect(nested.optionalT.rawValue == nested)
        let escaped: Stack = nested.optionalT.mapOptionalT(const(Stack.O.none))
        #expect(escaped.rawValue == nil)
        checkFunctor(samples, map: { $0.map($1) }, observe: \.rawValue)
        checkApEqualsBind(fns, samples, apply: Stack.apply, derived: { ff, fa in ff.flatMap { fa.map($0) } }, observe: \.rawValue)
        checkMonad(samples, arrows: (Stack.pure, f, g), flatMap: { $0.flatMap($1) }, kleisli: Stack.kleisli, observe: \.rawValue)
    }

    // MARK: - OptionalTStateful

    @Test func optionalTStatefulLaws() {
        typealias Stack = OptionalTStateful<Int, Int>
        let nested: Stateful<Int, Int>? = tick
        let samples = [nested.optionalT, Stack(nil)]
        let observe: (Stack) -> [Int] = { $0.rawValue.map(runAt1) ?? [] }

        #expect(observe(nested.optionalT) == [20, 2])
        let escaped: Stack = nested.optionalT.mapOptionalT(const(Stack.O.none))
        #expect(observe(escaped).isEmpty)
        checkFunctor(samples, map: { $0.map($1) }, observe: observe)
        checkApplicative(
            samples,
            pure: Stack.pure,
            pureFn: OptionalTStateful<Int, @Sendable (Int) -> Int>.pure,
            apply: Stack.apply,
            observe: observe
        )
    }

    // MARK: - OptionalTWriter

    @Test func optionalTWriterLaws() {
        typealias Stack = OptionalTWriter<[String], Int>
        let nested: Writer<[String], Int>? = Writer(1, ["a"])
        let samples = [nested.optionalT, Stack(nil)]
        let f: @Sendable (Int) -> Stack = { Stack(Writer($0 * 2, ["f"])) }
        let g: @Sendable (Int) -> Stack = { Stack($0 > 2 ? nil : Writer($0, ["g"])) }
        let fns = [OptionalTWriter<[String], @Sendable (Int) -> Int>(Writer(inc, ["inc"])), OptionalTWriter(nil)]

        #expect(nested.optionalT.rawValue == nested)
        let escaped: Stack = nested.optionalT.mapWriterT(const(Stack.O.none))
        #expect(escaped.rawValue == nil)
        checkFunctor(samples, map: { $0.map($1) }, observe: \.rawValue)
        checkApEqualsBind(fns, samples, apply: Stack.apply, derived: { ff, fa in ff.flatMap { fa.map($0) } }, observe: \.rawValue)
        checkMonad(samples, arrows: (Stack.pure, f, g), flatMap: { $0.flatMap($1) }, kleisli: Stack.kleisli, observe: \.rawValue)
    }

    // MARK: - ResultTStateful

    @Test func resultTStatefulLaws() {
        typealias Stack = ResultTStateful<Boom, Int, Int>
        let nested: Result<Stateful<Int, Int>, Boom> = .success(tick)
        let samples = [nested.resultT, Stack(.failure(.boom))]
        let observe: (Stack) -> Result<[Int], Boom> = { $0.rawValue.map(runAt1) }

        #expect(observe(nested.resultT) == .success([20, 2]))
        let escaped: Stack = nested.resultT.mapResultT(const(Stack.O.failure(.boom)))
        #expect(observe(escaped) == .failure(.boom))
        checkFunctor(samples, map: { $0.map($1) }, observe: observe)
        checkApplicative(
            samples,
            pure: Stack.pure,
            pureFn: ResultTStateful<Boom, Int, @Sendable (Int) -> Int>.pure,
            apply: Stack.apply,
            observe: observe
        )
    }

    // MARK: - ResultTWriter

    @Test func resultTWriterLaws() {
        typealias Stack = ResultTWriter<Boom, [String], Int>
        let nested: Result<Writer<[String], Int>, Boom> = .success(Writer(1, ["a"]))
        let samples = [nested.resultT, Stack(.failure(.boom))]
        let f: @Sendable (Int) -> Stack = { Stack(.success(Writer($0 * 2, ["f"]))) }
        let g: @Sendable (Int) -> Stack = { Stack($0 > 2 ? .failure(.boom) : .success(Writer($0, ["g"]))) }
        let fns = [ResultTWriter<Boom, [String], @Sendable (Int) -> Int>(.success(Writer(inc, ["inc"]))), ResultTWriter(.failure(.boom))]

        #expect(nested.resultT.rawValue == nested)
        let escaped: Stack = nested.resultT.mapWriterT(const(Stack.O.failure(.boom)))
        #expect(escaped.rawValue == .failure(.boom))
        checkFunctor(samples, map: { $0.map($1) }, observe: \.rawValue)
        checkApEqualsBind(fns, samples, apply: Stack.apply, derived: { ff, fa in ff.flatMap { fa.map($0) } }, observe: \.rawValue)
        checkMonad(samples, arrows: (Stack.pure, f, g), flatMap: { $0.flatMap($1) }, kleisli: Stack.kleisli, observe: \.rawValue)
    }
}
