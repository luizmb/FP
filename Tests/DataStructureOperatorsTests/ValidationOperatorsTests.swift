// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ValidationOperatorsTests {
    // MARK: - Functor operators

    @Test func fmapOperatorSuccess() {
        let v: Validation<String, Int> = .success(5)
        let result = { $0 * 2 } <£> v
        #expect(result == .success(10))
    }

    @Test func fmapOperatorFailure() {
        let v: Validation<String, Int> = .failure("err")
        let result = { $0 * 2 } <£> v
        #expect(result == .failure("err"))
    }

    @Test func flippedFmapOperator() {
        let v: Validation<String, Int> = .success(5)
        #expect((v <&> { $0 + 1 }) == .success(6))
    }

    // MARK: - Applicative operators — the key ones

    @Test func applyOperatorBothSuccess() {
        let fns: Validation<[String], @Sendable (Int) -> Int> = .success { $0 * 3 }
        let vals: Validation<[String], Int> = .success(4)
        #expect((fns <*> vals) == .success(12))
    }

    @Test func applyOperatorAccumulatesErrors() {
        let fns: Validation<[String], @Sendable (Int) -> Int> = .failure(["fn error"])
        let vals: Validation<[String], Int> = .failure(["val error"])
        #expect((fns <*> vals) == .failure(["fn error", "val error"]))
    }

    @Test func seqRightOperatorAccumulatesErrors() {
        let lhs: Validation<[String], Int> = .failure(["left"])
        let rhs: Validation<[String], String> = .failure(["right"])
        #expect((lhs *> rhs) == .failure(["left", "right"]))
    }

    @Test func seqLeftOperatorAccumulatesErrors() {
        let lhs: Validation<[String], Int> = .failure(["left"])
        let rhs: Validation<[String], String> = .failure(["right"])
        #expect((lhs <* rhs) == .failure(["left", "right"]))
    }

    // MARK: - WriterTValidation operators

    @Test func writerTValidationFmapOperator() {
        let w = Writer<[String], Validation<[Int], Int>>(.success(3), ["log"])
        let result = { $0 * 2 } <£^> w
        #expect(result.value == .success(6))
        #expect(result.log == ["log"])
    }

    @Test func writerTValidationFlippedFmapOperator() {
        let w = Writer<[String], Validation<[Int], Int>>(.success(3), ["log"])
        let result = w <&^> { $0 * 2 }
        #expect(result.value == .success(6))
        #expect(result.log == ["log"])
    }

    @Test func writerTValidationApplyOperator() {
        let wf = Writer<[String], Validation<[Int], @Sendable (Int) -> Int>>(.failure([1]), ["l1"])
        let wa = Writer<[String], Validation<[Int], Int>>(.failure([2]), ["l2"])
        let result = wf <*> wa
        #expect(result.value == .failure([1, 2]))
        #expect(result.log == ["l1", "l2"])
    }

    // MARK: - StatefulTValidation operators

    @Test func statefulTValidationApplyOperator() {
        let sf = Stateful<Int, Validation<[String], @Sendable (Int) -> Int>>.pure(.failure(["sf"]))
        let sa = Stateful<Int, Validation<[String], Int>>.pure(.failure(["sa"]))
        var state = 0
        let result = (sf <*> sa).run(&state)
        #expect(result == .failure(["sf", "sa"]))
    }

    // MARK: - ReaderTValidation operators

    @Test func readerTValidationApplyOperator() {
        let rf = Reader<String, Validation<[Int], @Sendable (Int) -> Int>>(const(.failure([1])))
        let ra = Reader<String, Validation<[Int], Int>>(const(.failure([2])))
        let result = (rf <*> ra)("env")
        #expect(result == .failure([1, 2]))
    }
}
