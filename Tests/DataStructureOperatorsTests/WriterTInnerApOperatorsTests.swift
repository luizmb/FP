// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

// `<*>`, `*>` and `<*` on `Writer<W, Either/Optional/Result>` must match bind (`>>-`): a failed
// left-hand side keeps its own log but never appends the right-hand log.

private enum ApError: Error, Equatable {
    case function
    case lhs
}

@Suite struct WriterTInnerApOperatorsTests {
    @Test func eitherOperatorsMatchBind() {
        let wf = Writer<[String], Either<String, @Sendable (Int) -> Int>>(.left("e"), ["f"])
        let failed = Writer<[String], Either<String, Int>>(.left("e"), ["f"])
        let wa = Writer<[String], Either<String, Int>>(.right(1), ["a"])

        #expect((wf <*> wa) == Writer(.left("e"), ["f"]))
        #expect((wf <*> wa) == (wf >>- { f in wa.mapT(f) }))
        #expect((failed *> wa) == Writer(.left("e"), ["f"]))
        #expect((failed <* wa) == Writer(.left("e"), ["f"]))
    }

    @Test func optionalOperatorsMatchBind() {
        let wf = Writer<[String], (@Sendable (Int) -> Int)?>(nil, ["f"])
        let failed = Writer<[String], Int?>(nil, ["f"])
        let wa = Writer<[String], Int?>(.some(1), ["a"])

        #expect((wf <*> wa) == Writer(nil, ["f"]))
        #expect((wf <*> wa) == (wf >>- { f in wa.mapT(f) }))
        #expect((failed *> wa) == Writer(nil, ["f"]))
        #expect((failed <* wa) == Writer(nil, ["f"]))
    }

    @Test func resultOperatorsMatchBind() {
        let wf = Writer<[String], Result<@Sendable (Int) -> Int, ApError>>(.failure(.function), ["f"])
        let failed = Writer<[String], Result<Int, ApError>>(.failure(.lhs), ["f"])
        let wa = Writer<[String], Result<Int, ApError>>(.success(1), ["a"])

        #expect((wf <*> wa) == Writer(.failure(.function), ["f"]))
        #expect((wf <*> wa) == (wf >>- { f in wa.mapT(f) }))
        #expect((failed *> wa) == Writer(.failure(.lhs), ["f"]))
        #expect((failed <* wa) == Writer(.failure(.lhs), ["f"]))
    }
}
