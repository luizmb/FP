// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

/// Covers the 4 Reader-outer monad-transformer combinations that had zero test coverage:
/// `ReaderTArray`, `ReaderTOptional`, `ReaderTResult`, and `ReaderTReader` (nested Reader).
/// These tests exercise the named functions in `DataStructure` only — no operator syntax.
@Suite struct ReaderTOuterTransformerTests {
    // MARK: - Transformer: ReaderTArray

    struct ArrayEnv { let factor: Int }

    @Test func readerTArrayMapT() {
        let reader = Reader<ArrayEnv, [Int]> { env in [env.factor, env.factor * 2] }
        let result = reader.mapT { $0 + 1 }
        #expect(result.runReader(ArrayEnv(factor: 3)) == [4, 7])
    }

    @Test func readerTArrayApplySuccess() {
        let readerF = Reader<ArrayEnv, [@Sendable (Int) -> Int]> { env in [{ $0 + env.factor }, { $0 * env.factor }] }
        let readerA = Reader<ArrayEnv, [Int]>(const([1, 2]))
        let result = applyReaderArray(readerF, readerA)
        #expect(result.runReader(ArrayEnv(factor: 10)) == [11, 12, 10, 20])
    }

    @Test func readerTArrayApplyEmptyShortCircuits() {
        let readerF = Reader<ArrayEnv, [@Sendable (Int) -> Int]>(const([]))
        let readerA = Reader<ArrayEnv, [Int]>(const([1, 2]))
        let result = applyReaderArray(readerF, readerA)
        #expect(result.runReader(ArrayEnv(factor: 0)).isEmpty)
    }

    @Test func readerTArrayLiftA2() {
        let readerA = Reader<ArrayEnv, [Int]>(const([1, 2]))
        let readerB = Reader<ArrayEnv, [Int]>(const([10, 20]))
        let result = liftA2ReaderArray { (a: Int, b: Int) in a + b }(readerA, readerB)
        #expect(result.runReader(ArrayEnv(factor: 0)) == [11, 21, 12, 22])
    }

    @Test func readerTArraySeqRight() {
        let lhs = Reader<ArrayEnv, [Int]>(const([1, 2]))
        let rhs = Reader<ArrayEnv, [String]>(const(["a", "b"]))
        let result = seqRightReaderArray(lhs, rhs)
        #expect(result.runReader(ArrayEnv(factor: 0)) == ["a", "b", "a", "b"])
    }

    @Test func readerTArraySeqLeft() {
        let lhs = Reader<ArrayEnv, [Int]>(const([1, 2]))
        let rhs = Reader<ArrayEnv, [String]>(const(["a", "b"]))
        let result = seqLeftReaderArray(lhs, rhs)
        #expect(result.runReader(ArrayEnv(factor: 0)) == [1, 1, 2, 2])
    }

    @Test func readerTArrayFlatMapTSuccess() {
        let reader = Reader<ArrayEnv, [Int]> { env in [env.factor, env.factor * 2] }
        let result = reader.flatMapT { n in Reader<ArrayEnv, [Int]>(const([n, n + 1])) }
        #expect(result.runReader(ArrayEnv(factor: 3)) == [3, 4, 6, 7])
    }

    @Test func readerTArrayFlatMapTEmptyShortCircuits() {
        let reader = Reader<ArrayEnv, [Int]>(const([]))
        let result = reader.flatMapT { n in Reader<ArrayEnv, [Int]>(const([n, n + 1])) }
        #expect(result.runReader(ArrayEnv(factor: 0)).isEmpty)
    }

    // MARK: - Transformer: ReaderTOptional

    struct OptionalEnv { let value: Int }

    @Test func readerTOptionalMapT() {
        let reader = Reader<OptionalEnv, Int?> { env in env.value }
        let result = reader.mapT { $0 * 2 }
        #expect(result.runReader(OptionalEnv(value: 5)) == 10)
    }

    @Test func readerTOptionalApplySuccess() {
        let readerF = Reader<OptionalEnv, (@Sendable (Int) -> Int)?> { env in { $0 + env.value } }
        let readerA = Reader<OptionalEnv, Int?>(const(4))
        let result = applyReaderOptional(readerF, readerA)
        #expect(result.runReader(OptionalEnv(value: 10)) == 14)
    }

    @Test func readerTOptionalApplyNilShortCircuits() {
        let readerF = Reader<OptionalEnv, (@Sendable (Int) -> Int)?>(const(nil))
        let readerA = Reader<OptionalEnv, Int?>(const(4))
        let result = applyReaderOptional(readerF, readerA)
        #expect(result.runReader(OptionalEnv(value: 0)) == nil)
    }

