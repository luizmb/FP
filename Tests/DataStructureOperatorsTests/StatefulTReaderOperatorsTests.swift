// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct StatefulTReaderOperatorsTests {
    @Test func fmap() {
        let s = Stateful<Int, Reader<String, Int>>.pure(Reader(const(5)))
        let result = { $0 * 2 } <£^> s
        #expect(result.eval(0)("env") == 10)
    }

    @Test func flippedFmap() {
        let s = Stateful<Int, Reader<String, Int>>.pure(Reader(const(5)))
        let result = s <&^> { $0 * 2 }
        #expect(result.eval(0)("env") == 10)
    }

    @Test func apply() {
        let fn: @Sendable (Int) -> String = { "\($0)" }
        let sf = Stateful<Int, Reader<String, @Sendable (Int) -> String>>.pure(Reader(const(fn)))
        let sa = Stateful<Int, Reader<String, Int>>.pure(Reader(const(7)))
        let result = sf <*> sa
        #expect(result.eval(0)("env") == "7")
    }

    @Test func seqRight() {
        let lhs = Stateful<Int, Reader<String, Int>>.pure(Reader(const(1)))
        let rhs = Stateful<Int, Reader<String, String>>.pure(Reader(const("b")))
        let result = lhs *> rhs
        #expect(result.eval(0)("env") == "b")
    }

    @Test func seqLeft() {
        let lhs = Stateful<Int, Reader<String, Int>>.pure(Reader(const(1)))
        let rhs = Stateful<Int, Reader<String, String>>.pure(Reader(const("b")))
        let result = lhs <* rhs
        #expect(result.eval(0)("env") == 1)
    }
}
