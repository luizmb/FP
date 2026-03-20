import XCTest
@testable import FP
@testable import Reader
@testable import ReaderOperators
import Operators

final class ReaderFunctorTests: XCTestCase {

    struct Environment {
        let multiplier: Int
        let addend: Int
    }

    // MARK: - Basic Functor Tests

    func testFmap() {
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let doubled = reader.fmap { $0 * 2 }

        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(doubled(env), 10)
    }

    func testCurriedFmap() {
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let double: (Int) -> Int = { $0 * 2 }
        let fmap = Reader<Environment, Int>.fmap(double)
        let doubled = fmap(reader)

        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(doubled(env), 10)
    }

    func testMapReader() {
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let toString = reader.mapReader { "\($0)" }

        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(toString(env), "5")
    }

    func testContramapEnvironment() {
        struct GlobalEnv {
            let local: Environment
            let prefix: String
        }

        let reader = Reader<Environment, Int> { env in env.multiplier }
        let globalReader = reader.contramapEnvironment { (global: GlobalEnv) in global.local }

        let globalEnv = GlobalEnv(local: Environment(multiplier: 5, addend: 3), prefix: "test")
        XCTAssertEqual(globalReader(globalEnv), 5)
    }

    func testDimap() {
        struct GlobalEnv {
            let local: Environment
        }

        let reader = Reader<Environment, Int> { env in env.multiplier }
        let transformed = reader.dimap(
            { (global: GlobalEnv) in global.local },
            { "\($0)" }
        )

        let globalEnv = GlobalEnv(local: Environment(multiplier: 5, addend: 3))
        XCTAssertEqual(transformed(globalEnv), "5")
    }

    // MARK: - Functor Laws

    func testFunctorIdentityLaw() {
        // fmap id == id
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let identity: (Int) -> Int = { $0 }
        let mapped = reader.fmap(identity)

        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(reader(env), mapped(env))
    }

    func testFunctorCompositionLaw() {
        // fmap (g . f) == fmap g . fmap f
        let reader = Reader<Environment, Int> { env in env.multiplier }

        let f: (Int) -> Int = { $0 * 2 }
        let g: (Int) -> String = { "\($0)" }

        let composed = reader.fmap(compose(f, g))
        let separate = reader.fmap(f).fmap(g)

        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(composed(env), separate(env))
    }

    // MARK: - Functor Operators

    func testFmapOperator() {
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let doubled = { $0 * 2 } <£> reader

        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(doubled(env), 10)
    }

    func testMapReplaceOperator() {
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let replaced = reader £> 99

        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(replaced(env), 99)
    }

    func testMapReplaceFlippedOperator() {
        let reader = Reader<Environment, Int> { env in env.multiplier }
        let replaced = 42 <£ reader

        let env = Environment(multiplier: 5, addend: 3)
        XCTAssertEqual(replaced(env), 42)
    }
}
