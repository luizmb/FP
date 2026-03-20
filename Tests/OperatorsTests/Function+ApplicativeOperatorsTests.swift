import Testing
@testable import FP
@testable import Operators

@Suite struct FunctionApplicativeTests {

    // MARK: - Basic Applicative Tests

    @Test func basicApply() {
        // Function that returns a function
        let f: (Int) -> (Int) -> Int = { x in { y in x + y } }
        let g: (Int) -> Int = { $0 * 2 }

        let result = apply(f, g)

        // For input 5: f(5) = { y in 5 + y }, g(5) = 10
        // So f(5)(g(5)) = { y in 5 + y }(10) = 15
        #expect(result(5) == 15)
        #expect(result(3) == 9)  // f(3)(g(3)) = 3 + 6 = 9
    }

    @Test func curriedApply() {
        let f: (Int) -> (Int) -> Int = { x in { y in x + y } }
        let g: (Int) -> Int = { $0 * 2 }

        let appliedF = apply(f)
        let result = appliedF(g)

        #expect(result(5) == 15)
        #expect(result(3) == 9)
    }

    @Test func basicPure() {
        let constantFn: (Int) -> String = pure("hello")

        #expect(constantFn(1) == "hello")
        #expect(constantFn(100) == "hello")
        #expect(constantFn(-5) == "hello")
    }

    @Test func basicLiftA2() {
        let add: (Int) -> (Int) -> Int = { x in { y in x + y } }
        let f: (String) -> Int = { $0.count }
        let g: (String) -> Int = { _ in 10 }

        let lifted = liftA2(add, f, g)

        #expect(lifted("hello") == 15)  // 5 + 10
        #expect(lifted("ab") == 12)     // 2 + 10
    }

    @Test func curriedLiftA2() {
        let multiply: (Int) -> (Int) -> Int = { x in { y in x * y } }
        let f: (Int) -> Int = { $0 + 1 }
        let g: (Int) -> Int = { $0 * 2 }

        let lifted = liftA2(multiply)(f)(g)

        // For input 5: f(5) = 6, g(5) = 10, result = 6 * 10 = 60
        #expect(lifted(5) == 60)
        // For input 3: f(3) = 4, g(3) = 6, result = 4 * 6 = 24
        #expect(lifted(3) == 24)
    }

    // MARK: - Applicative Laws

    @Test func applicativeIdentityLaw() {
        // pure id <*> v == v
        let v: (Int) -> Int = { $0 * 2 }
        let identity: (Int) -> Int = id
        let pureId: (Int) -> (Int) -> Int = pure(identity)

        let left = pureId <*> v
        let right = v

        #expect(left(5) == right(5))
        #expect(left(10) == right(10))
    }

    @Test func applicativeCompositionLaw() {
        // pure (.) <*> u <*> v <*> w == u <*> (v <*> w)
        let u: (Int) -> (Int) -> String = { x in { y in "\(x + y)" } }
        let v: (Int) -> (Int) -> Int = { x in { y in x + y } }
        let w: (Int) -> Int = { $0 * 2 }

        // Composition function for functions
        let comp: (@escaping (Int) -> String) -> (@escaping (Int) -> Int) -> (Int) -> String = { f in
            { g in
                { x in f(g(x)) }
            }
        }

        let pureComp: (Int) -> (@escaping (Int) -> String) -> (@escaping (Int) -> Int) -> (Int) -> String = pure(comp)

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
        let f: (Int) -> String = { "\($0)" }
        let x = 42

        let pureF: (String) -> (Int) -> String = pure(f)
        let pureX: (String) -> Int = pure(x)

        let left = pureF <*> pureX
        let right: (String) -> String = pure(f(x))

        #expect(left("ignored") == right("ignored"))
        #expect(left("also ignored") == right("also ignored"))
    }

    @Test func applicativeInterchangeLaw() {
        // u <*> pure y == pure ($ y) <*> u
        let u: (Int) -> (Int) -> String = { x in { y in "\(x + y)" } }
        let y = 10

        let pureY: (Int) -> Int = pure(y)
        let left = u <*> pureY

        // ($ y) means "apply to y"
        let applyToY: (@escaping (Int) -> String) -> String = { f in f(y) }
        let pureApplyToY: (Int) -> (@escaping (Int) -> String) -> String = pure(applyToY)
        let right = pureApplyToY <*> u

        #expect(left(5) == right(5))
        #expect(left(3) == right(3))
    }

