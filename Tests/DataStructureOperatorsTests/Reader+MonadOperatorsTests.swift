import DataStructureOperators
import DataStructure
import Testing
@testable import CoreFP
import CoreFPOperators

@Suite struct ReaderMonadTests {

    struct Environment {
        let multiplier: Int
        let addend: Int
    }

    // MARK: - FlatMap Tests

    @Test func flatMap() {
        let reader1 = Reader<Environment, Int> { env in env.multiplier }
        let reader2: (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value * env.addend }
        }

        let result = reader1.flatMap(reader2)
        let env = Environment(multiplier: 5, addend: 3)

        #expect(result(env) == 15) // 5 * 3
    }

    @Test func bind() {
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let transform: (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value + env.addend }
        }

        let result = Reader.bind(transform)(reader)
        let env = Environment(multiplier: 5, addend: 3)

        #expect(result(env) == 8) // 5 + 3
    }

    // MARK: - Kleisli Composition Tests

    @Test func kleisliComposition() {
        let getMultiplier: (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value * env.multiplier }
        }

        let addAddend: (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value + env.addend }
        }

        let composed = Reader.kleisli(getMultiplier, addAddend)
        let env = Environment(multiplier: 2, addend: 10)

        #expect(composed(5)(env) == 20) // (5 * 2) + 10
    }

    // MARK: - Join Tests

    @Test func join() {
        let nested = Reader<Environment, Reader<Environment, Int>> { env in
            Reader { _ in env.multiplier * 2 }
        }

        let flattened = Reader.join(nested)
        let env = Environment(multiplier: 5, addend: 3)

        #expect(flattened(env) == 10)
    }

    // MARK: - Ask/Asks Tests

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

    // MARK: - Monad Laws Tests

    @Test func leftIdentity() {
        // return a >>= f = f a
        let a = 5
        let f: (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value * env.multiplier }
        }

        let left = Reader<Environment, Int> { _ in a }.flatMap(f)
        let right = f(a)

        let env = Environment(multiplier: 2, addend: 3)
        #expect(left(env) == right(env))
    }

    @Test func rightIdentity() {
        // m >>= return = m
        let m = Reader<Environment, Int> { env in env.multiplier }
        let pureFunc: (Int) -> Reader<Environment, Int> = { value in
            Reader { _ in value }
        }

        let left = m.flatMap(pureFunc)

        let env = Environment(multiplier: 5, addend: 3)
        #expect(left(env) == m(env))
    }

    @Test func associativity() {
        // (m >>= f) >>= g = m >>= (\x -> f x >>= g)
        let m = Reader<Environment, Int> { env in env.multiplier }
        let f: (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value + env.addend }
        }
        let g: (Int) -> Reader<Environment, Int> = { value in
            Reader { _ in value * 2 }
        }

        let left = m.flatMap(f).flatMap(g)
        let right = m.flatMap { x in f(x).flatMap(g) }

        let env = Environment(multiplier: 5, addend: 3)
        #expect(left(env) == right(env))
    }
}
