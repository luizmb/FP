// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

/// Covers the 4 Reader-outer monad-transformer combinations that had zero operator-syntax
/// coverage: `ReaderTArray`, `ReaderTOptional`, `ReaderTResult`, and `ReaderTReader` (nested
/// Reader). Every assertion below goes through an operator symbol (`<£^>`, `<&^>`, `<*>`, `*>`,
/// `<*`, `>>-`, `-<<`, `>=>`, `<=<`) rather than the underlying named function.
@Suite struct ReaderTOuterTransformerOperatorsTests {
    // MARK: - Transformer: ReaderTArray

    struct ArrayEnv { let factor: Int }

    @Test func readerTArrayFmapOperatorForward() {
        let reader = Reader<ArrayEnv, [Int]> { env in [env.factor, env.factor * 2] }
        let result = { (n: Int) in n + 1 } <£^> reader
        #expect(result.runReader(ArrayEnv(factor: 3)) == [4, 7])
    }

    @Test func readerTArrayFmapOperatorFlipped() {
        let reader = Reader<ArrayEnv, [Int]> { env in [env.factor, env.factor * 2] }
        let result = reader <&^> { $0 + 1 }
        #expect(result.runReader(ArrayEnv(factor: 3)) == [4, 7])
    }

    @Test func readerTArrayApplyOperator() {
        let readerF = Reader<ArrayEnv, [@Sendable (Int) -> Int]> { env in [{ $0 + env.factor }] }
        let readerA = Reader<ArrayEnv, [Int]>(const([1, 2]))
        let result = readerF <*> readerA
        #expect(result.runReader(ArrayEnv(factor: 10)) == [11, 12])
    }

    @Test func readerTArrayApplyOperatorEmptyShortCircuits() {
        let readerF = Reader<ArrayEnv, [@Sendable (Int) -> Int]>(const([]))
        let readerA = Reader<ArrayEnv, [Int]>(const([1, 2]))
        let result = readerF <*> readerA
        #expect(result.runReader(ArrayEnv(factor: 0)).isEmpty)
    }

    @Test func readerTArraySeqRightOperator() {
        let lhs = Reader<ArrayEnv, [Int]>(const([1, 2]))
        let rhs = Reader<ArrayEnv, [String]>(const(["a", "b"]))
        let result = lhs *> rhs
        #expect(result.runReader(ArrayEnv(factor: 0)) == ["a", "b", "a", "b"])
    }

    @Test func readerTArraySeqLeftOperator() {
        let lhs = Reader<ArrayEnv, [Int]>(const([1, 2]))
        let rhs = Reader<ArrayEnv, [String]>(const(["a", "b"]))
        let result = lhs <* rhs
        #expect(result.runReader(ArrayEnv(factor: 0)) == [1, 1, 2, 2])
    }

    @Test func readerTArrayBindOperatorForward() {
        let reader = Reader<ArrayEnv, [Int]> { env in [env.factor, env.factor * 2] }
        let result = reader >>- { n in Reader<ArrayEnv, [Int]>(const([n, n + 1])) }
        #expect(result.runReader(ArrayEnv(factor: 3)) == [3, 4, 6, 7])
    }

    @Test func readerTArrayBindOperatorFlipped() {
        let reader = Reader<ArrayEnv, [Int]> { env in [env.factor, env.factor * 2] }
        let result = { (n: Int) in Reader<ArrayEnv, [Int]>(const([n, n + 1])) } -<< reader
        #expect(result.runReader(ArrayEnv(factor: 3)) == [3, 4, 6, 7])
    }

    @Test func readerTArrayKleisliForward() {
        let step1: @Sendable (Int) -> Reader<ArrayEnv, [Int]> = { n in Reader(const([n, n + 1])) }
        let step2: @Sendable (Int) -> Reader<ArrayEnv, [Int]> = { n in Reader(const([n * 10])) }
        let pipeline = step1 >=> step2
        #expect(pipeline(3).runReader(ArrayEnv(factor: 0)) == [30, 40])
    }

    @Test func readerTArrayKleisliBackward() {
        let step1: @Sendable (Int) -> Reader<ArrayEnv, [Int]> = { n in Reader(const([n, n + 1])) }
        let step2: @Sendable (Int) -> Reader<ArrayEnv, [Int]> = { n in Reader(const([n * 10])) }
        let pipeline = step2 <=< step1
        #expect(pipeline(3).runReader(ArrayEnv(factor: 0)) == [30, 40])
    }

