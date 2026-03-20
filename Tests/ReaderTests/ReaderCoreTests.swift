import Testing
@testable import Reader
import FP

@Suite struct ReaderCoreTests {

    struct Environment {
        let multiplier: Int
        let offset: Int
    }

    // MARK: - Construction and Execution

    @Test func readerConstruction() {
        let reader = Reader<Environment, Int> { env in
            env.multiplier * 2
        }

        let env = Environment(multiplier: 5, offset: 3)
        #expect(reader(env) == 10)
    }

    @Test func readerCall() {
        let reader = Reader<Environment, Int> { env in
            env.multiplier + env.offset
        }

        let env = Environment(multiplier: 5, offset: 3)
        #expect(reader.callAsFunction(env) == 8)
    }

    // MARK: - Functor (Core Methods)

    @Test func fmap() {
        let reader = Reader<Environment, Int> { env in
            env.multiplier
        }

        let mapped = reader.fmap { $0 * 2 }

        let env = Environment(multiplier: 5, offset: 3)
        #expect(mapped(env) == 10)
    }

    @Test func mapReader() {
        let reader = Reader<Environment, Int> { env in
            env.multiplier
        }

        let mapped = reader.mapReader { "\($0)" }

        let env = Environment(multiplier: 5, offset: 3)
        #expect(mapped(env) == "5")
    }

    @Test func contramapEnvironment() {
        let reader = Reader<Int, String> { value in
            "\(value)"
        }

        let contramapped = reader.contramapEnvironment { (env: Environment) in
            env.multiplier
        }

        let env = Environment(multiplier: 5, offset: 3)
        #expect(contramapped(env) == "5")
    }

    @Test func dimap() {
        let reader = Reader<Int, Int> { value in
            value * 2
        }

        let dimapped = reader.dimap(
            { (env: Environment) in env.multiplier },
            { "\($0)" }
        )

        let env = Environment(multiplier: 5, offset: 3)
        #expect(dimapped(env) == "10")
    }

    // MARK: - Applicative (Core Methods)

    @Test func apply() {
        let readerFn = Reader<Environment, (Int) -> Int> { env in
            { value in value + env.offset }
        }

        let readerValue = Reader<Environment, Int> { env in
            env.multiplier
        }

        let result = Reader<Environment, Int> { env in
            let fn = readerFn(env)
            let value = readerValue(env)
            return fn(value)
        }

        let env = Environment(multiplier: 5, offset: 3)
        #expect(result(env) == 8)
    }

    @Test func liftA2() {
        let reader1 = Reader<Environment, Int> { env in
            env.multiplier
        }

        let reader2 = Reader<Environment, Int> { env in
            env.offset
        }

        let add: (Int, Int) -> Int = { $0 + $1 }
        let combined = Reader<Environment, Int>.liftA2(add)(reader1, reader2)

        let env = Environment(multiplier: 5, offset: 3)
        #expect(combined(env) == 8)
    }

    @Test func liftA2NonCurried() {
        let reader1 = Reader<Environment, Int> { env in
            env.multiplier
        }

        let reader2 = Reader<Environment, Int> { env in
            env.offset
        }

        let add: (Int, Int) -> Int = { $0 + $1 }
        let liftedAdd = Reader<Environment, Int>.liftA2(add)
        let combined = liftedAdd(reader1, reader2)

        let env = Environment(multiplier: 5, offset: 3)
        #expect(combined(env) == 8)
    }

    // MARK: - Monad (Core Methods)

    @Test func flatMap() {
        let reader = Reader<Environment, Int> { env in
            env.multiplier
        }

        let bound = reader.flatMap { value in
            Reader<Environment, String> { env in
                "\(value + env.offset)"
            }
        }

        let env = Environment(multiplier: 5, offset: 3)
        #expect(bound(env) == "8")
    }

    @Test func join() {
        let nested = Reader<Environment, Reader<Environment, Int>> { env in
            Reader<Environment, Int> { innerEnv in
                env.multiplier + innerEnv.offset
            }
        }

        let flattened = nested.flatMap(id)

        let env = Environment(multiplier: 5, offset: 3)
        #expect(flattened(env) == 8)
    }

    @Test func kleisli() {
        let f: (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value + env.offset }
        }

        let g: (Int) -> Reader<Environment, String> = { value in
            Reader { env in "\(value * env.multiplier)" }
        }

        let composed = Reader<Environment, Int>.kleisli(f, g)
        let result = composed(5)

        let env = Environment(multiplier: 2, offset: 3)
        #expect(result(env) == "16") // (5 + 3) * 2 = 16
    }

    @Test func kleisliBack() {
        let f: (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value + env.offset }
        }

        let g: (Int) -> Reader<Environment, String> = { value in
            Reader { env in "\(value * env.multiplier)" }
        }

        let composed = Reader<Environment, Int>.kleisliBack(g, f)
        let result = composed(5)

        let env = Environment(multiplier: 2, offset: 3)
        #expect(result(env) == "16")
    }

    // MARK: - Ask

    @Test func ask() {
        let reader = Reader<Environment, Environment>.ask

        let env = Environment(multiplier: 5, offset: 3)
        let result = reader(env)

        #expect(result.multiplier == 5)
        #expect(result.offset == 3)
    }

    @Test func asks() {
        let reader = Reader<Environment, Int>.asks { $0.multiplier }

        let env = Environment(multiplier: 5, offset: 3)
        #expect(reader(env) == 5)
    }

    // MARK: - Local

    @Test func local() {
        let reader = Reader<Environment, Int> { env in
            env.multiplier + env.offset
        }

        let modified = reader.local { env in
            Environment(multiplier: env.multiplier * 2, offset: env.offset)
        }

        let env = Environment(multiplier: 5, offset: 3)
        #expect(modified(env) == 13) // (5 * 2) + 3 = 13
    }
}
