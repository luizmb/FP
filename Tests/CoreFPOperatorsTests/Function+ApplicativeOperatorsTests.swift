// SPDX-License-Identifier: Apache-2.0
@testable import CoreFP
@testable import CoreFPOperators
import Testing

@Suite struct FunctionApplicativeTests {
    // MARK: - Basic Applicative Tests

    @Test func basicApply() {
        // Function that returns a function
        let f: @Sendable (Int) -> @Sendable (Int) -> Int = { x in { y in x + y } }
        let g: @Sendable (Int) -> Int = { $0 * 2 }

        let result: @Sendable (Int) -> Int = apply(f, g)

        // For input 5: f(5) = { y in 5 + y }, g(5) = 10
        // So f(5)(g(5)) = { y in 5 + y }(10) = 15
        #expect(result(5) == 15)
        #expect(result(3) == 9) // f(3)(g(3)) = 3 + 6 = 9
    }

    @Test func curriedApply() {
        let f: @Sendable (Int) -> @Sendable (Int) -> Int = { x in { y in x + y } }
        let g: @Sendable (Int) -> Int = { $0 * 2 }

        let appliedF: @Sendable (@escaping @Sendable (Int) -> Int) -> @Sendable (Int) -> Int = apply(f)
        let result: @Sendable (Int) -> Int = appliedF(g)

        #expect(result(5) == 15)
        #expect(result(3) == 9)
    }

    @Test func basicPure() {
        let constantFn: @Sendable (Int) -> String = pure("hello")

        #expect(constantFn(1) == "hello")
        #expect(constantFn(100) == "hello")
        #expect(constantFn(-5) == "hello")
    }

    @Test func basicLiftA2() {
        let add: @Sendable (Int) -> @Sendable (Int) -> Int = { x in { y in x + y } }
        let f: @Sendable (String) -> Int = get(\.count)
        let g: @Sendable (String) -> Int = const(10)

        let lifted: @Sendable (String) -> Int = liftA2(add, f, g)

        #expect(lifted("hello") == 15) // 5 + 10
        #expect(lifted("ab") == 12) // 2 + 10
    }

    @Test func curriedLiftA2() {
        let multiply: @Sendable (Int) -> @Sendable (Int) -> Int = { x in { y in x * y } }
        let f: @Sendable (Int) -> Int = { $0 + 1 }
        let g: @Sendable (Int) -> Int = { $0 * 2 }

        let lifted: @Sendable (Int) -> Int = liftA2(multiply)(f)(g)

        // For input 5: f(5) = 6, g(5) = 10, result = 6 * 10 = 60
        #expect(lifted(5) == 60)
        // For input 3: f(3) = 4, g(3) = 6, result = 4 * 6 = 24
        #expect(lifted(3) == 24)
    }

    // MARK: - Applicative Laws

    @Test func applicativeIdentityLaw() {
        // pure id <*> v == v
        let v: @Sendable (Int) -> Int = { $0 * 2 }
        let identity: @Sendable (Int) -> Int = id
        let pureId: @Sendable (Int) -> @Sendable (Int) -> Int = pure(identity)

        let left = pureId <*> v
        let right = v

        #expect(left(5) == right(5))
        #expect(left(10) == right(10))
    }

    @Test func applicativeCompositionLaw() {
        // pure (.) <*> u <*> v <*> w == u <*> (v <*> w)
        let u: @Sendable (Int) -> @Sendable (Int) -> String = { x in { y in "\(x + y)" } }
        let v: @Sendable (Int) -> @Sendable (Int) -> Int = { x in { y in x + y } }
        let w: @Sendable (Int) -> Int = { $0 * 2 }

        // Composition function for functions
        typealias CompFn = @Sendable (@escaping @Sendable (Int) -> String)
            -> @Sendable (@escaping @Sendable (Int) -> Int)
            -> @Sendable (Int) -> String
        let comp: CompFn = { f in
            { g in
                { x in f(g(x)) }
            }
        }

        let pureComp: @Sendable (Int) -> CompFn = pure(comp)

        // Left side: pure (.) <*> u <*> v <*> w
        let step1 = pureComp <*> u
        let step2 = step1 <*> v
        let left = step2 <*> w

        // Right side: u <*> (v <*> w)
        let right = u <*> (v <*> w)

        #expect(left(5) == right(5))
        #expect(left(3) == right(3))
    }

    @Test func applicativeHomomorphismLaw() {
        // pure f <*> pure x == pure (f x)
        let f: @Sendable (Int) -> String = { "\($0)" }
        let x = 42

        let pureF: @Sendable (String) -> @Sendable (Int) -> String = pure(f)
        let pureX: @Sendable (String) -> Int = pure(x)

        let left = pureF <*> pureX
        let right: @Sendable (String) -> String = pure(f(x))

        #expect(left("ignored") == right("ignored"))
        #expect(left("also ignored") == right("also ignored"))
    }