    @Test func readerTOptionalLiftA2() {
        let readerA = Reader<OptionalEnv, Int?>(const(3))
        let readerB = Reader<OptionalEnv, Int?>(const(4))
        let result = liftA2ReaderOptional { (a: Int, b: Int) in a + b }(readerA, readerB)
        #expect(result.runReader(OptionalEnv(value: 0)) == 7)
    }

    @Test func readerTOptionalLiftA2NilShortCircuits() {
        let readerA = Reader<OptionalEnv, Int?>(const(nil))
        let readerB = Reader<OptionalEnv, Int?>(const(4))
        let result = liftA2ReaderOptional { (a: Int, b: Int) in a + b }(readerA, readerB)
        #expect(result.runReader(OptionalEnv(value: 0)) == nil)
    }

    @Test func readerTOptionalSeqRight() {
        let lhs = Reader<OptionalEnv, Int?>(const(1))
        let rhs = Reader<OptionalEnv, String?>(const("a"))
        let result = seqRightReaderOptional(lhs, rhs)
        #expect(result.runReader(OptionalEnv(value: 0)) == "a")
    }

    @Test func readerTOptionalSeqLeft() {
        let lhs = Reader<OptionalEnv, Int?>(const(1))
        let rhs = Reader<OptionalEnv, String?>(const("a"))
        let result = seqLeftReaderOptional(lhs, rhs)
        #expect(result.runReader(OptionalEnv(value: 0)) == 1)
    }

    @Test func readerTOptionalFlatMapTSuccess() {
        let reader = Reader<OptionalEnv, Int?> { env in env.value }
        let result = reader.flatMapT { n in Reader<OptionalEnv, Int?>(const(n + 1)) }
        #expect(result.runReader(OptionalEnv(value: 5)) == 6)
    }

    @Test func readerTOptionalFlatMapTNilShortCircuits() {
        let reader = Reader<OptionalEnv, Int?>(const(nil))
        let result = reader.flatMapT { n in Reader<OptionalEnv, Int?>(const(n + 1)) }
        #expect(result.runReader(OptionalEnv(value: 0)) == nil)
    }

    // MARK: - Transformer: ReaderTResult

    struct ResultEnv { let factor: Int }
    enum ResultTestError: Error, Equatable { case boom }

    @Test func readerTResultMapT() {
        let reader = Reader<ResultEnv, Result<Int, ResultTestError>> { env in .success(env.factor) }
        let result = reader.mapT { $0 * 2 }
        #expect(result.runReader(ResultEnv(factor: 5)) == .success(10))
    }

