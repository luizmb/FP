@testable import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ReaderFunctorTests {
    struct Environment {
        let multiplier: Int
        let addend: Int
    }

    // MARK: - Basic Functor Tests

    @Test func fmap() {
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let doubled = reader.map { $0 * 2 }

        let env = Environment(multiplier: 5, addend: 3)
        #expect(doubled(env) == 10)
    }

    @Test func curriedFmap() {
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let double: (Int) -> Int = { $0 * 2 }
        let fmap = Reader<Environment, Int>.fmap(double)
        let doubled = fmap(reader)

        let env = Environment(multiplier: 5, addend: 3)
        #expect(doubled(env) == 10)
    }

    @Test func mapReader() {
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let toString = reader.mapReader { "\($0)" }

        let env = Environment(multiplier: 5, addend: 3)
        #expect(toString(env) == "5")
    }

    @Test func contramapEnvironment() {
        struct GlobalEnv {
            let local: Environment
            let prefix: String
        }

        let reader = Reader<Environment, Int> { env in env.multiplier }
        let globalReader = reader.contramapEnvironment { (global: GlobalEnv) in global.local }

        let globalEnv = GlobalEnv(local: Environment(multiplier: 5, addend: 3), prefix: "test")
        #expect(globalReader(globalEnv) == 5)
    }

    @Test func contramapEnvironmentCurried() {
        struct GlobalEnv { let local: Environment }

        let reader = Reader<Environment, Int> { env in env.multiplier }
        let widen = Reader<Environment, Int>.contramapEnvironment { (g: GlobalEnv) in g.local }
        let globalReader = widen(reader)

        let globalEnv = GlobalEnv(local: Environment(multiplier: 7, addend: 0))
        #expect(globalReader(globalEnv) == 7)
    }

    @Test func contramapEnvironmentPointFree() {
        struct GlobalEnv { let local: Environment }

        let readers: [Reader<Environment, Int>] = [
            Reader { $0.multiplier },
            Reader { $0.addend },
        ]
        let widen = Reader<Environment, Int>.contramapEnvironment { (g: GlobalEnv) in g.local }
        let global = readers.map(widen)

        let env = GlobalEnv(local: Environment(multiplier: 3, addend: 9))
        #expect(global[0](env) == 3)
        #expect(global[1](env) == 9)
    }

    @Test func dimap() {
        struct GlobalEnv {
            let local: Environment
        }

        let reader = Reader<Environment, Int> { env in env.multiplier }
        let transformed = reader.dimap(
            { (global: GlobalEnv) in global.local },
            { "\($0)" }
        )

        let globalEnv = GlobalEnv(local: Environment(multiplier: 5, addend: 3))
        #expect(transformed(globalEnv) == "5")
    }

    @Test func dimapCurried() {
        struct GlobalEnv { let local: Environment }

        let reader = Reader<Environment, Int> { env in env.multiplier }
        let transform = Reader<Environment, Int>.dimap(
            { (g: GlobalEnv) in g.local },
            { "\($0)" }
        )
        let transformed = transform(reader)

        let globalEnv = GlobalEnv(local: Environment(multiplier: 4, addend: 0))
        #expect(transformed(globalEnv) == "4")
    }

    @Test func dimapPointFree() {
        struct GlobalEnv { let local: Environment }

        let readers: [Reader<Environment, Int>] = [
            Reader { $0.multiplier },
            Reader { $0.addend },
        ]
        let transform = Reader<Environment, Int>.dimap(
            { (g: GlobalEnv) in g.local },
            { $0 * 10 }
        )
        let global = readers.map(transform)

        let env = GlobalEnv(local: Environment(multiplier: 2, addend: 5))
        #expect(global[0](env) == 20)
        #expect(global[1](env) == 50)
    }

    // MARK: - Functor Laws

    @Test func functorIdentityLaw() {
        // fmap id == id
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let mapped = reader.map(id)

        let env = Environment(multiplier: 5, addend: 3)
        #expect(reader(env) == mapped(env))
    }

    @Test func functorCompositionLaw() {
        // fmap (g . f) == fmap g . fmap f
        let reader = Reader<Environment, Int> { env in env.multiplier }

        let f: (Int) -> Int = { $0 * 2 }
        let g: (Int) -> String = { "\($0)" }

        let composed = reader.map(compose(f, g))
        let separate = reader.map(f).map(g)

        let env = Environment(multiplier: 5, addend: 3)
        #expect(composed(env) == separate(env))
    }

    // MARK: - Functor Operators

    @Test func fmapOperator() {
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let doubled = { $0 * 2 } <£> reader

        let env = Environment(multiplier: 5, addend: 3)
        #expect(doubled(env) == 10)
    }

    @Test func mapReplaceOperator() {
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let replaced = reader £> 99

        let env = Environment(multiplier: 5, addend: 3)
        #expect(replaced(env) == 99)
    }

    @Test func mapReplaceFlippedOperator() {
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let replaced = 42 <£ reader

        let env = Environment(multiplier: 5, addend: 3)
        #expect(replaced(env) == 42)
    }
}
