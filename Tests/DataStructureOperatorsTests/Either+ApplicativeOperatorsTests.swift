// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct EitherApplicativeTests {
    // MARK: - Basic Applicative Tests

    @Test func apply() {
        let fn: Either<String, @Sendable (Int) -> Int> = .right { $0 * 2 }
        let value: Either<String, Int> = .right(5)
        let result = fn <*> value
        #expect(result == .right(10))

        let leftFn: Either<String, @Sendable (Int) -> Int> = .left("error")
        let leftResult = leftFn <*> value
        #expect(leftResult == .left("error"))

        let leftValue: Either<String, Int> = .left("value error")
        let leftValueResult = fn <*> leftValue
        #expect(leftValueResult == .left("value error"))
    }

    @Test func liftA2() {
        let add: @Sendable (Int, Int) -> Int = { $0 + $1 }
        let lifted = Either<String, Int>.liftA2(add)

        let value1: Either<String, Int> = .right(5)
        let value2: Either<String, Int> = .right(3)
        let result = lifted(value1, value2)
        #expect(result == .right(8))

        let left1: Either<String, Int> = .left("error1")
        let leftResult = lifted(left1, value2)
        #expect(leftResult == .left("error1"))

        let left2: Either<String, Int> = .left("error2")
        let leftResult2 = lifted(value1, left2)
        #expect(leftResult2 == .left("error2"))
    }

    @Test func zip() {
        let value1: Either<String, Int> = .right(5)
        let value2: Either<String, String> = .right("test")
        let result = Either<String, (Int, String)>.zip(value1, value2)

        if case let .right(tuple) = result {
            #expect(tuple.0 == 5)
            #expect(tuple.1 == "test")
        } else {
            Issue.record("Expected right value")
        }

        let left1: Either<String, Int> = .left("error")
        let leftResult = Either<String, (Int, String)>.zip(left1, value2)
        if case let .left(error) = leftResult {
            #expect(error == "error")
        } else {
            Issue.record("Expected left value")
        }
    }

    // MARK: - Applicative Laws

    @Test func applicativeIdentityLaw() {
        // pure id <*> v = v
        let value: Either<String, Int> = .right(5)
        let identityE: Either<String, @Sendable (Int) -> Int> = .right(id)
        let result = identityE <*> value
        #expect(result == value)
    }

    @Test func applicativeCompositionLaw() {
        // pure (.) <*> u <*> v <*> w = u <*> (v <*> w)
        let u: Either<String, @Sendable (Int) -> String> = .right { "\($0)" }
        let v: Either<String, @Sendable (Int) -> Int> = .right { $0 * 2 }
        let w: Either<String, Int> = .right(5)

        // Left side: compose functions then apply to w
        typealias ComposeFn = @Sendable (
            @escaping @Sendable (Int) -> String,
            @escaping @Sendable (Int) -> Int
        ) -> @Sendable (Int) -> String
        let composeFn: ComposeFn = { f, g in { x in f(g(x)) } }
        let composed = Either<String, @Sendable (Int) -> String>.liftA2(composeFn)(u, v)
        let left = composed <*> w

        // Right side: apply v to w, then apply u
        let vw = v <*> w
        let right = u <*> vw

        #expect(left == right)
    }

    @Test func applicativeHomomorphismLaw() {
        // pure f <*> pure x = pure (f x)
        let f: @Sendable (Int) -> Int = { $0 * 2 }
        let x = 5

        let pureF: Either<String, @Sendable (Int) -> Int> = .right(f)
        let pureX: Either<String, Int> = .right(x)
        let left = pureF <*> pureX
        let right: Either<String, Int> = .right(f(x))

        #expect(left == right)
    }

    @Test func applicativeInterchangeLaw() {
        // u <*> pure y = pure ($ y) <*> u
        let u: Either<String, @Sendable (Int) -> Int> = .right { $0 * 2 }
        let y = 5

        let pureY: Either<String, Int> = .right(y)
        let left = u <*> pureY

        let applyTo: @Sendable (@escaping @Sendable (Int) -> Int) -> Int = { fn in fn(y) }
        let pureApply: Either<String, @Sendable (@escaping @Sendable (Int) -> Int) -> Int> = .right(applyTo)
        let right = pureApply <*> u

        #expect(left == right)
    }

    // MARK: - Applicative Operators

    @Test func applyOperator() {
        let fn: Either<String, @Sendable (Int) -> Int> = .right { $0 * 2 }
        let value: Either<String, Int> = .right(5)
        let result = fn <*> value
        #expect(result == .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = fn <*> left
        #expect(leftResult == .left("error"))
    }

    @Test func sequenceRight() {
        let value1: Either<String, Int> = .right(5)
        let value2: Either<String, Int> = .right(10)
        let result = value1 *> value2
        #expect(result == .right(10))

        let left: Either<String, Int> = .left("error")
        let leftResult = left *> value2
        #expect(leftResult == .left("error"))

        let leftResult2 = value1 *> left
        #expect(leftResult2 == .left("error"))
    }

    @Test func sequenceLeft() {
        let value1: Either<String, Int> = .right(5)
        let value2: Either<String, Int> = .right(10)
        let result = value1 <* value2
        #expect(result == .right(5))

        let left: Either<String, Int> = .left("error")
        let leftResult = left <* value2
        #expect(leftResult == .left("error"))

        let leftResult2 = value1 <* left
        #expect(leftResult2 == .left("error"))
    }
}
