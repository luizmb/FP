@testable import CoreFP
import DataStructure
import DataStructureOperators
import Testing
import CoreFPOperators

@Suite struct ReaderApplicativeTests {
    struct Environment {
        let multiplier: Int
        let addend: Int
    }

    // MARK: - Basic Applicative Tests

    @Test func apply() {
        let readerFn = Reader<Environment, (Int) -> Int> { env in
            { value in value * env.multiplier }
        }
        let readerValue = Reader<Environment, Int> { env in env.addend }

        let result = readerFn <*> readerValue
        let env = Environment(multiplier: 5, addend: 3)
        #expect(result(env) == 15) // 3 * 5
    }

    @Test func liftA2() {
        let reader1 = Reader<Environment, Int> { env in env.multiplier }
        let reader2 = Reader<Environment, Int> { env in env.addend }

        let add: (Int, Int) -> Int = { $0 + $1 }
        let combined = Reader<Environment, Int>.liftA2(add)(reader1, reader2)

        let env = Environment(multiplier: 5, addend: 3)
        #expect(combined(env) == 8)
    }

    // MARK: - Applicative Laws

    @Test func applicativeIdentityLaw() {
        // pure id <*> v = v
        let value = Reader<Environment, Int> { env in env.multiplier }
        let identity = Reader<Environment, (Int) -> Int>(const(id))
        let result = identity <*> value

        let env = Environment(multiplier: 5, addend: 3)
        #expect(result(env) == value(env))
    }

    @Test func applicativeCompositionLaw() {
        // pure (.) <*> u <*> v <*> w = u <*> (v <*> w)
        let u = Reader<Environment, (Int) -> String> { _ in { "\($0)" } }
        let v = Reader<Environment, (Int) -> Int> { env in { $0 * env.multiplier } }
        let w = Reader<Environment, Int> { env in env.addend }

        // Left side: compose functions then apply to w
        let composeFn: (@escaping (Int) -> String, @escaping (Int) -> Int) -> (Int) -> String = { f, g in
            { x in f(g(x)) }
        }
        let composed = Reader<Environment, (Int) -> String>.liftA2(composeFn)(u, v)
        let left = composed <*> w

        // Right side: apply v to w, then apply u
        let vw = v <*> w
        let right = u <*> vw

        let env = Environment(multiplier: 2, addend: 5)
        #expect(left(env) == right(env))
    }

    @Test func applicativeHomomorphismLaw() {
        // pure f <*> pure x = pure (f x)
        let f: (Int) -> Int = { $0 * 2 }
        let x = 5

        let readerF = Reader<Environment, (Int) -> Int> { _ in f }
        let readerX = Reader<Environment, Int> { _ in x }
        let left = readerF <*> readerX

        let right = Reader<Environment, Int> { _ in f(x) }

        let env = Environment(multiplier: 1, addend: 1)
        #expect(left(env) == right(env))
    }

    @Test func applicativeInterchangeLaw() {
        // u <*> pure y = pure ($ y) <*> u
        let u = Reader<Environment, (Int) -> Int> { env in { $0 * env.multiplier } }
        let y = 5

        let pureY = Reader<Environment, Int> { _ in y }
        let left = u <*> pureY

        let applyTo: (@escaping (Int) -> Int) -> Int = { fn in fn(y) }
        let pureApply = Reader<Environment, (@escaping (Int) -> Int) -> Int> { _ in applyTo }
        let right = pureApply <*> u

        let env = Environment(multiplier: 2, addend: 3)
        #expect(left(env) == right(env))
    }

    // MARK: - Applicative Operators

    @Test func applyOperator() {
        let readerFn = Reader<Environment, (Int) -> Int> { _ in { $0 * 2 } }
        let readerValue = Reader<Environment, Int> { env in env.multiplier }

        let result = readerFn <*> readerValue
        let env = Environment(multiplier: 5, addend: 3)
        #expect(result(env) == 10)
    }

    @Test func sequenceRight() {
        let reader1 = Reader<Environment, Int> { env in env.multiplier }
        let reader2 = Reader<Environment, Int> { env in env.addend }

        let result = reader1 *> reader2
        let env = Environment(multiplier: 5, addend: 3)
        #expect(result(env) == 3)
    }

    @Test func sequenceLeft() {
        let reader1 = Reader<Environment, Int> { env in env.multiplier }
        let reader2 = Reader<Environment, Int> { env in env.addend }

        let result = reader1 <* reader2
        let env = Environment(multiplier: 5, addend: 3)
        #expect(result(env) == 5)
    }
}