    @Test func readerTResultApplySuccess() {
        let readerF = Reader<ResultEnv, Result<@Sendable (Int) -> Int, ResultTestError>> { env in .success { $0 + env.factor } }
        let readerA = Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(4)))
        let result = applyReaderResult(readerF, readerA)
        #expect(result.runReader(ResultEnv(factor: 10)) == .success(14))
    }

    @Test func readerTResultApplyFailureShortCircuits() {
        let readerF = Reader<ResultEnv, Result<@Sendable (Int) -> Int, ResultTestError>>(const(.failure(.boom)))
        let readerA = Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(4)))
        let result = applyReaderResult(readerF, readerA)
        #expect(result.runReader(ResultEnv(factor: 0)) == .failure(.boom))
    }

    @Test func readerTResultLiftA2() {
        let readerA = Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(3)))
        let readerB = Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(4)))
        let result = liftA2ReaderResult { (a: Int, b: Int) in a + b }(readerA, readerB)
        #expect(result.runReader(ResultEnv(factor: 0)) == .success(7))
    }

    @Test func readerTResultLiftA2FailureShortCircuits() {
        let readerA = Reader<ResultEnv, Result<Int, ResultTestError>>(const(.failure(.boom)))
        let readerB = Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(4)))
        let result = liftA2ReaderResult { (a: Int, b: Int) in a + b }(readerA, readerB)
        #expect(result.runReader(ResultEnv(factor: 0)) == .failure(.boom))
    }

    @Test func readerTResultSeqRight() {
        let lhs = Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(1)))
        let rhs = Reader<ResultEnv, Result<String, ResultTestError>>(const(.success("a")))
        let result = seqRightReaderResult(lhs, rhs)
        #expect(result.runReader(ResultEnv(factor: 0)) == .success("a"))
    }

    @Test func readerTResultSeqLeft() {
        let lhs = Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(1)))
        let rhs = Reader<ResultEnv, Result<String, ResultTestError>>(const(.success("a")))
        let result = seqLeftReaderResult(lhs, rhs)
        #expect(result.runReader(ResultEnv(factor: 0)) == .success(1))
    }

    @Test func readerTResultFlatMapTSuccess() {
        let reader = Reader<ResultEnv, Result<Int, ResultTestError>> { env in .success(env.factor) }
        let result = reader.flatMapT { n in Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(n + 1))) }
        #expect(result.runReader(ResultEnv(factor: 5)) == .success(6))
    }

    @Test func readerTResultFlatMapTFailureShortCircuits() {
        let reader = Reader<ResultEnv, Result<Int, ResultTestError>>(const(.failure(.boom)))
        let result = reader.flatMapT { n in Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(n + 1))) }
        #expect(result.runReader(ResultEnv(factor: 0)) == .failure(.boom))
    }

    // MARK: - Transformer: ReaderTReader (nested)

    struct OuterEnv { let factor: Int }
    struct InnerEnv { let offset: Int }

    @Test func readerTReaderMapT() {
        let reader = Reader<OuterEnv, Reader<InnerEnv, Int>> { outer in
            Reader<InnerEnv, Int> { inner in outer.factor + inner.offset }
        }
        let result = reader.mapT { $0 * 2 }
        let inner = result.runReader(OuterEnv(factor: 3))
        #expect(inner.runReader(InnerEnv(offset: 4)) == 14) // (3 + 4) * 2
    }

    @Test func readerTReaderApply() {
        let readerF = Reader<OuterEnv, Reader<InnerEnv, @Sendable (Int) -> Int>> { outer in
            let addFactor: @Sendable (Int) -> Int = { $0 + outer.factor }
            return Reader<InnerEnv, @Sendable (Int) -> Int>(const(addFactor))
        }
        let readerA = Reader<OuterEnv, Reader<InnerEnv, Int>>(const(
            Reader<InnerEnv, Int> { inner in inner.offset }
        ))
        let result = applyReaderReader(readerF, readerA)
        let inner = result.runReader(OuterEnv(factor: 5))
        #expect(inner.runReader(InnerEnv(offset: 2)) == 7) // inner.offset(2) + outer.factor(5)
    }

    @Test func readerTReaderLiftA2() {
        let readerA = Reader<OuterEnv, Reader<InnerEnv, Int>> { outer in
            Reader<InnerEnv, Int>(const(outer.factor))
        }
        let readerB = Reader<OuterEnv, Reader<InnerEnv, Int>>(const(
            Reader<InnerEnv, Int> { inner in inner.offset }
        ))
        let result = liftA2ReaderReader { (a: Int, b: Int) in a + b }(readerA, readerB)
        let inner = result.runReader(OuterEnv(factor: 5))
        #expect(inner.runReader(InnerEnv(offset: 7)) == 12)
    }

    @Test func readerTReaderSeqRight() {
        let lhs = Reader<OuterEnv, Reader<InnerEnv, Int>>(const(Reader<InnerEnv, Int>(const(1))))
        let rhs = Reader<OuterEnv, Reader<InnerEnv, String>>(const(Reader<InnerEnv, String>(const("a"))))
        let result = seqRightReaderReader(lhs, rhs)
        let inner = result.runReader(OuterEnv(factor: 0))
        #expect(inner.runReader(InnerEnv(offset: 0)) == "a")
    }

    @Test func readerTReaderSeqLeft() {
        let lhs = Reader<OuterEnv, Reader<InnerEnv, Int>>(const(Reader<InnerEnv, Int>(const(1))))
        let rhs = Reader<OuterEnv, Reader<InnerEnv, String>>(const(Reader<InnerEnv, String>(const("a"))))
        let result = seqLeftReaderReader(lhs, rhs)
        let inner = result.runReader(OuterEnv(factor: 0))
        #expect(inner.runReader(InnerEnv(offset: 0)) == 1)
    }

    @Test func readerTReaderFlatMapT() {
        let reader = Reader<OuterEnv, Reader<InnerEnv, Int>> { outer in
            Reader<InnerEnv, Int> { inner in outer.factor + inner.offset }
        }
        let result = reader.flatMapT { n in
            Reader<OuterEnv, Reader<InnerEnv, Int>>(const(Reader<InnerEnv, Int>(const(n * 10))))
        }
        let inner = result.runReader(OuterEnv(factor: 3))
        #expect(inner.runReader(InnerEnv(offset: 4)) == 70) // (3 + 4) * 10
    }
}
