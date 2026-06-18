// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

private enum TestError: Error { case err }

@Suite struct ResultFoldableTests {
    // MARK: - foldMap

    @Test func foldMapSuccess() {
        let r: Result<Int, TestError> = .success(5)
        #expect(r.foldMap({ "\($0)" }) == "5")
    }

    @Test func foldMapFailureReturnsIdentity() {
        let r: Result<Int, TestError> = .failure(.err)
        #expect(r.foldMap({ "\($0)" }) == "")
    }

    @Test func foldMapCurried() {
        let fn = Result<Int, TestError>.foldMap({ "\($0)" })
        #expect(fn(.success(3)) == "3")
        #expect(fn(.failure(.err)) == "")
    }

    @Test func foldMapPointFree() {
        let values: [Result<Int, TestError>] = [.success(1), .failure(.err), .success(2)]
        let result = values.map(Result<Int, TestError>.foldMap({ "\($0)" }))
        #expect(result == ["1", "", "2"])
    }

    // MARK: - toList

    @Test func toListSuccess() {
        let r: Result<Int, TestError> = .success(42)
        #expect(r.toList == [42])
    }

    @Test func toListFailure() {
        let r: Result<Int, TestError> = .failure(.err)
        #expect(r.toList == [])
    }
}
