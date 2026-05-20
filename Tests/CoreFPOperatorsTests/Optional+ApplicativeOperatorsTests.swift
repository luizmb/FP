@testable import CoreFP
@testable import CoreFPOperators
import Testing

@Suite struct OptionalApplicativeTests {
    // MARK: - Basic Applicative Tests

    @Test func apply() {
        let fn: (@Sendable (Int) -> Int)? = { $0 * 2 }
        let value: Int? = 5
        let result = fn <*> value
        #expect(result == 10)

        let noneFn: (@Sendable (Int) -> Int)? = nil
        let noneResult = noneFn <*> value
        #expect(noneResult == nil)

        let noneValue: Int? = nil
        let noneValueResult = fn <*> noneValue
        #expect(noneValueResult == nil)
    }

    @Test func liftA2() {
        let add: @Sendable (Int, Int) -> Int = { $0 + $1 }
        let lifted = Int?.liftA2(add)

        #expect(lifted(5, 3) == 8)
        #expect(lifted(nil, 3) == nil)
        #expect(lifted(5, nil) == nil)
        #expect(lifted(nil, nil) == nil)
    }

    @Test func zip() {
        let value1: Int? = 5
        let value2: String? = "test"
        let result = (Int, String)?.zip(value1, value2)

        if let tuple = result {
            #expect(tuple.0 == 5)
            #expect(tuple.1 == "test")
        } else {
            Issue.record("Expected some value")
        }

        let none1: Int? = nil
        #expect((Int, String)?.zip(none1, value2) == nil)
        #expect((Int, String)?.zip(value1, nil) == nil)
    }

    // MARK: - Applicative Laws

    @Test func applicativeIdentityLaw() {
        // pure id <*> v = v
        let value: Int? = 5
        let identity: (@Sendable (Int) -> Int)? = id
        let result = identity <*> value
        #expect(result == value)
    }

    @Test func applicativeCompositionLaw() {
        // pure (.) <*> u <*> v <*> w = u <*> (v <*> w)
        let u: (@Sendable (Int) -> String)? = { "\($0)" }
        let v: (@Sendable (Int) -> Int)? = { $0 * 2 }
        let w: Int? = 5

        // Left side: compose functions then apply to w
        let composeFn: @Sendable (@escaping @Sendable (Int) -> String, @escaping @Sendable (Int) -> Int) -> @Sendable (Int) -> String = { f, g in
            { x in f(g(x)) }
        }
        let composed = (@Sendable (Int) -> String)?.liftA2(composeFn)(u, v)
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

        let pureF: (@Sendable (Int) -> Int)? = .some(f)
        let pureX: Int? = .some(x)
        let left = pureF <*> pureX
        let right: Int? = .some(f(x))

        #expect(left == right)
    }

    @Test func applicativeInterchangeLaw() {
        // u <*> pure y = pure ($ y) <*> u
        let u: (@Sendable (Int) -> Int)? = { $0 * 2 }
        let y = 5

        let pureY: Int? = .some(y)
        let left = u <*> pureY

        let applyTo: @Sendable (@escaping @Sendable (Int) -> Int) -> Int = { fn in fn(y) }
        let pureApply: (@Sendable (@escaping @Sendable (Int) -> Int) -> Int)? = .some(applyTo)
        let right = pureApply <*> u

        #expect(left == right)
    }

    // MARK: - Applicative Operators

    @Test func applyOperator() {
        let fn: (@Sendable (Int) -> Int)? = { $0 * 2 }
        let value: Int? = 5
        let result = fn <*> value
        #expect(result == 10)

        let none: Int? = nil
        let noneResult = fn <*> none
        #expect(noneResult == nil)
    }

    @Test func sequenceRight() {
        let value1: Int? = 5
        let value2: Int? = 10
        let result = value1 *> value2
        #expect(result == 10)

        let none: Int? = nil
        #expect((none *> value2) == nil)
        #expect((value1 *> none) == nil)
    }

    @Test func sequenceLeft() {
        let value1: Int? = 5
        let value2: Int? = 10
        let result = value1 <* value2
        #expect(result == 5)

        let none: Int? = nil
        #expect((none <* value2) == nil)
        #expect((value1 <* none) == nil)
    }
}
