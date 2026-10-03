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
        let fns: [(@Sendable (Int) -> Int)?] = [{ $0 + 1 }, nil]
        let lhs: [Int?] = [1, nil]
        let rhs: [String?] = ["x", nil, "y"]
        #expect((fns <*> lhs) == (fns >>- { f in lhs.mapT(f) }))
        #expect((fns <*> lhs) == [2, nil, nil])
        #expect((lhs *> rhs) == (lhs >>- { (_: Int) in rhs }))
        #expect((lhs *> rhs) == ["x", nil, "y", nil])
        #expect((lhs <* rhs) == (lhs >>- { n in rhs.mapT { (_: String) in n } }))
        #expect((lhs <* rhs) == [1, nil, 1, nil])
    }

    @Test func arrayTResultOperatorsMatchBind() {
        let fns: [Result<@Sendable (Int) -> Int, ApLawError>] = [.success { $0 + 1 }, .failure(.first)]
        let lhs: [Result<Int, ApLawError>] = [.success(1), .failure(.second)]
        let rhs: [Result<String, ApLawError>] = [.success("x"), .failure(.first)]
        #expect((fns <*> lhs) == (fns >>- { f in lhs.mapT(f) }))
        #expect((fns <*> lhs) == [.success(2), .failure(.second), .failure(.first)])
        #expect((lhs *> rhs) == (lhs >>- { (_: Int) in rhs }))
        #expect((lhs *> rhs) == [.success("x"), .failure(.first), .failure(.second)])
        #expect((lhs <* rhs) == (lhs >>- { n in rhs.mapT { (_: String) in n } }))
        #expect((lhs <* rhs) == [.success(1), .failure(.first), .failure(.second)])
    }
}