    @Test func applicativeInterchangeLaw() {
        // u <*> pure y == pure ($ y) <*> u
        let u: @Sendable (Int) -> @Sendable (Int) -> String = { x in { y in "\(x + y)" } }
        let y = 10

        let pureY: @Sendable (Int) -> Int = pure(y)
        let left = u <*> pureY

        // ($ y) means "apply to y"
        let applyToY: @Sendable (@escaping @Sendable (Int) -> String) -> String = { f in f(y) }
        let pureApplyToY: @Sendable (Int) -> @Sendable (@escaping @Sendable (Int) -> String) -> String = pure(applyToY)
        let right = pureApplyToY <*> u

        #expect(left(5) == right(5))
        #expect(left(3) == right(3))
    }

    // MARK: - Applicative Operators

    @Test func applyOperator() {
        let f: @Sendable (Int) -> @Sendable (String) -> String = { x in { y in "\(x): \(y)" } }
        let g: @Sendable (Int) -> String = { "value \($0)" }

        let result = f <*> g

        #expect(result(5) == "5: value 5")
        #expect(result(10) == "10: value 10")
    }

    @Test func sequenceRightOperator() {
        let f: @Sendable (Int) -> Int = { $0 + 1 }
        let g: @Sendable (Int) -> String = { "\($0)" }

        let result = f *> g

        // Should evaluate f, discard result, return g's result
        #expect(result(5) == "5")
        #expect(result(10) == "10")
    }

    @Test func sequenceLeftOperator() {
        let f: @Sendable (Int) -> String = { "\($0)" }
        let g: @Sendable (Int) -> Int = { $0 + 1 }

        let result = f <* g

        // Should evaluate f, keep result, evaluate g, return f's result
        #expect(result(5) == "5")
        #expect(result(10) == "10")
    }

    @Test func operatorComposition() {
        // Demonstrate chaining with liftA2
        let f: @Sendable (Int) -> Int = { $0 * 2 }
        let g: @Sendable (Int) -> Int = { $0 + 1 }

        let add: @Sendable (Int, Int) -> Int = { $0 + $1 }
        let addCurried: @Sendable (Int) -> @Sendable (Int) -> Int = { x in { y in add(x, y) } }
        let combined: @Sendable (Int) -> Int = liftA2(addCurried, f, g)

        // For input 5: f(5) = 10, g(5) = 6, result = 10 + 6 = 16
        #expect(combined(5) == 16)

        // Can also use pure and <*>
        let pureAdd: @Sendable (Int) -> @Sendable (Int) -> @Sendable (Int) -> Int = pure(addCurried)
        let step1: @Sendable (Int) -> @Sendable (Int) -> Int = pureAdd <*> f
        let result: @Sendable (Int) -> Int = step1 <*> g

        #expect(result(5) == 16)
    }

    // MARK: - Practical Examples

    @Test func practicalExample() {
        // Simulate reading from environment and combining values
        struct Config {
            let multiplier: Int
            let offset: Int
        }

        let getMultiplier: @Sendable (Config) -> Int = get(\.multiplier)
        let getOffset: @Sendable (Config) -> Int = get(\.offset)

        let combine: @Sendable (Int, Int) -> Int = { $0 + $1 }
        let combineCurried: @Sendable (Int) -> @Sendable (Int) -> Int = { x in { y in combine(x, y) } }

        let result: @Sendable (Config) -> Int = liftA2(combineCurried, getMultiplier, getOffset)

        let config = Config(multiplier: 5, offset: 10)
        #expect(result(config) == 15)
    }

    @Test func readerPattern() {
        // The function applicative is essentially the Reader monad's applicative
        struct Environment {
            let name: String
            let age: Int
        }

        let getName: @Sendable (Environment) -> String = get(\.name)
        let getAge: @Sendable (Environment) -> Int = get(\.age)

        let greet: @Sendable (String, Int) -> String = { name, age in
            "Hello \(name), you are \(age) years old"
        }
        let greetCurried: @Sendable (String) -> @Sendable (Int) -> String = { name in
            { age in greet(name, age) }
        }

        let greeting: @Sendable (Environment) -> String = liftA2(greetCurried, getName, getAge)

        let env = Environment(name: "Alice", age: 30)
        #expect(greeting(env) == "Hello Alice, you are 30 years old")
    }

    @Test func liftA2Practical() {
        // Combine two computations that depend on the same input
        let square: @Sendable (Int) -> Int = { $0 * $0 }
        let double: @Sendable (Int) -> Int = { $0 * 2 }

        let add: @Sendable (Int) -> @Sendable (Int) -> Int = { x in { y in x + y } }
        let combined: @Sendable (Int) -> Int = liftA2(add, square, double)

        // For input 5: square(5) = 25, double(5) = 10, result = 35
        #expect(combined(5) == 35)
        // For input 3: square(3) = 9, double(3) = 6, result = 15
        #expect(combined(3) == 15)
    }

    @Test func equivalenceWithManualApplication() {
        let f: @Sendable (Int) -> @Sendable (Int) -> Int = { x in { y in x + y } }
        let g: @Sendable (Int) -> Int = { $0 * 2 }

        let viaApply = f <*> g
        let manual: @Sendable (Int) -> Int = { r in f(r)(g(r)) }

        #expect(viaApply(5) == manual(5))
        #expect(viaApply(10) == manual(10))
    }
}