    // MARK: - Transformer: ReaderTOptional

    struct OptionalEnv { let value: Int }

    @Test func readerTOptionalFmapOperatorForward() {
        let reader = Reader<OptionalEnv, Int?> { env in env.value }
        let result = { (n: Int) in n * 2 } <£^> reader
        #expect(result.runReader(OptionalEnv(value: 5)) == 10)
    }

    @Test func readerTOptionalFmapOperatorFlipped() {
        let reader = Reader<OptionalEnv, Int?> { env in env.value }
        let result = reader <&^> { $0 * 2 }
        #expect(result.runReader(OptionalEnv(value: 5)) == 10)
    }

    @Test func readerTOptionalApplyOperator() {
        let readerF = Reader<OptionalEnv, (@Sendable (Int) -> Int)?> { env in { $0 + env.value } }
        let readerA = Reader<OptionalEnv, Int?>(const(4))
        let result = readerF <*> readerA
        #expect(result.runReader(OptionalEnv(value: 10)) == 14)
    }

    @Test func readerTOptionalApplyOperatorNilShortCircuits() {
        let readerF = Reader<OptionalEnv, (@Sendable (Int) -> Int)?>(const(nil))
        let readerA = Reader<OptionalEnv, Int?>(const(4))
        let result = readerF <*> readerA
        #expect(result.runReader(OptionalEnv(value: 0)) == nil)
    }

    @Test func readerTOptionalSeqRightOperator() {
        let lhs = Reader<OptionalEnv, Int?>(const(1))
        let rhs = Reader<OptionalEnv, String?>(const("a"))
        let result = lhs *> rhs
        #expect(result.runReader(OptionalEnv(value: 0)) == "a")
    }

    @Test func readerTOptionalSeqLeftOperator() {
        let lhs = Reader<OptionalEnv, Int?>(const(1))
        let rhs = Reader<OptionalEnv, String?>(const("a"))
        let result = lhs <* rhs
        #expect(result.runReader(OptionalEnv(value: 0)) == 1)
    }

    @Test func readerTOptionalBindOperatorForward() {
        let reader = Reader<OptionalEnv, Int?> { env in env.value }
        let result = reader >>- { n in Reader<OptionalEnv, Int?>(const(n + 1)) }
        #expect(result.runReader(OptionalEnv(value: 5)) == 6)
    }

    @Test func readerTOptionalBindOperatorFlipped() {
        let reader = Reader<OptionalEnv, Int?> { env in env.value }
        let result = { (n: Int) in Reader<OptionalEnv, Int?>(const(n + 1)) } -<< reader
        #expect(result.runReader(OptionalEnv(value: 5)) == 6)
    }

    @Test func readerTOptionalKleisliForward() {
        let step1: @Sendable (Int) -> Reader<OptionalEnv, Int?> = { n in Reader(const(n + 1)) }
        let step2: @Sendable (Int) -> Reader<OptionalEnv, Int?> = { n in Reader(const(n * 10)) }
        let pipeline = step1 >=> step2
        #expect(pipeline(3).runReader(OptionalEnv(value: 0)) == 40)
    }

    @Test func readerTOptionalKleisliBackward() {
        let step1: @Sendable (Int) -> Reader<OptionalEnv, Int?> = { n in Reader(const(n + 1)) }
        let step2: @Sendable (Int) -> Reader<OptionalEnv, Int?> = { n in Reader(const(n * 10)) }
        let pipeline = step2 <=< step1
        #expect(pipeline(3).runReader(OptionalEnv(value: 0)) == 40)
    }

    // MARK: - Transformer: ReaderTResult

    struct ResultEnv { let factor: Int }
    enum ResultTestError: Error, Equatable { case boom }

    @Test func readerTResultFmapOperatorForward() {
        let reader = Reader<ResultEnv, Result<Int, ResultTestError>> { env in .success(env.factor) }
        let result = { (n: Int) in n * 2 } <£^> reader
        #expect(result.runReader(ResultEnv(factor: 5)) == .success(10))
    }

    @Test func readerTResultFmapOperatorFlipped() {
        let reader = Reader<ResultEnv, Result<Int, ResultTestError>> { env in .success(env.factor) }
        let result = reader <&^> { $0 * 2 }
        #expect(result.runReader(ResultEnv(factor: 5)) == .success(10))
    }

