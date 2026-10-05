// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

// `<*>`, `*>` and `<*` on `WriterTEither` / `WriterTOptional` / `WriterTResult` must match bind (`>>-`): a failed
// left-hand side keeps its own log but never appends the right-hand log.

private enum ApError: Error, Equatable {
    case function
    case lhs
}

@Suite struct WriterTInnerApOperatorsTests {
    @Test func eitherOperatorsMatchBind() {
        let wf = WriterTEither<[String], String, @Sendable (Int) -> Int>(Writer(.left("e"), ["f"]))
        let failed = WriterTEither<[String], String, Int>(Writer(.left("e"), ["f"]))
        let wa = WriterTEither<[String], String, Int>(Writer(.right(1), ["a"]))

        #expect((wf <*> wa).rawValue == Writer(.left("e"), ["f"]))
        #expect((wf <*> wa).rawValue == (wf >>- { f in f <£> wa }).rawValue)
        #expect((failed *> wa).rawValue == Writer(.left("e"), ["f"]))
        #expect((failed <* wa).rawValue == Writer(.left("e"), ["f"]))
    }

    @Test func optionalOperatorsMatchBind() {
        let wf = WriterTOptional<[String], @Sendable (Int) -> Int>(Writer(nil, ["f"]))
        let failed = WriterTOptional<[String], Int>(Writer(nil, ["f"]))
        let wa = WriterTOptional<[String], Int>(Writer(.some(1), ["a"]))

        #expect((wf <*> wa).rawValue == Writer(nil, ["f"]))
        #expect((wf <*> wa).rawValue == (wf >>- { f in f <£> wa }).rawValue)
        #expect((failed *> wa).rawValue == Writer(nil, ["f"]))
        #expect((failed <* wa).rawValue == Writer(nil, ["f"]))
    }

    @Test func resultOperatorsMatchBind() {
        let wf = WriterTResult<[String], ApError, @Sendable (Int) -> Int>(Writer(.failure(.function), ["f"]))
        let failed = WriterTResult<[String], ApError, Int>(Writer(.failure(.lhs), ["f"]))
        let wa = WriterTResult<[String], ApError, Int>(Writer(.success(1), ["a"]))

        #expect((wf <*> wa).rawValue == Writer(.failure(.function), ["f"]))
        #expect((wf <*> wa).rawValue == (wf >>- { f in f <£> wa }).rawValue)
        #expect((failed *> wa).rawValue == Writer(.failure(.lhs), ["f"]))
        #expect((failed <* wa).rawValue == Writer(.failure(.lhs), ["f"]))
    }
}
