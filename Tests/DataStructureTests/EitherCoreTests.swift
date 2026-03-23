import DataStructure
import Testing
import CoreFP

@Suite struct EitherCoreTests {

    // MARK: - Construction

    @Test func leftConstruction() {
        let either: Either<String, Int> = .left("error")

        either.match(
            caseLeft: { error in #expect(error == "error") },
            caseRight: { _ in Issue.record("Expected left") }
        )
    }

    @Test func rightConstruction() {
        let either: Either<String, Int> = .right(42)

        either.match(
            caseLeft: { _ in Issue.record("Expected right") },
            caseRight: { value in #expect(value == 42) }
        )
    }

    // MARK: - Pattern Matching

    @Test func matchLeft() {
        let either: Either<String, Int> = .left("error")
        let result = either.match(
            caseLeft: { "left: \($0)" },
            caseRight: { "right: \($0)" }
        )

        #expect(result == "left: error")
    }

    @Test func matchRight() {
        let either: Either<String, Int> = .right(42)
        let result = either.match(
            caseLeft: { "left: \($0)" },
            caseRight: { "right: \($0)" }
        )

        #expect(result == "right: 42")
    }

    // MARK: - Functor (Core Methods)

    @Test func fmap() {
        let right: Either<String, Int> = .right(5)
        let result = Either<String, Int>.fmap({ $0 * 2 })(right)
        #expect(result == .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = Either<String, Int>.fmap({ $0 * 2 })(left)
        #expect(leftResult == .left("error"))
    }

    @Test func mapRight() {
        let right: Either<String, Int> = .right(5)
        let result = right.mapRight { $0 * 2 }
        #expect(result == .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = left.mapRight { $0 * 2 }
        #expect(leftResult == .left("error"))
    }

    @Test func mapLeft() {
        let left: Either<String, Int> = .left("error")
        let result = left.mapLeft { $0.uppercased() }
        #expect(result == .left("ERROR"))

        let right: Either<String, Int> = .right(5)
        let rightResult = right.mapLeft { $0.uppercased() }
        #expect(rightResult == .right(5))
    }

    @Test func bimap() {
        let left: Either<String, Int> = .left("error")
        let leftResult = left.bimap({ $0.uppercased() }, { $0 * 2 })
        #expect(leftResult == .left("ERROR"))

        let right: Either<String, Int> = .right(5)
        let rightResult = right.bimap({ $0.uppercased() }, { $0 * 2 })
        #expect(rightResult == .right(10))
    }

    // MARK: - Applicative (Core Methods)

    @Test func liftA2() {
        let add: (Int, Int) -> Int = { $0 + $1 }
        let liftedAdd = Either<String, Int>.liftA2(add)

        let right1: Either<String, Int> = .right(5)
        let right2: Either<String, Int> = .right(10)
        let result = liftedAdd(right1, right2)
        #expect(result == .right(15))

        let left: Either<String, Int> = .left("error")
        let leftResult = liftedAdd(left, right2)
        #expect(leftResult == .left("error"))
    }

    @Test func zip() {
        let right1: Either<String, Int> = .right(5)
        let right2: Either<String, String> = .right("hello")
        let result: Either<String, (Int, String)> = Either.zip(right1, right2)

        if case .right(let tuple) = result {
            #expect(tuple.0 == 5)
            #expect(tuple.1 == "hello")
        } else {
            Issue.record("Expected right")
        }

        let left: Either<String, Int> = .left("error")
        let leftResult: Either<String, (Int, String)> = Either.zip(left, right2)
        if case .left(let error) = leftResult {
            #expect(error == "error")
        } else {
            Issue.record("Expected left")
        }
    }

    // MARK: - Monad (Core Methods)

    @Test func flatMap() {
        let right: Either<String, Int> = .right(5)
        let result = right.flatMap { value in
            .right(value * 2)
        }
        #expect(result == .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = left.flatMap { value in
            Either<String, Int>.right(value * 2)
        }
        #expect(leftResult == .left("error"))
    }

    @Test func flatMapLeftToRight() {
        let right: Either<String, Int> = .right(5)
        let result = right.flatMap { _ in
            Either<String, Int>.left("new error")
        }
        #expect(result == .left("new error"))
    }

    @Test func join() {
        let nested: Either<String, Either<String, Int>> = .right(.right(42))
        let result = nested.flatMap(id)
        #expect(result == .right(42))

        let nestedLeft: Either<String, Either<String, Int>> = .right(.left("inner error"))
        let leftResult = nestedLeft.flatMap(id)
        #expect(leftResult == .left("inner error"))
    }

    @Test func kleisli() {
        let f: (Int) -> Either<String, Int> = { .right($0 * 2) }
        let g: (Int) -> Either<String, String> = { .right("\($0)") }

        let composed = Either<String, Int>.kleisli(f, g)
        let result = composed(5)
        #expect(result == .right("10"))
    }

    // MARK: - Inverted

    @Test func inverted() {
        let left: Either<String, Int> = .left("error")
        let inverted = left.inverted()
        #expect(inverted == .right("error"))

        let right: Either<String, Int> = .right(42)
        let invertedRight = right.inverted()
        #expect(invertedRight == .left(42))
    }

    // MARK: - Result Bridge

    @Test func fromResultSuccess() {
        let result: Result<Int, TestError> = .success(42)
        let either = result.either.parallel()
        #expect(either == Either<Int, TestError>.left(42))
    }

    @Test func fromResultFailure() {
        let result: Result<Int, TestError> = .failure(.test)
        let either = result.either.parallel()
        #expect(either == Either<Int, TestError>.right(.test))
    }

    @Test func toResultRight() {
        let either: Either<TestError, Int> = .right(42)
        let result = either.result()

        if case .success(let value) = result {
            #expect(value == 42)
        } else {
            Issue.record("Expected success")
        }
    }

    @Test func toResultLeft() {
        let either: Either<TestError, Int> = .left(.test)
        let result = either.result()

        if case .failure(let error) = result {
            #expect(error == .test)
        } else {
            Issue.record("Expected failure")
        }
    }

    // MARK: - join / void

    @Test func joinFreeFunction() {
        let nested: Either<String, Either<String, Int>> = .right(.right(42))
        #expect(DataStructure.join(nested) == .right(42))
    }

    @Test func joinOuterLeft() {
        let nested: Either<String, Either<String, Int>> = .left("err")
        #expect(DataStructure.join(nested) == .left("err"))
    }

    @Test func joinInnerLeft() {
        let nested: Either<String, Either<String, Int>> = .right(.left("inner"))
        #expect(DataStructure.join(nested) == .left("inner"))
    }

    @Test func voidRight() {
        let either: Either<String, Int> = .right(5)
        if case .left = DataStructure.void(either) { Issue.record("Expected .right") }
    }

    @Test func voidLeft() {
        let either: Either<String, Int> = .left("err")
        if case .right = DataStructure.void(either) { Issue.record("Expected .left") }
    }

    // MARK: - Helper

    enum TestError: Error, Equatable {
        case test
    }
}
