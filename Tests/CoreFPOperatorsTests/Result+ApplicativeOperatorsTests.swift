import Testing
@testable import CoreFP
@testable import CoreFPOperators

@Suite struct ResultApplicativeTests {

    enum TestError: Error, Equatable {
        case error1
        case error2
    }

    // MARK: - Basic Applicative Tests

    @Test func apply() {
        let fn: Result<(Int) -> Int, TestError> = .success({ $0 * 2 })
        let value: Result<Int, TestError> = .success(5)
        let result = fn <*> value
        #expect((try? result.get()) == 10)

        let failureFn: Result<(Int) -> Int, TestError> = .failure(.error1)
        let failureResult = failureFn <*> value
        #expect(throws: (any Error).self) { try failureResult.get() }

        let failureValue: Result<Int, TestError> = .failure(.error2)
        let failureValueResult = fn <*> failureValue
        #expect(throws: (any Error).self) { try failureValueResult.get() }
    }

    @Test func liftA2() {
        let add: (Int, Int) -> Int = { $0 + $1 }
        let lifted = Result<Int, TestError>.liftA2(add)

        let value1: Result<Int, TestError> = .success(5)
        let value2: Result<Int, TestError> = .success(3)
        #expect((try? lifted(value1, value2).get()) == 8)

        let failure1: Result<Int, TestError> = .failure(.error1)
        #expect(throws: (any Error).self) { try lifted(failure1, value2).get() }

        let failure2: Result<Int, TestError> = .failure(.error2)
        #expect(throws: (any Error).self) { try lifted(value1, failure2).get() }
    }

    @Test func zip() {
        let value1: Result<Int, TestError> = .success(5)
        let value2: Result<String, TestError> = .success("test")
        let result = Result<(Int, String), TestError>.zip(value1, value2)

        if case .success(let tuple) = result {
            #expect(tuple.0 == 5)
            #expect(tuple.1 == "test")
        } else {
            Issue.record("Expected success value")
        }

        let failure1: Result<Int, TestError> = .failure(.error1)
        let failureResult = Result<(Int, String), TestError>.zip(failure1, value2)
        #expect(throws: (any Error).self) { try failureResult.get() }
    }

    // MARK: - Applicative Laws

    @Test func applicativeIdentityLaw() {
        // pure id <*> v = v
        let value: Result<Int, TestError> = .success(5)
        let identity: Result<(Int) -> Int, TestError> = .success(id)
        let result = identity <*> value
        #expect((try? result.get()) == (try? value.get()))
    }

    @Test func applicativeCompositionLaw() {
        // pure (.) <*> u <*> v <*> w = u <*> (v <*> w)
        let u: Result<(Int) -> String, TestError> = .success({ "\($0)" })
        let v: Result<(Int) -> Int, TestError> = .success({ $0 * 2 })
        let w: Result<Int, TestError> = .success(5)

        // Left side: compose functions then apply to w
        let composeFn: (@escaping (Int) -> String, @escaping (Int) -> Int) -> (Int) -> String = { f, g in
            { x in f(g(x)) }
        }
        let composed = Result<(Int) -> String, TestError>.liftA2(composeFn)(u, v)
        let left = composed <*> w

        // Right side: apply v to w, then apply u
        let vw = v <*> w
        let right = u <*> vw

        #expect((try? left.get()) == (try? right.get()))
    }

    @Test func applicativeHomomorphismLaw() {
        // pure f <*> pure x = pure (f x)
        let f: (Int) -> Int = { $0 * 2 }
        let x = 5

        let pureF: Result<(Int) -> Int, TestError> = .success(f)
        let pureX: Result<Int, TestError> = .success(x)
        let left = pureF <*> pureX
        let right: Result<Int, TestError> = .success(f(x))

        #expect((try? left.get()) == (try? right.get()))
    }

    @Test func applicativeInterchangeLaw() {
        // u <*> pure y = pure ($ y) <*> u
        let u: Result<(Int) -> Int, TestError> = .success({ $0 * 2 })
        let y = 5

        let pureY: Result<Int, TestError> = .success(y)
        let left = u <*> pureY

        let applyTo: (@escaping (Int) -> Int) -> Int = { fn in fn(y) }
        let pureApply: Result<(@escaping (Int) -> Int) -> Int, TestError> = .success(applyTo)
        let right = pureApply <*> u

        #expect((try? left.get()) == (try? right.get()))
    }

    // MARK: - Applicative Operators

    @Test func applyOperator() {
        let fn: Result<(Int) -> Int, TestError> = .success({ $0 * 2 })
        let value: Result<Int, TestError> = .success(5)
        let result = fn <*> value
        #expect((try? result.get()) == 10)

        let failure: Result<Int, TestError> = .failure(.error1)
        let failureResult = fn <*> failure
        #expect(throws: (any Error).self) { try failureResult.get() }
    }

    @Test func sequenceRight() {
        let value1: Result<Int, TestError> = .success(5)
        let value2: Result<Int, TestError> = .success(10)
        let result = value1 *> value2
        #expect((try? result.get()) == 10)

        let failure: Result<Int, TestError> = .failure(.error1)
        #expect(throws: (any Error).self) { try (failure *> value2).get() }
        #expect(throws: (any Error).self) { try (value1 *> failure).get() }
    }

    @Test func sequenceLeft() {
        let value1: Result<Int, TestError> = .success(5)
        let value2: Result<Int, TestError> = .success(10)
        let result = value1 <* value2
        #expect((try? result.get()) == 5)

        let failure: Result<Int, TestError> = .failure(.error1)
        #expect(throws: (any Error).self) { try (failure <* value2).get() }
        #expect(throws: (any Error).self) { try (value1 <* failure).get() }
    }
}
