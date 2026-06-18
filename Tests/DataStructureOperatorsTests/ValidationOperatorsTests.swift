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

    // MARK: - EitherTValidation monad operators

    @Test func eitherTValidationBindOperator() {
        let e: Either<String, Validation<[Int], Int>> = .right(.success(5))
        let result = e >>- { n in Either<String, Validation<[Int], Int>>.right(.success(n * 2)) }
        #expect(result == .right(.success(10)))
    }

    @Test func eitherTValidationKleisli() {
        let f: @Sendable (Int) -> Either<String, Validation<[Int], Int>> = { n in .right(.success(n + 1)) }
        let g: @Sendable (Int) -> Either<String, Validation<[Int], String>> = { n in .right(.success("val: \(n)")) }
        let fg = f >=> g
        #expect(fg(4) == .right(.success("val: 5")))
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

    @Test func writerTValidationBindOperator() {
        let w = Writer<[String], Validation<[Int], Int>>(.success(5), ["start"])
        let result = w >>- { (n: Int) in Writer<[String], Validation<[Int], String>>(.success("got \(n)"), ["end"]) }
        #expect(result.value == .success("got 5"))
        #expect(result.log == ["start", "end"])
    }

    // MARK: - StatefulTValidation operators

    @Test func statefulTValidationApplyOperator() {
        let sf = Stateful<Int, Validation<[String], @Sendable (Int) -> Int>>.pure(.failure(["sf"]))
        let sa = Stateful<Int, Validation<[String], Int>>.pure(.failure(["sa"]))
        var state = 0
        let result = (sf <*> sa).run(&state)
        #expect(result == .failure(["sf", "sa"]))
    }

    @Test func statefulTValidationBindOperator() {
        let s = Stateful<Int, Validation<[String], Int>> { s in s += 1; return .success(s) }
        let result = s >>- { (n: Int) in Stateful<Int, Validation<[String], String>>.pure(.success("n=\(n)")) }
        var state = 0
        #expect(result.run(&state) == .success("n=1"))
    }

    // MARK: - ReaderTValidation operators

    @Test func readerTValidationApplyOperator() {
        let rf = Reader<String, Validation<[Int], @Sendable (Int) -> Int>>(const(.failure([1])))
        let ra = Reader<String, Validation<[Int], Int>>(const(.failure([2])))
        let result = (rf <*> ra)("env")
        #expect(result == .failure([1, 2]))
    }

    @Test func readerTValidationBindOperator() {
        let r = Reader<String, Validation<[Int], Int>> { env in .success(env.count) }
        let result = r >>- { (n: Int) in Reader<String, Validation<[Int], String>>(const(.success("n=\(n)"))) }
        #expect(result("hello") == .success("n=5"))
    }
}
