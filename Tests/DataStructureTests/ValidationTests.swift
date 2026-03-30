import DataStructure
import Testing

@Suite struct ValidationTests {
    // MARK: - Construction

    @Test func failureConstruction() {
        let v: Validation<String, Int> = .failure("error")
        v.match(
            caseFailure: { #expect($0 == "error") },
            caseSuccess: { _ in Issue.record("Expected failure") }
        )
    }

    @Test func successConstruction() {
        let v: Validation<String, Int> = .success(42)
        v.match(
            caseFailure: { _ in Issue.record("Expected success") },
            caseSuccess: { #expect($0 == 42) }
        )
    }

    // MARK: - Functor

    @Test func fmapSuccess() {
        let v: Validation<String, Int> = .success(5)
        let result = Validation<String, Int>.fmap({ $0 * 2 })(v)
        #expect(result == .success(10))
    }

    @Test func fmapFailure() {
        let v: Validation<String, Int> = .failure("err")
        let result = Validation<String, Int>.fmap({ $0 * 2 })(v)
        #expect(result == .failure("err"))
    }

    @Test func mapSuccess() {
        let v: Validation<String, Int> = .success(3)
        #expect(v.mapSuccess { $0 + 1 } == .success(4))
    }

    @Test func mapFailure() {
        let v: Validation<String, Int> = .failure("err")
        #expect(v.mapFailure { [$0] } == .failure(["err"]))
    }

    @Test func bimapSuccess() {
        let v: Validation<String, Int> = .success(3)
        #expect(v.bimap({ $0.uppercased() }, { $0 * 2 }) == .success(6))
    }

    @Test func bimapFailure() {
        let v: Validation<String, Int> = .failure("err")
        #expect(v.bimap({ $0.uppercased() }, { $0 * 2 }) == .failure("ERR"))
    }

    @Test func bimapCurried() {
        let transform = Validation<String, Int>.bimap({ $0.uppercased() }, { $0 * 2 })
        #expect(transform(.success(5)) == .success(10))
        #expect(transform(.failure("err")) == .failure("ERR"))
    }

    @Test func bimapPointFree() {
        let values: [Validation<String, Int>] = [.success(4), .failure("x"), .success(1)]
        let result = values.map(Validation<String, Int>.bimap({ $0 + "!" }, { $0 + 10 }))
        #expect(result == [.success(14), .failure("x!"), .success(11)])
    }

    @Test func voidSuccess() {
        let v: Validation<String, Int> = .success(42)
        if case .failure = DataStructure.void(v) { Issue.record("Expected .success") }
    }

    @Test func voidFailure() {
        let v: Validation<String, Int> = .failure("err")
        if case .success = DataStructure.void(v) { Issue.record("Expected .failure") }
    }

    @Test func voidPreservesError() {
        let v: Validation<String, Int> = .failure("msg")
        v.void().match(
            caseFailure: { #expect($0 == "msg") },
            caseSuccess: { _ in Issue.record("Expected .failure") }
        )
    }

    // MARK: - Applicative — the key behaviour

    @Test func applySuccessSuccess() {
        let fns: Validation<[String], (Int) -> Int> = .success { $0 * 2 }
        let vals: Validation<[String], Int> = .success(5)
        #expect(Validation.apply(fns, vals) == .success(10))
    }

    @Test func applyFailureSuccess() {
        let fns: Validation<[String], (Int) -> Int> = .failure(["e1"])
        let vals: Validation<[String], Int> = .success(5)
        #expect(Validation.apply(fns, vals) == .failure(["e1"]))
    }

    @Test func applySuccessFailure() {
        let fns: Validation<[String], (Int) -> Int> = .success { $0 * 2 }
        let vals: Validation<[String], Int> = .failure(["e2"])
        #expect(Validation.apply(fns, vals) == .failure(["e2"]))
    }

    @Test func applyAccumulatesBothFailures() {
        // THE key test — both errors must be combined
        let fns: Validation<[String], (Int) -> Int> = .failure(["e1"])
        let vals: Validation<[String], Int> = .failure(["e2"])
        #expect(Validation.apply(fns, vals) == .failure(["e1", "e2"]))
    }

    @Test func liftA2AccumulatesErrors() {
        let v1: Validation<[String], Int> = .failure(["name too short"])
        let v2: Validation<[String], Int> = .failure(["age invalid"])
        let result = Validation<[String], String>.liftA2({ "\($0)-\($1)" })(v1, v2)
        #expect(result == .failure(["name too short", "age invalid"]))
    }

    @Test func seqRightAccumulatesErrors() {
        let lhs: Validation<[String], Int> = .failure(["e1"])
        let rhs: Validation<[String], String> = .failure(["e2"])
        #expect(lhs.seqRight(rhs) == .failure(["e1", "e2"]))
    }

    @Test func seqRightSuccessReturnsRight() {
        let lhs: Validation<[String], Int> = .success(1)
        let rhs: Validation<[String], String> = .success("ok")
        #expect(lhs.seqRight(rhs) == .success("ok"))
    }

    @Test func seqLeftAccumulatesErrors() {
        let lhs: Validation<[String], Int> = .failure(["e1"])
        let rhs: Validation<[String], String> = .failure(["e2"])
        #expect(lhs.seqLeft(rhs) == .failure(["e1", "e2"]))
    }

    @Test func seqLeftSuccessReturnsLeft() {
        let lhs: Validation<[String], Int> = .success(1)
        let rhs: Validation<[String], String> = .success("ok")
        #expect(lhs.seqLeft(rhs) == .success(1))
    }

    // MARK: - Zip

    // Tuples don't satisfy Equatable in generic positions, so use match to inspect results.

    @Test func zipBothSuccess() {
        let v1: Validation<[String], Int> = .success(1)
        let v2: Validation<[String], String> = .success("a")
        Validation<[String], (Int, String)>.zip(v1, v2).match(
            caseFailure: { _ in Issue.record("Expected success") },
            caseSuccess: { #expect($0 == (1, "a")) }
        )
    }

    @Test func zipFirstFailure() {
        let v1: Validation<[String], Int> = .failure(["e1"])
        let v2: Validation<[String], String> = .success("a")
        Validation<[String], (Int, String)>.zip(v1, v2).match(
            caseFailure: { #expect($0 == ["e1"]) },
            caseSuccess: { _ in Issue.record("Expected failure") }
        )
    }

    @Test func zipSecondFailure() {
        let v1: Validation<[String], Int> = .success(1)
        let v2: Validation<[String], String> = .failure(["e2"])
        Validation<[String], (Int, String)>.zip(v1, v2).match(
            caseFailure: { #expect($0 == ["e2"]) },
            caseSuccess: { _ in Issue.record("Expected failure") }
        )
    }

    @Test func zipAccumulatesBothFailures() {
        let v1: Validation<[String], Int> = .failure(["e1"])
        let v2: Validation<[String], String> = .failure(["e2"])
        Validation<[String], (Int, String)>.zip(v1, v2).match(
            caseFailure: { #expect($0 == ["e1", "e2"]) },
            caseSuccess: { _ in Issue.record("Expected failure") }
        )
    }

    @Test func zip3AllSuccess() {
        let v1: Validation<[String], Int> = .success(1)
        let v2: Validation<[String], String> = .success("a")
        let v3: Validation<[String], Bool> = .success(true)
        Validation<[String], (Int, String, Bool)>.zip3(v1, v2, v3).match(
            caseFailure: { _ in Issue.record("Expected success") },
            caseSuccess: { #expect($0 == (1, "a", true)) }
        )
    }

    @Test func zip3AccumulatesAllThreeFailures() {
        let v1: Validation<[String], Int> = .failure(["e1"])
        let v2: Validation<[String], String> = .failure(["e2"])
        let v3: Validation<[String], Bool> = .failure(["e3"])
        Validation<[String], (Int, String, Bool)>.zip3(v1, v2, v3).match(
            caseFailure: { #expect($0 == ["e1", "e2", "e3"]) },
            caseSuccess: { _ in Issue.record("Expected failure") }
        )
    }

    @Test func zip3AccumulatesPartialFailures() {
        // first and third fail, second succeeds — both errors must appear
        let v1: Validation<[String], Int> = .failure(["e1"])
        let v2: Validation<[String], String> = .success("ok")
        let v3: Validation<[String], Bool> = .failure(["e3"])
        Validation<[String], (Int, String, Bool)>.zip3(v1, v2, v3).match(
            caseFailure: { #expect($0 == ["e1", "e3"]) },
            caseSuccess: { _ in Issue.record("Expected failure") }
        )
    }

    @Test func zip4AllSuccess() {
        let v1: Validation<[String], Int> = .success(1)
        let v2: Validation<[String], String> = .success("a")
        let v3: Validation<[String], Bool> = .success(true)
        let v4: Validation<[String], Double> = .success(3.14)
        Validation<[String], (Int, String, Bool, Double)>.zip4(v1, v2, v3, v4).match(
            caseFailure: { _ in Issue.record("Expected success") },
            caseSuccess: { #expect($0 == (1, "a", true, 3.14)) }
        )
    }

    @Test func zip4AccumulatesAllFourFailures() {
        let v1: Validation<[String], Int> = .failure(["e1"])
        let v2: Validation<[String], String> = .failure(["e2"])
        let v3: Validation<[String], Bool> = .failure(["e3"])
        let v4: Validation<[String], Double> = .failure(["e4"])
        Validation<[String], (Int, String, Bool, Double)>.zip4(v1, v2, v3, v4).match(
            caseFailure: { #expect($0 == ["e1", "e2", "e3", "e4"]) },
            caseSuccess: { _ in Issue.record("Expected failure") }
        )
    }

    // MARK: - Prism

    @Test func prismSuccess() {
        let v: Validation<String, Int> = .success(42)
        #expect(v.success == 42)
        #expect(v.failure == nil)
        #expect(v.isSuccess)
        #expect(!v.isFailure)
    }

    @Test func prismFailure() {
        let v: Validation<String, Int> = .failure("err")
        #expect(v.failure == "err")
        #expect(v.success == nil)
        #expect(v.isFailure)
        #expect(!v.isSuccess)
    }

    // MARK: - Either conversion

    @Test func toEitherSuccess() {
        let v: Validation<String, Int> = .success(42)
        #expect(v.toEither() == .right(42))
    }

    @Test func toEitherFailure() {
        let v: Validation<String, Int> = .failure("err")
        #expect(v.toEither() == .left("err"))
    }

    @Test func fromEither() {
        let e: Either<String, Int> = .right(10)
        let v = validationFromEither(e)
        #expect(v == .success(10))

        let e2: Either<String, Int> = .left("oops")
        let v2 = validationFromEither(e2)
        #expect(v2 == .failure("oops"))
    }

    // MARK: - Transformer: ValidationTOptional

    @Test func validationTOptionalFunctor() {
        let v: Validation<[String], Int?> = .success(.some(5))
        let result = fmapTValidationOptional({ $0 * 2 })(v)
        #expect(result == .success(.some(10)))
    }

    @Test func validationTOptionalApplyBothFailures() {
        let vf: Validation<[String], ((Int) -> Int)?> = .failure(["e1"])
        let va: Validation<[String], Int?> = .failure(["e2"])
        #expect(applyValidationOptional(vf, va) == .failure(["e1", "e2"]))
    }

    // MARK: - Transformer: ValidationTArray

    @Test func validationTArrayFunctor() {
        let v: Validation<[String], [Int]> = .success([1, 2, 3])
        let result = fmapTValidationArray({ $0 * 2 })(v)
        #expect(result == .success([2, 4, 6]))
    }

    @Test func validationTArrayApplyAccumulatesErrors() {
        let vf: Validation<[String], [(Int) -> Int]> = .failure(["e1"])
        let va: Validation<[String], [Int]> = .failure(["e2"])
        #expect(applyValidationArray(vf, va) == .failure(["e1", "e2"]))
    }

    // MARK: - Transformer: EitherTValidation

    @Test func eitherTValidationFunctorRight() {
        let e: Either<String, Validation<[Int], Int>> = .right(.success(5))
        let result = fmapTEitherValidation({ $0 * 2 }, e)
        #expect(result == .right(.success(10)))
    }

    @Test func eitherTValidationApplyAccumulatesInner() {
        // Either is right on both sides — Validation accumulates inner errors
        let ef: Either<String, Validation<[Int], (Int) -> Int>> = .right(.failure([1]))
        let ea: Either<String, Validation<[Int], Int>> = .right(.failure([2]))
        #expect(applyEitherValidation(ef, ea) == .right(.failure([1, 2])))
    }

    @Test func eitherTValidationApplyShortCircuitsOnEitherLeft() {
        let ef: Either<String, Validation<[Int], (Int) -> Int>> = .left("outer err")
        let ea: Either<String, Validation<[Int], Int>> = .right(.failure([2]))
        #expect(applyEitherValidation(ef, ea) == .left("outer err"))
    }

    @Test func eitherTValidationFlatMapTSuccess() {
        let e: Either<String, Validation<[Int], Int>> = .right(.success(5))
        let result = flatMapTEitherValidation(e) { n in
            .right(.success(n * 2))
        }
        #expect(result == .right(.success(10)))
    }

    @Test func eitherTValidationFlatMapTFailure() {
        let e: Either<String, Validation<[Int], Int>> = .right(.failure([42]))
        let result = flatMapTEitherValidation(e) { n in
            Either<String, Validation<[Int], Int>>.right(.success(n * 2))
        }
        #expect(result == .right(.failure([42])))
    }

    // MARK: - Transformer: WriterTValidation

    @Test func writerTValidationApplyAccumulatesLogsAndErrors() {
        let wf = Writer<[String], Validation<[Int], (Int) -> Int>>(.failure([1]), ["log1"])
        let wa = Writer<[String], Validation<[Int], Int>>(.failure([2]), ["log2"])
        let result = applyWriterValidation(wf, wa)
        #expect(result.value == .failure([1, 2]))
        #expect(result.log == ["log1", "log2"])
    }

    @Test func writerTValidationFlatMapTSuccess() {
        let w = Writer<[String], Validation<[Int], Int>>(.success(3), ["outer"])
        let result = w.flatMapT { n in Writer<[String], Validation<[Int], String>>(.success("\(n)"), ["inner"]) }
        #expect(result.value == .success("3"))
        #expect(result.log == ["outer", "inner"])
    }

    @Test func writerTValidationFlatMapTFailure() {
        let w = Writer<[String], Validation<[Int], Int>>(.failure([9]), ["outer"])
        let result = w.flatMapT { n in Writer<[String], Validation<[Int], String>>(.success("\(n)"), ["inner"]) }
        #expect(result.value == .failure([9]))
        #expect(result.log == ["outer"])
    }

    // MARK: - Transformer: StatefulTValidation

    @Test func statefulTValidationApplyAccumulatesErrors() {
        let sf = Stateful<Int, Validation<[String], (Int) -> Int>> { _ in .failure(["e1"]) }
        let sa = Stateful<Int, Validation<[String], Int>> { _ in .failure(["e2"]) }
        var state = 0
        let result = applyStatefulValidation(sf, sa).run(&state)
        #expect(result == .failure(["e1", "e2"]))
    }

    @Test func statefulTValidationFlatMapTSuccess() {
        let stateful = Stateful<Int, Validation<[String], Int>> { s in
            s += 1
            return .success(s)
        }
        let result = flatMapTStatefulValidation(stateful) { n in
            Stateful<Int, Validation<[String], String>> { s in
                s += 10
                return .success("\(n + s)")
            }
        }
        var state = 0
        let value = result.run(&state)
        #expect(value == .success("12"))
        #expect(state == 11)
    }

    // MARK: - Transformer: ReaderTValidation

    @Test func readerTValidationApplyAccumulatesErrors() {
        let rf = Reader<String, Validation<[Int], (Int) -> Int>> { _ in .failure([1]) }
        let ra = Reader<String, Validation<[Int], Int>> { _ in .failure([2]) }
        let result = applyReaderValidation(rf, ra)("env")
        #expect(result == .failure([1, 2]))
    }

    @Test func readerTValidationFlatMapTSuccess() {
        let reader = Reader<String, Validation<[Int], Int>> { env in .success(env.count) }
        let result = reader.flatMapT { n in
            Reader<String, Validation<[Int], String>> { _ in .success("count: \(n)") }
        }
        #expect(result("hello") == .success("count: 5"))
    }

    // MARK: - Alternative

    @Test func altSuccessIgnoresRhs() {
        let lhs: Validation<String, Int> = .success(1)
        let rhs: Validation<String, Int> = .success(2)
        #expect(Validation.alt(lhs, rhs) == .success(1))
    }

    @Test func altFailureFallsBackToRhs() {
        let lhs: Validation<String, Int> = .failure("err")
        let rhs: Validation<String, Int> = .success(42)
        #expect(Validation.alt(lhs, rhs) == .success(42))
    }

    @Test func altBothFailureReturnsRhs() {
        let lhs: Validation<String, Int> = .failure("first")
        let rhs: Validation<String, Int> = .failure("second")
        #expect(Validation.alt(lhs, rhs) == .failure("second"))
    }

    // MARK: - Foldable

    @Test func foldMapSuccess() {
        let v: Validation<String, Int> = .success(5)
        #expect(v.foldMap({ "\($0)" }) == "5")
    }

    @Test func foldMapFailureReturnsIdentity() {
        let v: Validation<String, Int> = .failure("err")
        #expect(v.foldMap({ "\($0)" }) == "")
    }

    @Test func foldMapCurried() {
        let fn = Validation<String, Int>.foldMap({ "\($0)" })
        #expect(fn(.success(3)) == "3")
        #expect(fn(.failure("x")) == "")
    }

    @Test func toListSuccess() {
        let v: Validation<String, Int> = .success(42)
        #expect(v.toList == [42])
    }

    @Test func toListFailure() {
        let v: Validation<String, Int> = .failure("err")
        #expect(v.toList == [])
    }
}
