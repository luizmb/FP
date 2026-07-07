// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct StatefulTValidationTests {
    // MARK: - Stateful<S, Validation<E, A>> — State as outer, Validation as inner

    @Test func mapTSuccess() {
        let s = Stateful<Int, Validation<[String], Int>>.pure(.success(5))
        let mapped = fmapTStatefulValidation({ $0 * 2 }, s)
        #expect(mapped.eval(0) == .success(10))
    }

    @Test func mapTFailure() {
        let s = Stateful<Int, Validation<[String], Int>>.pure(.failure(["err"]))
        let mapped = fmapTStatefulValidation({ $0 * 2 }, s)
        #expect(mapped.eval(0) == .failure(["err"]))
    }

    @Test func applyStatefulValidationBothSuccess() {
        let sf = Stateful<Int, Validation<[String], @Sendable (Int) -> String>>.pure(.success { "\($0)" })
        let sa = Stateful<Int, Validation<[String], Int>>.pure(.success(42))
        let result = applyStatefulValidation(sf, sa)
        #expect(result.eval(0) == .success("42"))
    }

    @Test func applyStatefulValidationAccumulatesErrors() {
        let sf = Stateful<Int, Validation<[String], @Sendable (Int) -> String>>.pure(.failure(["e1"]))
        let sa = Stateful<Int, Validation<[String], Int>>.pure(.failure(["e2"]))
        let result = applyStatefulValidation(sf, sa)
        #expect(result.eval(0) == .failure(["e1", "e2"]))
    }

    @Test func seqRightStatefulValidationBothSuccess() {
        let lhs = Stateful<Int, Validation<[String], Int>>.pure(.success(1))
        let rhs = Stateful<Int, Validation<[String], String>>.pure(.success("done"))
        let result = seqRightStatefulValidation(lhs, rhs)
        #expect(result.eval(0) == .success("done"))
    }

    @Test func seqLeftStatefulValidationBothSuccess() {
        let lhs = Stateful<Int, Validation<[String], Int>>.pure(.success(1))
        let rhs = Stateful<Int, Validation<[String], String>>.pure(.success("done"))
        let result = seqLeftStatefulValidation(lhs, rhs)
        #expect(result.eval(0) == .success(1))
    }
}
