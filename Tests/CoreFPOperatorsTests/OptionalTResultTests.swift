import Testing
@testable import CoreFP
@testable import CoreFPOperators

@Suite struct OptionalTResultTests {

    private enum Err: Error, Equatable { case fail }

    // MARK: - Functor

    @Test func mapTSomeSuccess() throws {
        let opt: Result<Int, Err>? = .success(5)
        let result = opt.mapT { $0 * 2 }
        try #require(result != nil)
        #expect(try result?.get() == 10)
    }

    @Test func mapTSomeFailure() {
        let opt: Result<Int, Err>? = .failure(.fail)
        let result = opt.mapT { $0 * 2 }
        #expect(result == .some(.failure(.fail)))
    }

    @Test func mapTNone() {
        let opt: Result<Int, Err>? = nil
        let result = opt.mapT { $0 * 2 }
        #expect(result == nil)
    }

    @Test func fmapOperator() throws {
        let opt: Result<Int, Err>? = .success(3)
        let result = { $0 * 2 } <£> opt
        #expect(try result?.get() == 6)
    }

    // MARK: - Applicative

    @Test func liftA2BothSuccess() throws {
        let a: Result<Int, Err>? = .success(3)
        let b: Result<Int, Err>? = .success(4)
        let result = liftA2OptionalResult(+)(a, b)
        #expect(try result?.get() == 7)
    }

    @Test func liftA2LeftNil() {
        let a: Result<Int, Err>? = nil
        let b: Result<Int, Err>? = .success(4)
        let result = liftA2OptionalResult(+)(a, b)
        #expect(result == nil)
    }

    @Test func liftA2LeftFailure() {
        let a: Result<Int, Err>? = .failure(.fail)
        let b: Result<Int, Err>? = .success(4)
        let result = liftA2OptionalResult(+)(a, b)
        #expect(result == .some(.failure(.fail)))
    }

    @Test func seqRightBothSuccess() throws {
        let a: Result<Int, Err>? = .success(1)
        let b: Result<String, Err>? = .success("x")
        let result = a *> b
        #expect(try result?.get() == "x")
    }

    // MARK: - Monad

    @Test func flatMapTSomeSuccess() throws {
        let opt: Result<Int, Err>? = .success(5)
        let result = opt.flatMapT { n in Result<String, Err>.success("\(n)") }
        #expect(try result?.get() == "5")
    }

    @Test func flatMapTSomeFailure() {
        let opt: Result<Int, Err>? = .failure(.fail)
        let result = opt.flatMapT { n in Result<String, Err>.success("\(n)") }
        #expect(result == .some(.failure(.fail)))
    }

    @Test func flatMapTNone() {
        let opt: Result<Int, Err>? = nil
        let result = opt.flatMapT { n in Result<String, Err>.success("\(n)") }
        #expect(result == nil)
    }

    @Test func flatMapTFnReturnsNil() {
        let opt: Result<Int, Err>? = .success(5)
        let result = opt.flatMapT { _ -> Result<String, Err>? in nil }
        #expect(result == nil)
    }

    @Test func bindOperator() throws {
        let opt: Result<Int, Err>? = .success(5)
        let result = opt >>- { n -> Result<Int, Err>? in .success(n * 2) }
        #expect(try result?.get() == 10)
    }
}
