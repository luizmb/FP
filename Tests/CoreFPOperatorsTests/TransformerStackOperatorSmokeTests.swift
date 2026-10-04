// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import Testing

/// Smoke tests for the generated newtype stacks (operator syntax): each operator must resolve on the
/// struct and agree with its named function.
@Suite struct TransformerStackOperatorSmokeTests {
    @Test func arrayTOptionalFunctorOperators() {
        let stack: ArrayTOptional<Int> = [1, nil, 3].arrayT
        let double: @Sendable (Int) -> Int = { $0 * 2 }

        #expect((double <£> stack).rawValue == stack.map(double).rawValue)
        #expect((stack <&> double).rawValue == stack.map(double).rawValue)
        #expect((stack £> "x").rawValue == ["x", nil, "x"])
        #expect(("x" <£ stack).rawValue == ["x", nil, "x"])
    }

    @Test func arrayTOptionalApplicativeOperators() {
        let fns = ArrayTOptional<@Sendable (Int) -> Int>([{ $0 + 1 }, nil])
        let values = ArrayTOptional<Int>([10, 20])

        #expect((fns <*> values).rawValue == ArrayTOptional.apply(fns, values).rawValue)
        #expect((values *> values).rawValue == values.seqRight(values).rawValue)
        #expect((values <* values).rawValue == values.seqLeft(values).rawValue)
    }

    @Test func arrayTOptionalMonadOperators() {
        let stack = ArrayTOptional<Int>([2, nil])
        let half: @Sendable (Int) -> ArrayTOptional<Int> = { ArrayTOptional([$0 / 2]) }
        let show: @Sendable (Int) -> ArrayTOptional<String> = { ArrayTOptional([String($0)]) }

        #expect((stack >>- half).rawValue == stack.flatMap(half).rawValue)
        #expect((half -<< stack).rawValue == stack.flatMap(half).rawValue)
        #expect((half >=> show)(4).rawValue == ["2"])
        #expect((show <=< half)(4).rawValue == ["2"])
    }

    @Test func optionalTArrayOperators() {
        let stack = OptionalTArray<Int>([1, 2])
        let double: @Sendable (Int) -> Int = { $0 * 2 }
        let typed: OptionalTArray<Int> = double <£> stack

        #expect(typed.rawValue == [2, 4])
        #expect((stack >>- { OptionalTArray([$0, $0]) }).rawValue == [1, 1, 2, 2])
    }
}
