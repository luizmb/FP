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
        let fns: ArrayTEither<String, @Sendable (Int) -> Int> = ArrayTEither([.right { $0 + 1 }, .left("f")])
        let lhs: ArrayTEither<String, Int> = ArrayTEither([.right(1), .left("a")])
        let rhs: ArrayTEither<String, String> = ArrayTEither([.right("x"), .left("s")])
        #expect((fns <*> lhs).rawValue == (fns >>- { f in f <£> lhs }).rawValue)
        #expect((fns <*> lhs).rawValue == [.right(2), .left("a"), .left("f")])
        #expect((lhs *> rhs).rawValue == (lhs >>- { (_: Int) in rhs }).rawValue)
        #expect((lhs *> rhs).rawValue == [.right("x"), .left("s"), .left("a")])
        #expect((lhs <* rhs).rawValue == (lhs >>- { n in rhs <&> { (_: String) in n } }).rawValue)
        #expect((lhs <* rhs).rawValue == [.right(1), .left("s"), .left("a")])
    }

    @Test func nonEmptyTEitherOperatorsMatchBind() {
        let fns = NonEmpty<Either<String, @Sendable (Int) -> Int>>(head: .left("f"), tail: [.right { $0 + 1 }]).nonEmptyT
        let lhs = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.left("a")]).nonEmptyT
        let rhs = NonEmpty<Either<String, String>>(head: .right("x"), tail: [.left("s")]).nonEmptyT
        #expect((fns <*> lhs).rawValue.toArray == (fns >>- { f in f <£> lhs }).rawValue.toArray)
        #expect((fns <*> lhs).rawValue.toArray == [.left("f"), .right(2), .left("a")])
        #expect((lhs *> rhs).rawValue.toArray == (lhs >>- { (_: Int) in rhs }).rawValue.toArray)
        #expect((lhs *> rhs).rawValue.toArray == [.right("x"), .left("s"), .left("a")])
        #expect((lhs <* rhs).rawValue.toArray == (lhs >>- { n in rhs <&> { (_: String) in n } }).rawValue.toArray)
        #expect((lhs <* rhs).rawValue.toArray == [.right(1), .left("s"), .left("a")])
    }

    @Test func nonEmptyTOptionalOperatorsMatchBind() {
        let fns = NonEmpty<(@Sendable (Int) -> Int)?>(head: nil, tail: [{ $0 + 1 }]).nonEmptyT
        let lhs = NonEmpty<Int?>(head: 1, tail: [nil]).nonEmptyT
        let rhs = NonEmpty<String?>(head: "x", tail: [nil]).nonEmptyT
        #expect((fns <*> lhs).rawValue.toArray == (fns >>- { f in f <£> lhs }).rawValue.toArray)
        #expect((fns <*> lhs).rawValue.toArray == [nil, 2, nil])
        #expect((lhs *> rhs).rawValue.toArray == (lhs >>- { (_: Int) in rhs }).rawValue.toArray)
        #expect((lhs *> rhs).rawValue.toArray == ["x", nil, nil])
        #expect((lhs <* rhs).rawValue.toArray == (lhs >>- { n in rhs <&> { (_: String) in n } }).rawValue.toArray)
        #expect((lhs <* rhs).rawValue.toArray == [1, nil, nil])
    }

    @Test func nonEmptyTResultOperatorsMatchBind() {
        let fns = NonEmpty<Result<@Sendable (Int) -> Int, ApLawError>>(head: .failure(.first), tail: [.success { $0 + 1 }]).nonEmptyT
        let lhs = NonEmpty<Result<Int, ApLawError>>(head: .success(1), tail: [.failure(.second)]).nonEmptyT
        let rhs = NonEmpty<Result<String, ApLawError>>(head: .success("x"), tail: [.failure(.first)]).nonEmptyT
        #expect((fns <*> lhs).rawValue.toArray == (fns >>- { f in f <£> lhs }).rawValue.toArray)
        #expect((fns <*> lhs).rawValue.toArray == [.failure(.first), .success(2), .failure(.second)])
        #expect((lhs *> rhs).rawValue.toArray == (lhs >>- { (_: Int) in rhs }).rawValue.toArray)
        #expect((lhs *> rhs).rawValue.toArray == [.success("x"), .failure(.first), .failure(.second)])
        #expect((lhs <* rhs).rawValue.toArray == (lhs >>- { n in rhs <&> { (_: String) in n } }).rawValue.toArray)
        #expect((lhs <* rhs).rawValue.toArray == [.success(1), .failure(.first), .failure(.second)])
    }
}
