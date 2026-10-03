// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

// `<*>`, `*>`, `<*` on `ExceptT l []`, `MaybeT NonEmpty`, `ExceptT e NonEmpty` match the
// bind-derived result (`<*> = ap`).

private enum ApLawError: Error, Equatable {
    case first
    case second
}

@Suite struct ArrayTNonEmptyTApLawOperatorsTests {
    @Test func arrayTEitherOperatorsMatchBind() {
        let fns: [Either<String, @Sendable (Int) -> Int>] = [.right { $0 + 1 }, .left("f")]
        let lhs: [Either<String, Int>] = [.right(1), .left("a")]
        let rhs: [Either<String, String>] = [.right("x"), .left("s")]
        #expect((fns <*> lhs) == (fns >>- { f in lhs.mapT(f) }))
        #expect((fns <*> lhs) == [.right(2), .left("a"), .left("f")])
        #expect((lhs *> rhs) == (lhs >>- { (_: Int) in rhs }))
        #expect((lhs *> rhs) == [.right("x"), .left("s"), .left("a")])
        #expect((lhs <* rhs) == (lhs >>- { n in rhs.mapT { (_: String) in n } }))
        #expect((lhs <* rhs) == [.right(1), .left("s"), .left("a")])
    }

    @Test func nonEmptyTEitherOperatorsMatchBind() {
        let fns = NonEmpty<Either<String, @Sendable (Int) -> Int>>(head: .left("f"), tail: [.right { $0 + 1 }])
        let lhs = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.left("a")])
        let rhs = NonEmpty<Either<String, String>>(head: .right("x"), tail: [.left("s")])
        #expect((fns <*> lhs).toArray == (fns >>- { f in lhs.mapT(f) }).toArray)
        #expect((fns <*> lhs).toArray == [.left("f"), .right(2), .left("a")])
        #expect((lhs *> rhs).toArray == (lhs >>- { (_: Int) in rhs }).toArray)
        #expect((lhs *> rhs).toArray == [.right("x"), .left("s"), .left("a")])
        #expect((lhs <* rhs).toArray == (lhs >>- { n in rhs.mapT { (_: String) in n } }).toArray)
        #expect((lhs <* rhs).toArray == [.right(1), .left("s"), .left("a")])
    }

    @Test func nonEmptyTOptionalOperatorsMatchBind() {
        let fns = NonEmpty<(@Sendable (Int) -> Int)?>(head: nil, tail: [{ $0 + 1 }])
        let lhs = NonEmpty<Int?>(head: 1, tail: [nil])
        let rhs = NonEmpty<String?>(head: "x", tail: [nil])
        #expect((fns <*> lhs).toArray == (fns >>- { f in lhs.mapT(f) }).toArray)
        #expect((fns <*> lhs).toArray == [nil, 2, nil])
        #expect((lhs *> rhs).toArray == (lhs >>- { (_: Int) in rhs }).toArray)
        #expect((lhs *> rhs).toArray == ["x", nil, nil])
        #expect((lhs <* rhs).toArray == (lhs >>- { n in rhs.mapT { (_: String) in n } }).toArray)
        #expect((lhs <* rhs).toArray == [1, nil, nil])
    }

    @Test func nonEmptyTResultOperatorsMatchBind() {
        let fns = NonEmpty<Result<@Sendable (Int) -> Int, ApLawError>>(head: .failure(.first), tail: [.success { $0 + 1 }])
        let lhs = NonEmpty<Result<Int, ApLawError>>(head: .success(1), tail: [.failure(.second)])
        let rhs = NonEmpty<Result<String, ApLawError>>(head: .success("x"), tail: [.failure(.first)])
        #expect((fns <*> lhs).toArray == (fns >>- { f in lhs.mapT(f) }).toArray)
        #expect((fns <*> lhs).toArray == [.failure(.first), .success(2), .failure(.second)])
        #expect((lhs *> rhs).toArray == (lhs >>- { (_: Int) in rhs }).toArray)
        #expect((lhs *> rhs).toArray == [.success("x"), .failure(.first), .failure(.second)])
        #expect((lhs <* rhs).toArray == (lhs >>- { n in rhs.mapT { (_: String) in n } }).toArray)
        #expect((lhs <* rhs).toArray == [.success(1), .failure(.first), .failure(.second)])
    }
}