    // MARK: - Applicative Operators

    @Test func applyOperator() {
        let f: (Int) -> (String) -> String = { x in { y in "\(x): \(y)" } }
        let g: (Int) -> String = { "value \($0)" }

        let result = f <*> g

        #expect(result(5) == "5: value 5")
        #expect(result(10) == "10: value 10")
    }

    @Test func sequenceRightOperator() {
        let f: (Int) -> Int = { $0 + 1 }
        let g: (Int) -> String = { "\($0)" }

        let result = f *> g

        // Should evaluate f, discard result, return g's result
        #expect(result(5) == "5")
        #expect(result(10) == "10")
    }

    @Test func sequenceLeftOperator() {
        let f: (Int) -> String = { "\($0)" }
        let g: (Int) -> Int = { $0 + 1 }

        let result = f <* g

        // Should evaluate f, keep result, evaluate g, return f's result
        #expect(result(5) == "5")
        #expect(result(10) == "10")
    }

    @Test func operatorComposition() {
        // Demonstrate chaining with liftA2
        let f: (Int) -> Int = { $0 * 2 }
        let g: (Int) -> Int = { $0 + 1 }

        let add: (Int, Int) -> Int = { $0 + $1 }
        let addCurried: (Int) -> (Int) -> Int = { x in { y in add(x, y) } }
        let combined = liftA2(addCurried, f, g)

        // For input 5: f(5) = 10, g(5) = 6, result = 10 + 6 = 16
        #expect(combined(5) == 16)

        // Can also use pure and <*>
        let pureAdd: (Int) -> (Int) -> (Int) -> Int = pure(addCurried)
        let step1: (Int) -> (Int) -> Int = pureAdd <*> f
        let result: (Int) -> Int = step1 <*> g

        #expect(result(5) == 16)
    }

    // MARK: - Practical Examples

    @Test func practicalExample() {
        // Simulate reading from environment and combining values
        struct Config {
            let multiplier: Int
            let offset: Int
        }

        let getMultiplier: (Config) -> Int = { $0.multiplier }
        let getOffset: (Config) -> Int = { $0.offset }

        let combine: (Int, Int) -> Int = { $0 + $1 }
        let combineCurried: (Int) -> (Int) -> Int = { x in { y in combine(x, y) } }

        let result = liftA2(combineCurried, getMultiplier, getOffset)

        let config = Config(multiplier: 5, offset: 10)
        #expect(result(config) == 15)
    }

    @Test func readerPattern() {
        // The function applicative is essentially the Reader monad's applicative
        struct Environment {
            let name: String
            let age: Int
        }

        let getName: (Environment) -> String = { $0.name }
        let getAge: (Environment) -> Int = { $0.age }

        let greet: (String, Int) -> String = { name, age in
            "Hello \(name), you are \(age) years old"
        }
        let greetCurried: (String) -> (Int) -> String = { name in
            { age in greet(name, age) }
        }

        let greeting = liftA2(greetCurried, getName, getAge)

        let env = Environment(name: "Alice", age: 30)
        #expect(greeting(env) == "Hello Alice, you are 30 years old")
    }

    @Test func liftA2Practical() {
        // Combine two computations that depend on the same input
        let square: (Int) -> Int = { $0 * $0 }
        let double: (Int) -> Int = { $0 * 2 }

        let add: (Int) -> (Int) -> Int = { x in { y in x + y } }
        let combined = liftA2(add, square, double)

        // For input 5: square(5) = 25, double(5) = 10, result = 35
        #expect(combined(5) == 35)
        // For input 3: square(3) = 9, double(3) = 6, result = 15
        #expect(combined(3) == 15)
    }

    @Test func equivalenceWithManualApplication() {
        let f: (Int) -> (Int) -> Int = { x in { y in x + y } }
        let g: (Int) -> Int = { $0 * 2 }

        let viaApply = f <*> g
        let manual: (Int) -> Int = { r in f(r)(g(r)) }

        #expect(viaApply(5) == manual(5))
        #expect(viaApply(10) == manual(10))
    }
}
