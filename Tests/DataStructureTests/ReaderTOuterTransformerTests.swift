// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

/// Covers the Reader-outer stacks `ReaderTArray`, `ReaderTOptional`, `ReaderTResult`, and
/// `ReaderTReader` (nested Reader) through the named struct API in `DataStructure` only — no operator syntax.
@Suite struct ReaderTOuterTransformerTests {
    // MARK: - Transformer: ReaderTArray

    struct ArrayEnv { let factor: Int }

    @Test func readerTArrayMap() {
        let stack = ReaderTArray(Reader<ArrayEnv, [Int]> { env in [env.factor, env.factor * 2] })
        let result = stack.map { $0 + 1 }
        #expect(result.rawValue.runReader(ArrayEnv(factor: 3)) == [4, 7])
    }

    @Test func readerTArrayApplySuccess() {
        let stackF = ReaderTArray(Reader<ArrayEnv, [@Sendable (Int) -> Int]> { env in [{ $0 + env.factor }, { $0 * env.factor }] })
        let stackA = ReaderTArray(Reader<ArrayEnv, [Int]>(const([1, 2])))
        let result = ReaderTArray<ArrayEnv, Int>.apply(stackF, stackA)
        #expect(result.rawValue.runReader(ArrayEnv(factor: 10)) == [11, 12, 10, 20])
    }

    @Test func readerTArrayApplyEmptyShortCircuits() {
        let stackF = ReaderTArray(Reader<ArrayEnv, [@Sendable (Int) -> Int]>(const([])))
        let stackA = ReaderTArray(Reader<ArrayEnv, [Int]>(const([1, 2])))
        let result = ReaderTArray<ArrayEnv, Int>.apply(stackF, stackA)
        #expect(result.rawValue.runReader(ArrayEnv(factor: 0)).isEmpty)
    }

    @Test func readerTArrayLiftA2() {
        let stackA = ReaderTArray(Reader<ArrayEnv, [Int]>(const([1, 2])))
        let stackB = ReaderTArray(Reader<ArrayEnv, [Int]>(const([10, 20])))
        let result = ReaderTArray<ArrayEnv, Int>.liftA2 { (a: Int, b: Int) in a + b }(stackA, stackB)
        #expect(result.rawValue.runReader(ArrayEnv(factor: 0)) == [11, 21, 12, 22])
    }

    @Test func readerTArraySeqRight() {
        let lhs = ReaderTArray(Reader<ArrayEnv, [Int]>(const([1, 2])))
        let rhs = ReaderTArray(Reader<ArrayEnv, [String]>(const(["a", "b"])))
        let result = lhs.seqRight(rhs)
        #expect(result.rawValue.runReader(ArrayEnv(factor: 0)) == ["a", "b", "a", "b"])
    }

    @Test func readerTArraySeqLeft() {
        let lhs = ReaderTArray(Reader<ArrayEnv, [Int]>(const([1, 2])))
        let rhs = ReaderTArray(Reader<ArrayEnv, [String]>(const(["a", "b"])))
        let result = lhs.seqLeft(rhs)
        #expect(result.rawValue.runReader(ArrayEnv(factor: 0)) == [1, 1, 2, 2])
    }

    @Test func readerTArrayFlatMapSuccess() {
        let stack = ReaderTArray(Reader<ArrayEnv, [Int]> { env in [env.factor, env.factor * 2] })
        let result = stack.flatMap { n in ReaderTArray(Reader<ArrayEnv, [Int]>(const([n, n + 1]))) }
        #expect(result.rawValue.runReader(ArrayEnv(factor: 3)) == [3, 4, 6, 7])
    }

    @Test func readerTArrayFlatMapEmptyShortCircuits() {
        let stack = ReaderTArray(Reader<ArrayEnv, [Int]>(const([])))
        let result = stack.flatMap { n in ReaderTArray(Reader<ArrayEnv, [Int]>(const([n, n + 1]))) }
        #expect(result.rawValue.runReader(ArrayEnv(factor: 0)).isEmpty)
    }

