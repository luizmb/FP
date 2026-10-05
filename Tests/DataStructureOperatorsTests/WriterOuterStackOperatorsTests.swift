// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

// Functor operators (`<£>`, `<&>`, `£>`, `<£`) for the Writer-outer stacks, the flipped monad operators
// (`-<<`, `<=<`) for the `MonadT` ones, and `<*>` on `WriterTAsyncStream` (cartesian `ap`).

private let inc: @Sendable (Int) -> Int = { $0 + 1 }
private let dbl: @Sendable (Int) -> Int = { $0 * 2 }

@Suite struct WriterOuterStackOperatorsTests {
    @Test func writerTArrayFunctorOperators() {
        let m = Writer<[String], [Int]>([1, 2], ["a"]).writerT
        #expect((inc <£> m).rawValue == Writer([2, 3], ["a"]))
        #expect((m <&> inc).rawValue == Writer([2, 3], ["a"]))
        #expect((m £> "x").rawValue == Writer(["x", "x"], ["a"]))
        #expect(("x" <£ m).rawValue == Writer(["x", "x"], ["a"]))
    }

    @Test func writerTNonEmptyFunctorOperators() {
        let m = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1, tail: [2]), ["a"]).writerT
        #expect((inc <£> m).rawValue == Writer(NonEmpty(head: 2, tail: [3]), ["a"]))
        #expect((m <&> inc).rawValue == Writer(NonEmpty(head: 2, tail: [3]), ["a"]))
        #expect((m £> 0).rawValue == Writer(NonEmpty(head: 0, tail: [0]), ["a"]))
        #expect((0 <£ m).rawValue == Writer(NonEmpty(head: 0, tail: [0]), ["a"]))
    }

    @Test func writerTValidationFunctorOperators() {
        let m = Writer<[String], Validation<[String], Int>>(.success(1), ["a"]).writerT
        #expect((inc <£> m).rawValue == Writer(.success(2), ["a"]))
        #expect((m <&> inc).rawValue == Writer(.success(2), ["a"]))
        #expect((m £> 0).rawValue == Writer(.success(0), ["a"]))
        #expect((0 <£ m).rawValue == Writer(.success(0), ["a"]))
    }

    @Test func writerTReaderFunctorOperators() {
        let m = Writer<[String], Reader<Int, Int>>(Reader { $0 }, ["a"]).writerT
        #expect((inc <£> m).rawValue.value.runReader(4) == 5)
        #expect((m <&> inc).rawValue.value.runReader(4) == 5)
        #expect((m £> 0).rawValue.value.runReader(4) == 0)
        #expect((0 <£ m).rawValue.log == ["a"])
    }

    @Test func writerTStatefulFunctorOperators() {
        let m = Writer<[String], Stateful<Int, Int>>(Stateful<Int, Int>.get, ["a"]).writerT
        #expect((inc <£> m).rawValue.value.eval(4) == 5)
        #expect((m <&> inc).rawValue.value.eval(4) == 5)
        #expect((m £> 0).rawValue.value.eval(4) == 0)
        #expect((0 <£ m).rawValue.log == ["a"])
    }

    @Test func writerTEitherOperators() {
        let m = Writer<[String], Either<String, Int>>(.right(1), ["a"]).writerT
        let fn: @Sendable (Int) -> WriterTEither<[String], String, Int> = { n in WriterTEither(Writer(.right(n * 10), ["f"])) }
        #expect((inc <£> m).rawValue == Writer(.right(2), ["a"]))
        #expect((m <&> inc).rawValue == Writer(.right(2), ["a"]))
        #expect((m £> 0).rawValue == Writer(.right(0), ["a"]))
        #expect((0 <£ m).rawValue == Writer(.right(0), ["a"]))
        #expect((fn -<< m).rawValue == Writer(.right(10), ["a", "f"]))
        #expect((fn <=< fn)(1).rawValue == Writer(.right(100), ["f", "f"]))
    }

    @Test func writerTOptionalOperators() {
        let m = Writer<[String], Int?>(.some(1), ["a"]).writerT
        let fn: @Sendable (Int) -> WriterTOptional<[String], Int> = { n in WriterTOptional(Writer(.some(n * 10), ["f"])) }
        #expect((inc <£> m).rawValue == Writer(.some(2), ["a"]))
        #expect((m <&> inc).rawValue == Writer(.some(2), ["a"]))
        #expect((m £> 0).rawValue == Writer(.some(0), ["a"]))
        #expect((0 <£ m).rawValue == Writer(.some(0), ["a"]))
        #expect((fn -<< m).rawValue == Writer(.some(10), ["a", "f"]))
        #expect((fn <=< fn)(1).rawValue == Writer(.some(100), ["f", "f"]))
    }

    @Test func writerTResultOperators() {
        let m = Writer<[String], Result<Int, Never>>(.success(1), ["a"]).writerT
        let fn: @Sendable (Int) -> WriterTResult<[String], Never, Int> = { n in WriterTResult(Writer(.success(n * 10), ["f"])) }
        #expect((inc <£> m).rawValue == Writer(.success(2), ["a"]))
        #expect((m <&> inc).rawValue == Writer(.success(2), ["a"]))
        #expect((m £> 0).rawValue == Writer(.success(0), ["a"]))
        #expect((0 <£ m).rawValue == Writer(.success(0), ["a"]))
        #expect((fn -<< m).rawValue == Writer(.success(10), ["a", "f"]))
        #expect((fn <=< fn)(1).rawValue == Writer(.success(100), ["f", "f"]))
    }

    @Test func writerTAsyncStreamOperators() async {
        let fns = WriterTAsyncStream<[String], @Sendable (Int) -> Int>(Writer(streamOf([inc, dbl]), ["fns"]))
        let xs = WriterTAsyncStream<[String], Int>(Writer(streamOf([10, 20]), ["xs"]))
        let applied = (fns <*> xs).rawValue
        let appliedValues = await collectAll(applied.value)
        #expect(appliedValues == [11, 21, 20, 40])
        #expect(applied.log == ["fns", "xs"])

        let lhs = WriterTAsyncStream<[String], Int>(Writer(streamOf([1, 2]), ["a"]))
        let mapped = (dbl <£> lhs).rawValue
        let mappedValues = await collectAll(mapped.value)
        #expect(mappedValues == [2, 4])
        #expect(mapped.log == ["a"])

        let rhs = WriterTAsyncStream<[String], Int>(Writer(streamOf([10, 20]), ["b"]))
        let right = (WriterTAsyncStream<[String], Int>(Writer(streamOf([1, 2]), ["a"])) *> rhs).rawValue
        let rightValues = await collectAll(right.value)
        #expect(rightValues == [10, 20, 10, 20])
    }
}
