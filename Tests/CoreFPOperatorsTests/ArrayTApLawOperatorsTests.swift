// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import Testing

// `<*>`, `*>`, `<*` on `MaybeT []` / `ExceptT e []` match the bind-derived result (`<*> = ap`).

private enum ApLawError: Error, Equatable {
    case first
    case second
}

@Suite struct ArrayTApLawOperatorsTests {
    @Test func arrayTOptionalOperatorsMatchBind() {
        let fns = ArrayTOptional<@Sendable (Int) -> Int>([{ $0 + 1 }, nil])
        let lhs = ArrayTOptional<Int>([1, nil])
        let rhs = ArrayTOptional<String>(["x", nil, "y"])
        #expect((fns <*> lhs).rawValue == (fns >>- { f in f <£> lhs }).rawValue)
        #expect((fns <*> lhs).rawValue == [2, nil, nil])
        #expect((lhs *> rhs).rawValue == (lhs >>- { (_: Int) in rhs }).rawValue)
        #expect((lhs *> rhs).rawValue == ["x", nil, "y", nil])
        #expect((lhs <* rhs).rawValue == (lhs >>- { n in { (_: String) in n } <£> rhs }).rawValue)
        #expect((lhs <* rhs).rawValue == [1, nil, 1, nil])
    }

    @Test func arrayTResultOperatorsMatchBind() {
        let fns = ArrayTResult<ApLawError, @Sendable (Int) -> Int>([.success { $0 + 1 }, .failure(.first)])
        let lhs = ArrayTResult<ApLawError, Int>([.success(1), .failure(.second)])
        let rhs = ArrayTResult<ApLawError, String>([.success("x"), .failure(.first)])
        #expect((fns <*> lhs).rawValue == (fns >>- { f in f <£> lhs }).rawValue)
        #expect((fns <*> lhs).rawValue == [.success(2), .failure(.second), .failure(.first)])
        #expect((lhs *> rhs).rawValue == (lhs >>- { (_: Int) in rhs }).rawValue)
        #expect((lhs *> rhs).rawValue == [.success("x"), .failure(.first), .failure(.second)])
        #expect((lhs <* rhs).rawValue == (lhs >>- { n in { (_: String) in n } <£> rhs }).rawValue)
        #expect((lhs <* rhs).rawValue == [.success(1), .failure(.first), .failure(.second)])
    }
}
