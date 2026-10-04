// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

// `<*>`, `*>` and `<*` on the Either/Optional-outer stacks must match the bind-derived result
// on mixed-failure inputs (the first failure in left-to-right order wins).

private enum StackError: Error, Equatable {
    case fromLhs
    case fromRhs
}

@Suite struct EitherOptionalStacksApOperatorTests {
    // MARK: - EitherTOptional

    @Test func eitherTOptionalOperatorsMatchBind() {
        let fns: Either<String, (@Sendable (Int) -> Int)?> = .right(nil)
        let lhs: Either<String, Int?> = .right(nil)
        let rhs: Either<String, Int?> = .left("rhs")
        #expect((fns <*> rhs) == flatMapTEitherOptional(fns) { fn in rhs.mapT(fn) })
        #expect((fns <*> rhs) == .right(nil))
        #expect((lhs *> rhs) == .right(nil))
        #expect((lhs <* rhs) == .right(nil))
    }

    // MARK: - EitherTResult

    @Test func eitherTResultOperatorsMatchBind() {
        let fns: Either<String, Result<@Sendable (Int) -> Int, StackError>> = .right(.failure(.fromLhs))
        let lhs: Either<String, Result<Int, StackError>> = .right(.failure(.fromLhs))
        let rhs: Either<String, Result<Int, StackError>> = .left("rhs")
        #expect((fns <*> rhs) == flatMapTEitherResult(fns) { fn in rhs.mapT(fn) })
        #expect((fns <*> rhs) == .right(.failure(.fromLhs)))
        #expect((lhs *> rhs) == .right(.failure(.fromLhs)))
        #expect((lhs <* rhs) == .right(.failure(.fromLhs)))
    }

    // MARK: - OptionalTEither

    @Test func optionalTEitherOperatorsMatchBind() {
        let fns: Either<String, @Sendable (Int) -> Int>? = .some(.left("lhs"))
        let lhs: Either<String, Int>? = .some(.left("lhs"))
        let rhs: Either<String, Int>? = nil
        #expect((fns <*> rhs) == fns.flatMapT { fn in rhs.mapT(fn) })
        #expect((fns <*> rhs) == .some(.left("lhs")))
        #expect((lhs *> rhs) == .some(.left("lhs")))
        #expect((lhs <* rhs) == .some(.left("lhs")))
    }
}
