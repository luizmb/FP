// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

@Suite struct ResultTraversableTests {
    private enum TestError: Error, Equatable { case fail }

    // MARK: - Fold

    @Test func foldSuccess() {
        let r: Result<Int, TestError> = .success(5)
        #expect(r.fold(onSuccess: { $0 * 2 }, onFailure: const(-1)) == 10)
    }

    @Test func foldFailure() {
        let r: Result<Int, TestError> = .failure(.fail)
        #expect(r.fold(onSuccess: { $0 * 2 }, onFailure: const(-1)) == -1)
    }

    @Test func foldCurriedStatic() {
        let fold = Result<Int, TestError>.fold(onSuccess: { $0 * 2 }, onFailure: const(-1))
        #expect(fold(.success(5)) == 10)
        #expect(fold(.failure(.fail)) == -1)
    }

    // MARK: - traverse :: (a -> [b]) -> Result a e -> [Result b e]

    @Test func traverseArrayFailure() {
        let r: Result<Int, TestError> = .failure(.fail)
        #expect(r.traverse { [$0, $0 * 2] } == [.failure(.fail)])
    }

    @Test func traverseArraySuccess() {
        let r: Result<Int, TestError> = .success(3)
        #expect(r.traverse { [$0, $0 * 2] } == [.success(3), .success(6)])
    }

    @Test func sequenceArray() {
        let failure: Result<[Int], TestError> = .failure(.fail)
        #expect(failure.sequence() == [.failure(.fail)])

        let success: Result<[Int], TestError> = .success([1, 2])
        #expect(success.sequence() == [.success(1), .success(2)])
    }

    // MARK: - traverse :: (a -> b?) -> Result a e -> (Result b e)?

    @Test func traverseOptionalFailure() {
        let r: Result<Int, TestError> = .failure(.fail)
        #expect(r.traverse { Optional($0 * 2) } == .some(.failure(.fail)))
    }

    @Test func traverseOptionalSuccessSome() {
        let r: Result<Int, TestError> = .success(3)
        #expect(r.traverse { Optional($0 * 2) } == .some(.success(6)))
    }

    @Test func traverseOptionalSuccessNone() {
        let r: Result<Int, TestError> = .success(3)
        #expect(r.traverse(const(nil as Int?)) == .none)
    }

    @Test func sequenceOptional() {
        let failure: Result<Int?, TestError> = .failure(.fail)
        #expect(failure.sequence() == .some(.failure(.fail)))

        let successSome: Result<Int?, TestError> = .success(.some(5))
        #expect(successSome.sequence() == .some(.success(5)))

        let successNone: Result<Int?, TestError> = .success(.none)
        #expect(successNone.sequence() == .none)
    }

    // MARK: - Free functions

    @Test func freeTraverseArray() {
        let transform = traverse { (n: Int) in [n, n * 10] } as (Result<Int, TestError>) -> [Result<Int, TestError>]
        #expect(transform(.success(2)) == [.success(2), .success(20)])
        #expect(transform(.failure(.fail)) == [.failure(.fail)])
    }

    @Test func freeSequenceArray() {
        let success: Result<[Int], TestError> = .success([1, 2])
        #expect(sequence(success) == [.success(1), .success(2)])
    }

    @Test func freeTraverseOptional() {
        let transform = traverse { (n: Int) in Optional(n * 10) } as (Result<Int, TestError>) -> Result<Int, TestError>?
        #expect(transform(.success(2)) == .some(.success(20)))
        #expect(transform(.failure(.fail)) == .some(.failure(.fail)))
    }

    @Test func freeSequenceOptional() {
        let success: Result<Int?, TestError> = .success(.some(5))
        #expect(sequence(success) == .some(.success(5)))
    }
}
