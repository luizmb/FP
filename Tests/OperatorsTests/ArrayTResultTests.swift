import Testing
@testable import FP
@testable import Operators

@Suite struct ArrayTResultTests {

    private enum Err: Error, Equatable { case fail }

    // MARK: - Functor

    @Test func mapTAllSuccess() throws {
        let arr: [Result<Int, Err>] = [.success(1), .success(2), .success(3)]
        let result = arr.mapT { $0 * 2 }
        #expect(try result.map { try $0.get() } == [2, 4, 6])
    }

    @Test func mapTWithFailure() {
        let arr: [Result<Int, Err>] = [.success(1), .failure(.fail), .success(3)]
        let result = arr.mapT { $0 * 2 }
        #expect(result == [.success(2), .failure(.fail), .success(6)])
    }

    @Test func fmapOperator() {
        let arr: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let result = { $0 * 2 } <£> arr
        #expect(result == [.success(2), .failure(.fail)])
    }

    // MARK: - Applicative

    @Test func liftA2CartesianProduct() {
        let a: [Result<Int, Err>] = [.success(1), .success(2)]
        let b: [Result<Int, Err>] = [.success(10), .success(20)]
        let result = liftA2ArrayResult(+)(a, b)
        #expect(result == [.success(11), .success(21), .success(12), .success(22)])
    }

    @Test func liftA2WithFailure() {
        let a: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let b: [Result<Int, Err>] = [.success(10)]
        let result = liftA2ArrayResult(+)(a, b)
        #expect(result == [.success(11), .failure(.fail)])
    }

    @Test func seqRightCartesianProduct() {
        let a: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let b: [Result<String, Err>] = [.success("x")]
        let result = a *> b
        #expect(result == [.success("x"), .failure(.fail)])
    }

    @Test func seqLeftCartesianProduct() {
        let a: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let b: [Result<String, Err>] = [.success("x")]
        let result = a <* b
        #expect(result == [.success(1), .failure(.fail)])
    }

    // MARK: - Monad

    @Test func flatMapTAllSuccess() {
        let arr: [Result<Int, Err>] = [.success(1), .success(2)]
        let result = arr.flatMapT { n in [.success(n), .success(n * 10)] }
        #expect(result == [.success(1), .success(10), .success(2), .success(20)])
    }

    @Test func flatMapTFailurePropagates() {
        let arr: [Result<Int, Err>] = [.success(1), .failure(.fail), .success(3)]
        let result = arr.flatMapT { n in [Result<String, Err>.success("\(n)")] }
        #expect(result == [.success("1"), .failure(.fail), .success("3")])
    }

    @Test func flatMapTEmpty() {
        let arr: [Result<Int, Err>] = []
        let result = arr.flatMapT { n in [Result<String, Err>.success("\(n)")] }
        #expect(result == [])
    }

    @Test func bindOperator() {
        let arr: [Result<Int, Err>] = [.success(1), .success(2)]
        let result = arr >>- { n in [Result<Int, Err>.success(n * 2)] }
        #expect(result == [.success(2), .success(4)])
    }

    @Test func kleisliOperator() {
        let f: (Int) -> [Result<Int, Err>] = { n in [.success(n), .success(n * 2)] }
        let g: (Int) -> [Result<String, Err>] = { n in [.success("\(n)")] }
        let h = f >=> g
        #expect(h(3) == [.success("3"), .success("6")])
    }
}
