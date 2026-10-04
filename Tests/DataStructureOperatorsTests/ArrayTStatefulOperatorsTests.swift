// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ArrayTStatefulOperatorsTests {
    @Test func apply() {
        let fns: [Stateful<Int, @Sendable (Int) -> String>] = [.pure { "\($0)" }]
        let vals: [Stateful<Int, Int>] = [.pure(5)]
        let result = fns <*> vals
        #expect(result.count == 1)
        #expect(result[0].eval(0) == "5")
    }

    @Test func seqRight() {
        let lhs: [Stateful<Int, Int>] = [.pure(1)]
        let rhs: [Stateful<Int, String>] = [.pure("hello")]
        let result = lhs *> rhs
        #expect(result.count == 1)
        #expect(result[0].eval(0) == "hello")
    }

    @Test func seqLeft() {
        let lhs: [Stateful<Int, Int>] = [.pure(99)]
        let rhs: [Stateful<Int, String>] = [.pure("ignored")]
        let result = lhs <* rhs
        #expect(result.count == 1)
        #expect(result[0].eval(0) == 99)
    }
}
