// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

/// Operator syntax on the Reader-outer stacks that the other operator suites leave uncovered:
/// the functor operators (`<£>`, `<&>`, `£>`, `<£`) on every stack, plus the applicative and
/// monad operators of `ReaderTEither`, `ReaderTAsyncStream`, `ReaderTValidation` and `ReaderTWriter`.
@Suite struct ReaderTStackOperatorsTests {
    private let double: @Sendable (Int) -> Int = { $0 * 2 }

    @Test func readerTArrayFunctorOperators() {
        let stack = ReaderTArray<Int, Int>(Reader { [$0, $0 + 1] })
        #expect((double <£> stack).rawValue(1) == [2, 4])
        #expect((stack <&> double).rawValue(1) == [2, 4])
        #expect((stack £> "x").rawValue(1) == ["x", "x"])
        #expect(("x" <£ stack).rawValue(1) == ["x", "x"])
    }

    @Test func readerTOptionalFunctorOperators() {
        let stack = ReaderTOptional<Int, Int>(Reader { $0 > 0 ? $0 : nil })
        #expect((double <£> stack).rawValue(3) == 6)
        #expect((stack <&> double).rawValue(0) == nil)
        #expect((stack £> "x").rawValue(3) == "x")
        #expect(("x" <£ stack).rawValue(0) == nil)
    }

    @Test func readerTResultFunctorOperators() {
        let stack = ReaderTResult<Int, ReaderTOperatorError, Int>(Reader { $0 > 0 ? .success($0) : .failure(.boom) })
        #expect((double <£> stack).rawValue(3) == .success(6))
        #expect((stack <&> double).rawValue(0) == .failure(.boom))
        #expect((stack £> "x").rawValue(3) == .success("x"))
        #expect(("x" <£ stack).rawValue(0) == .failure(.boom))
    }

    @Test func readerTReaderFunctorOperators() {
        let stack = ReaderTReader<Int, Int, Int>(Reader { env in Reader { env + $0 } })
        #expect((double <£> stack).rawValue(1)(2) == 6)
        #expect((stack <&> double).rawValue(1)(2) == 6)
        #expect((stack £> "x").rawValue(1)(2) == "x")
        #expect(("x" <£ stack).rawValue(1)(2) == "x")
    }

    @Test func readerTNonEmptyFunctorOperators() {
        let stack = ReaderTNonEmpty<Int, Int>(Reader { NonEmpty(head: $0, tail: [$0 + 1]) })
        #expect((double <£> stack).rawValue(1) == NonEmpty(head: 2, tail: [4]))
        #expect((stack <&> double).rawValue(1) == NonEmpty(head: 2, tail: [4]))
        #expect((stack £> "x").rawValue(1) == NonEmpty(head: "x", tail: ["x"]))
        #expect(("x" <£ stack).rawValue(1) == NonEmpty(head: "x", tail: ["x"]))
    }

    @Test func readerTStatefulFunctorOperators() {
        let stack = ReaderTStateful<Int, Int, Int>(Reader { env in
            Stateful { s in
                s += env
                return s
            }
        })
        #expect((double <£> stack).rawValue(2).runStateful(1) == (6, 3))
        #expect((stack <&> double).rawValue(2).runStateful(1) == (6, 3))
        #expect((stack £> "x").rawValue(2).runStateful(1) == ("x", 3))
        #expect(("x" <£ stack).rawValue(2).runStateful(1) == ("x", 3))
    }