    @Test func readerTResultApplyOperator() {
        let readerF = Reader<ResultEnv, Result<@Sendable (Int) -> Int, ResultTestError>> { env in .success { $0 + env.factor } }
        let readerA = Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(4)))
        let result = readerF <*> readerA
        #expect(result.runReader(ResultEnv(factor: 10)) == .success(14))
    }

    @Test func readerTResultApplyOperatorFailureShortCircuits() {
        let readerF = Reader<ResultEnv, Result<@Sendable (Int) -> Int, ResultTestError>>(const(.failure(.boom)))
        let readerA = Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(4)))
        let result = readerF <*> readerA
        #expect(result.runReader(ResultEnv(factor: 0)) == .failure(.boom))
    }

    @Test func readerTResultSeqRightOperator() {
        let lhs = Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(1)))
        let rhs = Reader<ResultEnv, Result<String, ResultTestError>>(const(.success("a")))
        let result = lhs *> rhs
        #expect(result.runReader(ResultEnv(factor: 0)) == .success("a"))
    }

    @Test func readerTResultSeqLeftOperator() {
        let lhs = Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(1)))
        let rhs = Reader<ResultEnv, Result<String, ResultTestError>>(const(.success("a")))
        let result = lhs <* rhs
        #expect(result.runReader(ResultEnv(factor: 0)) == .success(1))
    }

    @Test func readerTResultBindOperatorForward() {
        let reader = Reader<ResultEnv, Result<Int, ResultTestError>> { env in .success(env.factor) }
        let result = reader >>- { n in Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(n + 1))) }
        #expect(result.runReader(ResultEnv(factor: 5)) == .success(6))
    }

    @Test func readerTResultBindOperatorFlipped() {
        let reader = Reader<ResultEnv, Result<Int, ResultTestError>> { env in .success(env.factor) }
        let result = { (n: Int) in Reader<ResultEnv, Result<Int, ResultTestError>>(const(.success(n + 1))) } -<< reader
        #expect(result.runReader(ResultEnv(factor: 5)) == .success(6))
    }

    @Test func readerTResultKleisliForward() {
        let step1: @Sendable (Int) -> Reader<ResultEnv, Result<Int, ResultTestError>> = { n in Reader(const(.success(n + 1))) }
        let step2: @Sendable (Int) -> Reader<ResultEnv, Result<Int, ResultTestError>> = { n in Reader(const(.success(n * 10))) }
        let pipeline = step1 >=> step2
        #expect(pipeline(3).runReader(ResultEnv(factor: 0)) == .success(40))
    }

    @Test func readerTResultKleisliBackward() {
        let step1: @Sendable (Int) -> Reader<ResultEnv, Result<Int, ResultTestError>> = { n in Reader(const(.success(n + 1))) }
        let step2: @Sendable (Int) -> Reader<ResultEnv, Result<Int, ResultTestError>> = { n in Reader(const(.success(n * 10))) }
        let pipeline = step2 <=< step1
        #expect(pipeline(3).runReader(ResultEnv(factor: 0)) == .success(40))
    }

    // MARK: - Transformer: ReaderTReader (nested)

    struct OuterEnv { let factor: Int }
    struct InnerEnv { let offset: Int }

    @Test func readerTReaderFmapOperatorForward() {
        let reader = Reader<OuterEnv, Reader<InnerEnv, Int>> { outer in
            Reader<InnerEnv, Int> { inner in outer.factor + inner.offset }
        }
        let result = { (n: Int) in n * 2 } <£^> reader
        let inner = result.runReader(OuterEnv(factor: 3))
        #expect(inner.runReader(InnerEnv(offset: 4)) == 14)
    }

    @Test func readerTReaderFmapOperatorFlipped() {
        let reader = Reader<OuterEnv, Reader<InnerEnv, Int>> { outer in
            Reader<InnerEnv, Int> { inner in outer.factor + inner.offset }
        }
        let result = reader <&^> { $0 * 2 }
        let inner = result.runReader(OuterEnv(factor: 3))
        #expect(inner.runReader(InnerEnv(offset: 4)) == 14)
    }

    @Test func readerTReaderApplyOperator() {
        let readerF = Reader<OuterEnv, Reader<InnerEnv, @Sendable (Int) -> Int>> { outer in
            let addFactor: @Sendable (Int) -> Int = { $0 + outer.factor }
            return Reader<InnerEnv, @Sendable (Int) -> Int>(const(addFactor))
        }
        let readerA = Reader<OuterEnv, Reader<InnerEnv, Int>>(const(
            Reader<InnerEnv, Int> { inner in inner.offset }
        ))
        let result = readerF <*> readerA
        let inner = result.runReader(OuterEnv(factor: 5))
        #expect(inner.runReader(InnerEnv(offset: 2)) == 7)
    }

    @Test func readerTReaderSeqRightOperator() {
        let lhs = Reader<OuterEnv, Reader<InnerEnv, Int>>(const(Reader<InnerEnv, Int>(const(1))))
        let rhs = Reader<OuterEnv, Reader<InnerEnv, String>>(const(Reader<InnerEnv, String>(const("a"))))
        let result = lhs *> rhs
        let inner = result.runReader(OuterEnv(factor: 0))
        #expect(inner.runReader(InnerEnv(offset: 0)) == "a")
    }

    @Test func readerTReaderSeqLeftOperator() {
        let lhs = Reader<OuterEnv, Reader<InnerEnv, Int>>(const(Reader<InnerEnv, Int>(const(1))))
        let rhs = Reader<OuterEnv, Reader<InnerEnv, String>>(const(Reader<InnerEnv, String>(const("a"))))
        let result = lhs <* rhs
        let inner = result.runReader(OuterEnv(factor: 0))
        #expect(inner.runReader(InnerEnv(offset: 0)) == 1)
    }

    @Test func readerTReaderBindOperatorForward() {
        let reader = Reader<OuterEnv, Reader<InnerEnv, Int>> { outer in
            Reader<InnerEnv, Int> { inner in outer.factor + inner.offset }
        }
        let result = reader >>- { n in
            Reader<OuterEnv, Reader<InnerEnv, Int>>(const(Reader<InnerEnv, Int>(const(n * 10))))
        }
        let inner = result.runReader(OuterEnv(factor: 3))
        #expect(inner.runReader(InnerEnv(offset: 4)) == 70)
    }

    @Test func readerTReaderBindOperatorFlipped() {
        let reader = Reader<OuterEnv, Reader<InnerEnv, Int>> { outer in
            Reader<InnerEnv, Int> { inner in outer.factor + inner.offset }
        }
        let fn: @Sendable (Int) -> Reader<OuterEnv, Reader<InnerEnv, Int>> = { n in
            Reader<OuterEnv, Reader<InnerEnv, Int>>(const(Reader<InnerEnv, Int>(const(n * 10))))
        }
        let result = fn -<< reader
        let inner = result.runReader(OuterEnv(factor: 3))
        #expect(inner.runReader(InnerEnv(offset: 4)) == 70)
    }

    @Test func readerTReaderKleisliForward() {
        let step1: @Sendable (Int) -> Reader<OuterEnv, Reader<InnerEnv, Int>> = { n in
            Reader<OuterEnv, Reader<InnerEnv, Int>>(const(Reader<InnerEnv, Int>(const(n + 1))))
        }
        let step2: @Sendable (Int) -> Reader<OuterEnv, Reader<InnerEnv, Int>> = { n in
            Reader<OuterEnv, Reader<InnerEnv, Int>>(const(Reader<InnerEnv, Int>(const(n * 10))))
        }
        let pipeline = step1 >=> step2
        let inner = pipeline(3).runReader(OuterEnv(factor: 0))
        #expect(inner.runReader(InnerEnv(offset: 0)) == 40)
    }

    @Test func readerTReaderKleisliBackward() {
        let step1: @Sendable (Int) -> Reader<OuterEnv, Reader<InnerEnv, Int>> = { n in
            Reader<OuterEnv, Reader<InnerEnv, Int>>(const(Reader<InnerEnv, Int>(const(n + 1))))
        }
        let step2: @Sendable (Int) -> Reader<OuterEnv, Reader<InnerEnv, Int>> = { n in
            Reader<OuterEnv, Reader<InnerEnv, Int>>(const(Reader<InnerEnv, Int>(const(n * 10))))
        }
        let pipeline = step2 <=< step1
        let inner = pipeline(3).runReader(OuterEnv(factor: 0))
        #expect(inner.runReader(InnerEnv(offset: 0)) == 40)
    }
}
