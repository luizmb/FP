import Testing
@testable import FP
@testable import Reader
@testable import ReaderOperators
import Operators

@Suite struct ReaderFunctorTests {

    struct Environment {
        let multiplier: Int
        let addend: Int
    }

    // MARK: - Basic Functor Tests

    @Test func fmap() {
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let doubled = reader.fmap { $0 * 2 }

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

    // MARK: - Functor Laws

    @Test func functorIdentityLaw() {
        // fmap id == id
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let identity: (Int) -> Int = { $0 }
        let mapped = reader.fmap(identity)

        let env = Environment(multiplier: 5, addend: 3)
        #expect(reader(env) == mapped(env))
    }

    @Test func functorCompositionLaw() {
        // fmap (g . f) == fmap g . fmap f
        let reader = Reader<Environment, Int> { env in env.multiplier }

        let f: (Int) -> Int = { $0 * 2 }
        let g: (Int) -> String = { "\($0)" }

        let composed = reader.fmap(compose(f, g))
        let separate = reader.fmap(f).fmap(g)

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