    // MARK: - Transformer: ReaderTOptional

    struct OptionalEnv { let value: Int }

    @Test func readerTOptionalMap() {
        let stack = ReaderTOptional(Reader<OptionalEnv, Int?> { env in env.value })
        let result = stack.map { $0 * 2 }
        #expect(result.rawValue.runReader(OptionalEnv(value: 5)) == 10)
    }

    @Test func readerTOptionalApplySuccess() {
        let stackF = ReaderTOptional(Reader<OptionalEnv, (@Sendable (Int) -> Int)?> { env in { $0 + env.value } })
        let stackA = ReaderTOptional(Reader<OptionalEnv, Int?>(const(4)))
        let result = ReaderTOptional<OptionalEnv, Int>.apply(stackF, stackA)
        #expect(result.rawValue.runReader(OptionalEnv(value: 10)) == 14)
    }

    @Test func readerTOptionalApplyNilShortCircuits() {
        let stackF = ReaderTOptional(Reader<OptionalEnv, (@Sendable (Int) -> Int)?>(const(nil)))
        let stackA = ReaderTOptional(Reader<OptionalEnv, Int?>(const(4)))
        let result = ReaderTOptional<OptionalEnv, Int>.apply(stackF, stackA)
        #expect(result.rawValue.runReader(OptionalEnv(value: 0)) == nil)
    }

    @Test func readerTOptionalLiftA2() {
        let stackA = ReaderTOptional(Reader<OptionalEnv, Int?>(const(3)))
        let stackB = ReaderTOptional(Reader<OptionalEnv, Int?>(const(4)))
        let result = ReaderTOptional<OptionalEnv, Int>.liftA2 { (a: Int, b: Int) in a + b }(stackA, stackB)
        #expect(result.rawValue.runReader(OptionalEnv(value: 0)) == 7)
    }

    @Test func readerTOptionalLiftA2NilShortCircuits() {
        let stackA = ReaderTOptional(Reader<OptionalEnv, Int?>(const(nil)))
        let stackB = ReaderTOptional(Reader<OptionalEnv, Int?>(const(4)))
        let result = ReaderTOptional<OptionalEnv, Int>.liftA2 { (a: Int, b: Int) in a + b }(stackA, stackB)
        #expect(result.rawValue.runReader(OptionalEnv(value: 0)) == nil)
    }

    @Test func readerTOptionalSeqRight() {
        let lhs = ReaderTOptional(Reader<OptionalEnv, Int?>(const(1)))
        let rhs = ReaderTOptional(Reader<OptionalEnv, String?>(const("a")))
        let result = lhs.seqRight(rhs)
        #expect(result.rawValue.runReader(OptionalEnv(value: 0)) == "a")
    }

    @Test func readerTOptionalSeqLeft() {
        let lhs = ReaderTOptional(Reader<OptionalEnv, Int?>(const(1)))
        let rhs = ReaderTOptional(Reader<OptionalEnv, String?>(const("a")))
        let result = lhs.seqLeft(rhs)
        #expect(result.rawValue.runReader(OptionalEnv(value: 0)) == 1)
    }

    @Test func readerTOptionalFlatMapSuccess() {
        let stack = ReaderTOptional(Reader<OptionalEnv, Int?> { env in env.value })
        let result = stack.flatMap { n in ReaderTOptional(Reader<OptionalEnv, Int?>(const(n + 1))) }
        #expect(result.rawValue.runReader(OptionalEnv(value: 5)) == 6)
    }

    @Test func readerTOptionalFlatMapNilShortCircuits() {
        let stack = ReaderTOptional(Reader<OptionalEnv, Int?>(const(nil)))
        let result = stack.flatMap { n in ReaderTOptional(Reader<OptionalEnv, Int?>(const(n + 1))) }
        #expect(result.rawValue.runReader(OptionalEnv(value: 0)) == nil)
    }

