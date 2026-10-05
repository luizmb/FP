// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import Testing

@Suite struct ArrayTResultTests {
    private enum Err: Error, Equatable { case fail }

    private let add: @Sendable (Int) -> @Sendable (Int) -> Int = { x in { y in x + y } }

    // MARK: - Functor

    @Test func mapAllSuccess() throws {
        let arr: [Result<Int, Err>] = [.success(1), .success(2), .success(3)]
        let result = { $0 * 2 } <£> arr.arrayT
        #expect(try result.rawValue.map { try $0.get() } == [2, 4, 6])
    }

    @Test func mapWithFailure() {
        let arr: [Result<Int, Err>] = [.success(1), .failure(.fail), .success(3)]
        let result = arr.arrayT <&> { $0 * 2 }
        #expect(result.rawValue == [.success(2), .failure(.fail), .success(6)])
    }

    // MARK: - Applicative

    @Test func liftA2CartesianProduct() {
        let a: [Result<Int, Err>] = [.success(1), .success(2)]
        let b: [Result<Int, Err>] = [.success(10), .success(20)]
        let result = add <£> a.arrayT <*> b.arrayT
        #expect(result.rawValue == [.success(11), .success(21), .success(12), .success(22)])
    }

    @Test func liftA2WithFailure() {
        let a: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let b: [Result<Int, Err>] = [.success(10)]
        let result = add <£> a.arrayT <*> b.arrayT
        #expect(result.rawValue == [.success(11), .failure(.fail)])
    }

    @Test func seqRightCartesianProduct() {
        let a: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let b: [Result<String, Err>] = [.success("x")]
        let result = a.arrayT *> b.arrayT
        #expect(result.rawValue == [.success("x"), .failure(.fail)])
    }

    @Test func seqLeftCartesianProduct() {
        let a: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let b: [Result<String, Err>] = [.success("x")]
        let result = a.arrayT <* b.arrayT
        #expect(result.rawValue == [.success(1), .failure(.fail)])
    }

    // MARK: - Monad

    @Test func bindAllSuccess() {
        let arr: [Result<Int, Err>] = [.success(1), .success(2)]
        let result = arr.arrayT >>- { n in ArrayTResult([.success(n), .success(n * 10)]) }
        #expect(result.rawValue == [.success(1), .success(10), .success(2), .success(20)])
    }

    @Test func bindFailurePropagates() {
        let arr: [Result<Int, Err>] = [.success(1), .failure(.fail), .success(3)]
        let result = arr.arrayT >>- { n in ArrayTResult<Err, String>([.success("\(n)")]) }
        #expect(result.rawValue == [.success("1"), .failure(.fail), .success("3")])
    }

    @Test func bindEmpty() {
        let arr: [Result<Int, Err>] = []
        let result = { n in ArrayTResult<Err, String>([.success("\(n)")]) } -<< arr.arrayT
        #expect(result.rawValue == [])
    }

    @Test func bindOperator() {
        let arr: [Result<Int, Err>] = [.success(1), .success(2)]
        let result = arr.arrayT >>- { n in ArrayTResult<Err, Int>([.success(n * 2)]) }
        #expect(result.rawValue == [.success(2), .success(4)])
    }

    @Test func kleisliOperator() {
        let f: @Sendable (Int) -> ArrayTResult<Err, Int> = { n in ArrayTResult([.success(n), .success(n * 2)]) }
        let g: @Sendable (Int) -> ArrayTResult<Err, String> = { n in ArrayTResult([.success("\(n)")]) }
        let h = f >=> g
        #expect(h(3).rawValue == [.success("3"), .success("6")])
        #expect((g <=< f)(3).rawValue == [.success("3"), .success("6")])
    }
}