    @Test func readerTWriterOperators() {
        let stack = ReaderTWriter<Int, [String], Int>(Reader { Writer($0, ["m"]) })
        let fs = ReaderTWriter<Int, [String], @Sendable (Int) -> Int>(Reader { env in Writer({ $0 + env }, ["fn"]) })
        let next: @Sendable (Int) -> ReaderTWriter<Int, [String], Int> = { a in ReaderTWriter(Reader { Writer(a * $0, ["next"]) }) }
        #expect((double <£> stack).rawValue(3) == Writer(6, ["m"]))
        #expect((stack <&> double).rawValue(3) == Writer(6, ["m"]))
        #expect((stack £> "x").rawValue(3) == Writer("x", ["m"]))
        #expect(("x" <£ stack).rawValue(3) == Writer("x", ["m"]))
        #expect((fs <*> stack).rawValue(3) == Writer(6, ["fn", "m"]))
        #expect((next >=> next)(2).rawValue(3) == Writer(18, ["next", "next"]))
        #expect((next <=< next)(2).rawValue(3) == Writer(18, ["next", "next"]))
    }

    @Test func readerTEitherOperators() {
        let stack = ReaderTEither<Int, String, Int>(Reader { $0 > 0 ? .right($0) : .left("small") })
        let next: @Sendable (Int) -> ReaderTEither<Int, String, Int> = { a in
            ReaderTEither(Reader { env in a > 10 ? .left("big") : .right(a * env) })
        }
        #expect((double <£> stack).rawValue(3) == .right(6))
        #expect((stack <&> double).rawValue(0) == .left("small"))
        #expect((stack £> "x").rawValue(3) == .right("x"))
        #expect(("x" <£ stack).rawValue(0) == .left("small"))
        #expect((stack >>- next).rawValue(3) == .right(9))
        #expect((next -<< stack).rawValue(0) == .left("small"))
        #expect((next >=> next)(2).rawValue(3) == .right(18))
        #expect((next <=< next)(4).rawValue(3) == .left("big"))
    }

    @Test func readerTValidationOperators() {
        let left = ReaderTValidation<Int, [String], Int>(Reader { .failure(["l\($0)"]) })
        let right = ReaderTValidation<Int, [String], Int>(Reader { .failure(["r\($0)"]) })
        let valid = ReaderTValidation<Int, [String], Int>(Reader { .success($0) })
        #expect((double <£> valid).rawValue(3) == .success(6))
        #expect((valid <&> double).rawValue(3) == .success(6))
        #expect((valid £> "x").rawValue(3) == .success("x"))
        #expect(("x" <£ left).rawValue(3) == .failure(["l3"]))
        #expect((left *> right).rawValue(1) == .failure(["l1", "r1"]))
        #expect((left <* right).rawValue(1) == .failure(["l1", "r1"]))
        #expect((valid *> valid).rawValue(1) == .success(1))
    }

    @Test func readerTAsyncStreamOperators() async {
        let stack = ReaderTAsyncStream<Int, Int>(Reader { streamOf([$0, $0 + 1]) })
        let fs = ReaderTAsyncStream<Int, @Sendable (Int) -> Int>(Reader { env in streamOf([{ $0 + env }, { $0 * 10 }]) })
        let next: @Sendable (Int) -> ReaderTAsyncStream<Int, Int> = { a in ReaderTAsyncStream(Reader { streamOf([a, a * $0]) }) }
        let double = double
        let mapped = await collectAll((double <£> stack).rawValue(1))
        let flippedMapped = await collectAll((stack <&> double).rawValue(1))
        let replaced = await collectAll((stack £> 0).rawValue(1))
        let flippedReplaced = await collectAll((0 <£ stack).rawValue(1))
        let applied = await collectAll((fs <*> stack).rawValue(1))
        let composed = await collectAll((next >=> next)(2).rawValue(3))
        let flippedComposed = await collectAll((next <=< next)(2).rawValue(3))
        #expect(mapped == [2, 4])
        #expect(flippedMapped == [2, 4])
        #expect(replaced == [0, 0])
        #expect(flippedReplaced == [0, 0])
        #expect(applied == [2, 3, 10, 20])
        #expect(composed == [2, 6, 6, 18])
        #expect(flippedComposed == [2, 6, 6, 18])
    }
}

enum ReaderTOperatorError: Error, Equatable {
    case boom
}
