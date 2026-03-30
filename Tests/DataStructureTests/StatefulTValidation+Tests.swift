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

    @Test func flatMapTSuccess() {
        let s = Stateful<Int, Validation<[String], Int>> { state in
            let v = state
            state += 1
            return .success(v)
        }
        let result = flatMapTStatefulValidation(s) { value in
            Stateful<Int, Validation<[String], String>> { state in
                state += value
                return .success("\(value)")
            }
        }
        let (output, finalState) = result.runStateful(5)
        #expect(output == .success("5"))
        #expect(finalState == 11) // 5→6 from first, 6+5=11 from second
    }

    @Test func flatMapTFailureShortCircuits() {
        let s = Stateful<Int, Validation<[String], Int>>.pure(.failure(["err"]))
        let result = flatMapTStatefulValidation(s) { value in
            Stateful<Int, Validation<[String], String>>.pure(.success("\(value)"))
        }
        #expect(result.eval(0) == .failure(["err"]))
    }

    @Test func applyStatefulValidationBothSuccess() {
        let sf = Stateful<Int, Validation<[String], (Int) -> String>>.pure(.success { "\($0)" })
        let sa = Stateful<Int, Validation<[String], Int>>.pure(.success(42))
        let result = applyStatefulValidation(sf, sa)
        #expect(result.eval(0) == .success("42"))
    }

    @Test func applyStatefulValidationAccumulatesErrors() {
        let sf = Stateful<Int, Validation<[String], (Int) -> String>>.pure(.failure(["e1"]))
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
