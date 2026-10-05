// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

/// Smoke tests for the generated newtype stacks (operator syntax), one representative per family.
@Suite struct TransformerStackOperatorSmokeTests {
    @Test func readerTArrayOperators() {
        let stack = ReaderTArray<Int, Int>(Reader { [$0, $0 + 1] })
        let double: @Sendable (Int) -> Int = { $0 * 2 }
        let next: @Sendable (Int) -> ReaderTArray<Int, Int> = { a in ReaderTArray(Reader { [a + $0] }) }

        #expect((double <£> stack).rawValue(1) == [2, 4])
        #expect((stack <&> double).rawValue(1) == [2, 4])
        #expect((stack £> 0).rawValue(1) == [0, 0])
        #expect((0 <£ stack).rawValue(1) == [0, 0])
        #expect((ReaderTArray<Int, @Sendable (Int) -> Int>.pure(double) <*> stack).rawValue(1) == [2, 4])
        #expect((stack *> stack).rawValue(1) == stack.seqRight(stack).rawValue(1))
        #expect((stack <* stack).rawValue(1) == stack.seqLeft(stack).rawValue(1))
        #expect((stack >>- next).rawValue(1) == [2, 3])
        #expect((next -<< stack).rawValue(1) == [2, 3])
        #expect((next >=> next)(1).rawValue(1) == [3])
        #expect((next <=< next)(1).rawValue(1) == [3])
    }

    @Test func optionalTWriterOperators() {
        let stack = OptionalTWriter<[String], Int>(Writer(1, ["one"]))
        let next: @Sendable (Int) -> OptionalTWriter<[String], Int> = { OptionalTWriter(Writer($0 + 1, ["inc"])) }

        #expect((stack >>- next).rawValue == Writer(2, ["one", "inc"]))
        #expect((stack <&> { $0 * 3 }).rawValue == Writer(3, ["one"]))
    }

    @Test func validationTArrayOperators() {
        let left = ValidationTArray<[String], Int>(.failure(["a"]))
        let right = ValidationTArray<[String], Int>(.failure(["b"]))

        #expect((left *> right).rawValue == .failure(["a", "b"]))
        #expect((left <* right).rawValue == .failure(["a", "b"]))
        #expect(({ $0 + 1 } <£> ValidationTArray<[String], Int>(.success([1]))).rawValue == .success([2]))
    }
}
