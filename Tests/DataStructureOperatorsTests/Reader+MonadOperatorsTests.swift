// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ReaderMonadTests {
    struct Environment {
        let multiplier: Int
        let addend: Int
    }

    // MARK: - Bind Operator Tests

    @Test func bindOperatorContainerLeft() {
        let reader1 = Reader<Environment, Int> { env in env.multiplier }
        let reader2: @Sendable (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value * env.addend }
        }

        let result = reader1 >>- reader2
        let env = Environment(multiplier: 5, addend: 3)

        #expect(result(env) == 15) // 5 * 3
    }

    @Test func bindOperatorFunctionLeft() {
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let transform: @Sendable (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value + env.addend }
        }

        let result = transform -<< reader
        let env = Environment(multiplier: 5, addend: 3)

        #expect(result(env) == 8) // 5 + 3
    }

    // MARK: - Kleisli Composition Tests

    @Test func kleisliOperatorForward() {
        let getMultiplier: @Sendable (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value * env.multiplier }
        }

        let addAddend: @Sendable (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value + env.addend }
        }

        let composed = getMultiplier >=> addAddend
        let env = Environment(multiplier: 2, addend: 10)

        #expect(composed(5)(env) == 20) // (5 * 2) + 10
    }

    @Test func kleisliOperatorBackward() {
        let getMultiplier: @Sendable (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value * env.multiplier }
        }

        let addAddend: @Sendable (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value + env.addend }
        }

        let composed = addAddend <=< getMultiplier
        let env = Environment(multiplier: 2, addend: 10)

        #expect(composed(5)(env) == 20) // (5 * 2) + 10
    }

    // MARK: - Join Tests

    // No custom operator exists for `join` on Reader — tested via the named function.

    @Test func join() {
        let nested = Reader<Environment, Reader<Environment, Int>> { env in
            Reader(const(env.multiplier * 2))
        }

        let flattened = Reader.join(nested)
        let env = Environment(multiplier: 5, addend: 3)

        #expect(flattened(env) == 10)
    }

    // MARK: - Ask/Asks Tests

    // No custom operator exists for `ask`/`asks` on Reader — tested via the named API.

    @Test func ask() {
        let reader = Reader<Environment, Environment>.ask
        let env = Environment(multiplier: 5, addend: 3)

        #expect(reader(env).multiplier == 5)
        #expect(reader(env).addend == 3)
    }

    @Test func asks() {
        let reader = Reader<Environment, Int>.asks { $0.multiplier }
        let env = Environment(multiplier: 5, addend: 3)

        #expect(reader(env) == 5)
    }

    // MARK: - Local Tests

    // No custom operator exists for `local` on Reader — tested via the named function.

    @Test func local() {
        let reader = Reader<Environment, Int> { env in
            env.multiplier + env.addend
        }

        let modified = reader.local { env in
            Environment(multiplier: env.multiplier * 2, addend: env.addend)
        }

        let env = Environment(multiplier: 5, addend: 3)

        #expect(reader(env) == 8) // 5 + 3
        #expect(modified(env) == 13) // (5 * 2) + 3
    }

    // MARK: - Monad Laws Tests (via >>-)

    @Test func leftIdentity() {
        // return a >>- f = f a
        let a = 5
        let f: @Sendable (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value * env.multiplier }
        }

        let left = Reader<Environment, Int>(const(a)) >>- f
        let right = f(a)

        let env = Environment(multiplier: 2, addend: 3)
        #expect(left(env) == right(env))
    }

    @Test func rightIdentity() {
        // m >>- return = m
        let m = Reader<Environment, Int> { env in env.multiplier }
        let pureFunc: @Sendable (Int) -> Reader<Environment, Int> = { value in
            Reader(const(value))
        }

        let left = m >>- pureFunc

        let env = Environment(multiplier: 5, addend: 3)
        #expect(left(env) == m(env))
    }

    @Test func associativity() {
        // (m >>- f) >>- g = m >>- (\x -> f x >>- g)
        let m = Reader<Environment, Int> { env in env.multiplier }
        let f: @Sendable (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value + env.addend }
        }
        let g: @Sendable (Int) -> Reader<Environment, Int> = { value in
            Reader(const(value * 2))
        }

        let left = (m >>- f) >>- g
        let right = m >>- { x in f(x) >>- g }

        let env = Environment(multiplier: 5, addend: 3)
        #expect(left(env) == right(env))
    }
}
