import XCTest
@testable import Reader
import FP

final class ReaderCoreTests: XCTestCase {

    struct Environment {
        let multiplier: Int
        let offset: Int
    }

    // MARK: - Construction and Execution

    func testReaderConstruction() {
        let reader = Reader<Environment, Int> { env in
            env.multiplier * 2
        }

        let env = Environment(multiplier: 5, offset: 3)
        XCTAssertEqual(reader(env), 10)
    }

    func testReaderCall() {
        let reader = Reader<Environment, Int> { env in
            env.multiplier + env.offset
        }

        let env = Environment(multiplier: 5, offset: 3)
        XCTAssertEqual(reader.callAsFunction(env), 8)
    }

    // MARK: - Functor (Core Methods)

    func testFmap() {
        let reader = Reader<Environment, Int> { env in
            env.multiplier
        }

        let mapped = reader.fmap { $0 * 2 }

        let env = Environment(multiplier: 5, offset: 3)
        XCTAssertEqual(mapped(env), 10)
    }

    func testMapReader() {
        let reader = Reader<Environment, Int> { env in
            env.multiplier
        }

        let mapped = reader.mapReader { "\($0)" }

        let env = Environment(multiplier: 5, offset: 3)
        XCTAssertEqual(mapped(env), "5")
    }

    func testContramapEnvironment() {
        let reader = Reader<Int, String> { value in
            "\(value)"
        }

        let contramapped = reader.contramapEnvironment { (env: Environment) in
            env.multiplier
        }

        let env = Environment(multiplier: 5, offset: 3)
        XCTAssertEqual(contramapped(env), "5")
    }

    func testDimap() {
        let reader = Reader<Int, Int> { value in
            value * 2
        }

        let dimapped = reader.dimap(
            { (env: Environment) in env.multiplier },
            { "\($0)" }
        )

        let env = Environment(multiplier: 5, offset: 3)
        XCTAssertEqual(dimapped(env), "10")
    }

    // MARK: - Applicative (Core Methods)

    func testApply() {
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
        XCTAssertEqual(result(env), 8)
    }

    func testLiftA2() {
        let reader1 = Reader<Environment, Int> { env in
            env.multiplier
        }

        let reader2 = Reader<Environment, Int> { env in
            env.offset
        }

        let add: (Int, Int) -> Int = { $0 + $1 }
        let combined = Reader<Environment, Int>.liftA2(add)(reader1, reader2)

        let env = Environment(multiplier: 5, offset: 3)
        XCTAssertEqual(combined(env), 8)
    }

    func testLiftA2NonCurried() {
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
        XCTAssertEqual(combined(env), 8)
    }

    // MARK: - Monad (Core Methods)

    func testFlatMap() {
        let reader = Reader<Environment, Int> { env in
            env.multiplier
        }

        let bound = reader.flatMap { value in
            Reader<Environment, String> { env in
                "\(value + env.offset)"
            }
        }

        let env = Environment(multiplier: 5, offset: 3)
        XCTAssertEqual(bound(env), "8")
    }

    func testJoin() {
        let nested = Reader<Environment, Reader<Environment, Int>> { env in
            Reader<Environment, Int> { innerEnv in
                env.multiplier + innerEnv.offset
            }
        }

        let flattened = nested.flatMap { $0 }

        let env = Environment(multiplier: 5, offset: 3)
        XCTAssertEqual(flattened(env), 8)
    }

    func testKleisli() {
        let f: (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value + env.offset }
        }

        let g: (Int) -> Reader<Environment, String> = { value in
            Reader { env in "\(value * env.multiplier)" }
        }

        let composed = Reader<Environment, Int>.kleisli(f, g)
        let result = composed(5)

        let env = Environment(multiplier: 2, offset: 3)
        XCTAssertEqual(result(env), "16") // (5 + 3) * 2 = 16
    }

    func testKleisliBack() {
        let f: (Int) -> Reader<Environment, Int> = { value in
            Reader { env in value + env.offset }
        }

        let g: (Int) -> Reader<Environment, String> = { value in
            Reader { env in "\(value * env.multiplier)" }
        }

        let composed = Reader<Environment, Int>.kleisliBack(g, f)
        let result = composed(5)

        let env = Environment(multiplier: 2, offset: 3)
        XCTAssertEqual(result(env), "16")
    }

    // MARK: - Ask

    func testAsk() {
        let reader = Reader<Environment, Environment>.ask

        let env = Environment(multiplier: 5, offset: 3)
        let result = reader(env)

        XCTAssertEqual(result.multiplier, 5)
        XCTAssertEqual(result.offset, 3)
    }

    func testAsks() {
        let reader = Reader<Environment, Int>.asks { $0.multiplier }

        let env = Environment(multiplier: 5, offset: 3)
        XCTAssertEqual(reader(env), 5)
    }

    // MARK: - Local

    func testLocal() {
        let reader = Reader<Environment, Int> { env in
            env.multiplier + env.offset
        }

        let modified = reader.local { env in
            Environment(multiplier: env.multiplier * 2, offset: env.offset)
        }

        let env = Environment(multiplier: 5, offset: 3)
        XCTAssertEqual(modified(env), 13) // (5 * 2) + 3 = 13
    }
}
