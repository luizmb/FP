// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import Testing

@Suite struct OptionalTResultTests {
    private enum Err: Error, Equatable { case fail }

    private let add: @Sendable (Int) -> @Sendable (Int) -> Int = { x in { y in x + y } }

    // MARK: - Functor

    @Test func mapSomeSuccess() throws {
        let opt: Result<Int, Err>? = .success(5)
        let result = ({ $0 * 2 } <£> opt.optionalT).rawValue
        try #require(result != nil)
        #expect(try result?.get() == 10)
    }

    @Test func mapSomeFailure() {
        let opt: Result<Int, Err>? = .failure(.fail)
        let result = opt.optionalT <&> { $0 * 2 }
        #expect(result.rawValue == .some(.failure(.fail)))
    }

    @Test func mapNone() {
        let opt: Result<Int, Err>? = nil
        let result = { $0 * 2 } <£> opt.optionalT
        #expect(result.rawValue == nil)
    }

    // MARK: - Applicative

    @Test func liftA2BothSuccess() throws {
        let a: Result<Int, Err>? = .success(3)
        let b: Result<Int, Err>? = .success(4)
        let result = add <£> a.optionalT <*> b.optionalT
        #expect(try result.rawValue?.get() == 7)
    }

    @Test func liftA2LeftNil() {
        let a: Result<Int, Err>? = nil
        let b: Result<Int, Err>? = .success(4)
        let result = add <£> a.optionalT <*> b.optionalT
        #expect(result.rawValue == nil)
    }

    @Test func liftA2LeftFailure() {
        let a: Result<Int, Err>? = .failure(.fail)
        let b: Result<Int, Err>? = .success(4)
        let result = add <£> a.optionalT <*> b.optionalT
        #expect(result.rawValue == .some(.failure(.fail)))
    }

    @Test func seqRightBothSuccess() throws {
        let a: Result<Int, Err>? = .success(1)
        let b: Result<String, Err>? = .success("x")
        let result = a.optionalT *> b.optionalT
        #expect(try result.rawValue?.get() == "x")
    }

    // MARK: - Monad

    @Test func bindSomeSuccess() throws {
        let opt: Result<Int, Err>? = .success(5)
        let result = opt.optionalT >>- { n in OptionalTResult<Err, String>(.success("\(n)")) }
        #expect(try result.rawValue?.get() == "5")
    }

    @Test func bindSomeFailure() {
        let opt: Result<Int, Err>? = .failure(.fail)
        let result = opt.optionalT >>- { n in OptionalTResult<Err, String>(.success("\(n)")) }
        #expect(result.rawValue == .some(.failure(.fail)))
    }

    @Test func bindNone() {
        let opt: Result<Int, Err>? = nil
        let result = { n in OptionalTResult<Err, String>(.success("\(n)")) } -<< opt.optionalT
        #expect(result.rawValue == nil)
    }

    @Test func bindFnReturnsNil() {
        let opt: Result<Int, Err>? = .success(5)
        let result = opt.optionalT >>- const(OptionalTResult<Err, String>(nil))
        #expect(result.rawValue == nil)
    }

    @Test func bindOperator() throws {
        let opt: Result<Int, Err>? = .success(5)
        let result = opt.optionalT >>- { n in OptionalTResult<Err, Int>(.success(n * 2)) }
        #expect(try result.rawValue?.get() == 10)
    }

    // MARK: - Applicative is ap (mixed failures)

    @Test func applicativeOperatorsMatchBindOnMixedFailure() {
        let fns = OptionalTResult<Err, @Sendable (Int) -> Int>(.some(.failure(.fail)))
        let lhs = OptionalTResult<Err, Int>(.some(.failure(.fail)))
        let rhs = OptionalTResult<Err, Int>(nil)
        #expect((fns <*> rhs).rawValue == (fns >>- { fn in fn <£> rhs }).rawValue)
        #expect((fns <*> rhs).rawValue == .some(.failure(.fail)))
        #expect((lhs *> rhs).rawValue == .some(.failure(.fail)))
        #expect((lhs <* rhs).rawValue == .some(.failure(.fail)))
    }
}