    // MARK: - Transformer: ReaderTResult

    struct ResultEnv { let factor: Int }
    enum ResultTestError: Error, Equatable { case boom }

    @Test func readerTResultMap() {
        let stack = ReaderTResult(Reader<ResultEnv, Result<Int, ResultTestError>> { env in .success(env.factor) })
        let result = stack.map { $0 * 2 }
        #expect(result.rawValue.runReader(ResultEnv(factor: 5)) == .success(10))
    }

    @Test func readerTResultApplySuccess() {
        let stackF = ReaderTResult(Reader<ResultEnv, Result<@Sendable (Int) -> Int, ResultTestError>> { env in
            .success { $0 + env.factor }
        })
        let stackA = ReaderTResult(Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(4))))
        let result = ReaderTResult<ResultEnv, ResultTestError, Int>.apply(stackF, stackA)
        #expect(result.rawValue.runReader(ResultEnv(factor: 10)) == .success(14))
    }

    @Test func readerTResultApplyFailureShortCircuits() {
        let stackF = ReaderTResult(Reader<ResultEnv, Result<@Sendable (Int) -> Int, ResultTestError>>(const(.failure(.boom))))
        let stackA = ReaderTResult(Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(4))))
        let result = ReaderTResult<ResultEnv, ResultTestError, Int>.apply(stackF, stackA)
        #expect(result.rawValue.runReader(ResultEnv(factor: 0)) == .failure(.boom))
    }

    @Test func readerTResultLiftA2() {
        let stackA = ReaderTResult(Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(3))))
        let stackB = ReaderTResult(Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(4))))
        let result = ReaderTResult<ResultEnv, ResultTestError, Int>.liftA2 { (a: Int, b: Int) in a + b }(stackA, stackB)
        #expect(result.rawValue.runReader(ResultEnv(factor: 0)) == .success(7))
    }

    @Test func readerTResultLiftA2FailureShortCircuits() {
        let stackA = ReaderTResult(Reader<ResultEnv, Result<Int, ResultTestError>>(const(.failure(.boom))))
        let stackB = ReaderTResult(Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(4))))
        let result = ReaderTResult<ResultEnv, ResultTestError, Int>.liftA2 { (a: Int, b: Int) in a + b }(stackA, stackB)
        #expect(result.rawValue.runReader(ResultEnv(factor: 0)) == .failure(.boom))
    }

    @Test func readerTResultSeqRight() {
        let lhs = ReaderTResult(Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(1))))
        let rhs = ReaderTResult(Reader<ResultEnv, Result<String, ResultTestError>>(const(.success("a"))))
        let result = lhs.seqRight(rhs)
        #expect(result.rawValue.runReader(ResultEnv(factor: 0)) == .success("a"))
    }

    @Test func readerTResultSeqLeft() {
        let lhs = ReaderTResult(Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(1))))
        let rhs = ReaderTResult(Reader<ResultEnv, Result<String, ResultTestError>>(const(.success("a"))))
        let result = lhs.seqLeft(rhs)
        #expect(result.rawValue.runReader(ResultEnv(factor: 0)) == .success(1))
    }

    @Test func readerTResultFlatMapSuccess() {
        let stack = ReaderTResult(Reader<ResultEnv, Result<Int, ResultTestError>> { env in .success(env.factor) })
        let result = stack.flatMap { n in ReaderTResult(Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(n + 1)))) }
        #expect(result.rawValue.runReader(ResultEnv(factor: 5)) == .success(6))
    }

    @Test func readerTResultFlatMapFailureShortCircuits() {
        let stack = ReaderTResult(Reader<ResultEnv, Result<Int, ResultTestError>>(const(.failure(.boom))))
        let result = stack.flatMap { n in ReaderTResult(Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(n + 1)))) }
        #expect(result.rawValue.runReader(ResultEnv(factor: 0)) == .failure(.boom))
    }

    // MARK: - Transformer: ReaderTReader (nested)

    struct OuterEnv { let factor: Int }
    struct InnerEnv { let offset: Int }

    @Test func readerTReaderMap() {
        let stack = ReaderTReader(Reader<OuterEnv, Reader<InnerEnv, Int>> { outer in
            Reader<InnerEnv, Int> { inner in outer.factor + inner.offset }
        })
        let result = stack.map { $0 * 2 }
        let inner = result.rawValue.runReader(OuterEnv(factor: 3))
        #expect(inner.runReader(InnerEnv(offset: 4)) == 14) // (3 + 4) * 2
    }

    @Test func readerTReaderApply() {
        let stackF = ReaderTReader(Reader<OuterEnv, Reader<InnerEnv, @Sendable (Int) -> Int>> { outer in
            let addFactor: @Sendable (Int) -> Int = { $0 + outer.factor }
            return Reader<InnerEnv, @Sendable (Int) -> Int>(const(addFactor))
        })
        let stackA = ReaderTReader(Reader<OuterEnv, Reader<InnerEnv, Int>>(const(
            Reader<InnerEnv, Int> { inner in inner.offset }
        )))
        let result = ReaderTReader<OuterEnv, InnerEnv, Int>.apply(stackF, stackA)
        let inner = result.rawValue.runReader(OuterEnv(factor: 5))
        #expect(inner.runReader(InnerEnv(offset: 2)) == 7) // inner.offset(2) + outer.factor(5)
    }

    @Test func readerTReaderLiftA2() {
        let stackA = ReaderTReader(Reader<OuterEnv, Reader<InnerEnv, Int>> { outer in
            Reader<InnerEnv, Int>(const(outer.factor))
        })
        let stackB = ReaderTReader(Reader<OuterEnv, Reader<InnerEnv, Int>>(const(
            Reader<InnerEnv, Int> { inner in inner.offset }
        )))
        let result = ReaderTReader<OuterEnv, InnerEnv, Int>.liftA2 { (a: Int, b: Int) in a + b }(stackA, stackB)
        let inner = result.rawValue.runReader(OuterEnv(factor: 5))
        #expect(inner.runReader(InnerEnv(offset: 7)) == 12)
    }

    @Test func readerTReaderSeqRight() {
        let lhs = ReaderTReader(Reader<OuterEnv, Reader<InnerEnv, Int>>(const(Reader<InnerEnv, Int>(const(1)))))
        let rhs = ReaderTReader(Reader<OuterEnv, Reader<InnerEnv, String>>(const(Reader<InnerEnv, String>(const("a")))))
        let result = lhs.seqRight(rhs)
        let inner = result.rawValue.runReader(OuterEnv(factor: 0))
        #expect(inner.runReader(InnerEnv(offset: 0)) == "a")
    }

    @Test func readerTReaderSeqLeft() {
        let lhs = ReaderTReader(Reader<OuterEnv, Reader<InnerEnv, Int>>(const(Reader<InnerEnv, Int>(const(1)))))
        let rhs = ReaderTReader(Reader<OuterEnv, Reader<InnerEnv, String>>(const(Reader<InnerEnv, String>(const("a")))))
        let result = lhs.seqLeft(rhs)
        let inner = result.rawValue.runReader(OuterEnv(factor: 0))
        #expect(inner.runReader(InnerEnv(offset: 0)) == 1)
    }

    @Test func readerTReaderFlatMap() {
        let stack = ReaderTReader(Reader<OuterEnv, Reader<InnerEnv, Int>> { outer in
            Reader<InnerEnv, Int> { inner in outer.factor + inner.offset }
        })
        let result = stack.flatMap { n in
            ReaderTReader(Reader<OuterEnv, Reader<InnerEnv, Int>>(const(Reader<InnerEnv, Int>(const(n * 10)))))
        }
        let inner = result.rawValue.runReader(OuterEnv(factor: 3))
        #expect(inner.runReader(InnerEnv(offset: 4)) == 70) // (3 + 4) * 10
    }
}
