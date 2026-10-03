// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

// `<*>`, `*>` and `<*` on `Stateful<S, Either/Optional/Result>` must match bind (`>>-`): a failed
// left-hand side keeps its own state update but never runs the right-hand state effect.

private enum ApError: Error, Equatable {
    case function
    case lhs
}

private func step<A: Sendable>(_ update: @escaping @Sendable (Int) -> Int, _ output: A) -> Stateful<Int, A> {
    Stateful<Int, A> { s in
        s = update(s)
        return output
    }
}

@Suite struct StatefulTInnerApOperatorsTests {
    @Test func eitherOperatorsMatchBind() {
        let sf: Stateful<Int, Either<String, @Sendable (Int) -> Int>> = step({ $0 + 1 }, .left("e"))
        let failed: Stateful<Int, Either<String, Int>> = step({ $0 + 1 }, .left("e"))
        let sa: Stateful<Int, Either<String, Int>> = step({ $0 + 10 }, .right(1))

        let applied = (sf <*> sa).runStateful(0)
        let bound = (sf >>- { f in sa.mapT(f) }).runStateful(0)
        #expect(applied.0 == .left("e"))
        #expect(applied.1 == 1)
        #expect(applied.0 == bound.0)
        #expect(applied.1 == bound.1)

        let right = (failed *> sa).runStateful(0)
        #expect(right.0 == .left("e"))
        #expect(right.1 == 1)

        let left = (failed <* sa).runStateful(0)
        #expect(left.0 == .left("e"))
        #expect(left.1 == 1)
    }

    @Test func optionalOperatorsMatchBind() {
        let sf: Stateful<Int, (@Sendable (Int) -> Int)?> = step({ $0 + 1 }, nil)
        let failed: Stateful<Int, Int?> = step({ $0 + 1 }, nil)
        let sa: Stateful<Int, Int?> = step({ $0 + 10 }, .some(1))

        let applied = (sf <*> sa).runStateful(0)
        let bound = (sf >>- { f in sa.mapT(f) }).runStateful(0)
        #expect(applied.0 == nil)
        #expect(applied.1 == 1)
        #expect(applied.0 == bound.0)
        #expect(applied.1 == bound.1)

        let right = (failed *> sa).runStateful(0)
        #expect(right.0 == nil)
        #expect(right.1 == 1)

        let left = (failed <* sa).runStateful(0)
        #expect(left.0 == nil)
        #expect(left.1 == 1)
    }

    @Test func resultOperatorsMatchBind() {
        let sf: Stateful<Int, Result<@Sendable (Int) -> Int, ApError>> = step({ $0 + 1 }, .failure(.function))
        let failed: Stateful<Int, Result<Int, ApError>> = step({ $0 + 1 }, .failure(.lhs))
        let sa: Stateful<Int, Result<Int, ApError>> = step({ $0 + 10 }, .success(1))

        let applied = (sf <*> sa).runStateful(0)
        let bound = (sf >>- { f in sa.mapT(f) }).runStateful(0)
        #expect(applied.0 == .failure(.function))
        #expect(applied.1 == 1)
        #expect(applied.0 == bound.0)
        #expect(applied.1 == bound.1)

        let right = (failed *> sa).runStateful(0)
        #expect(right.0 == .failure(.lhs))
        #expect(right.1 == 1)

        let left = (failed <* sa).runStateful(0)
        #expect(left.0 == .failure(.lhs))
        #expect(left.1 == 1)
    }
}
