// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

@Suite struct WriterMonoidTests {
    fileprivate typealias W = Writer<[String], String>

    // MARK: - combine

    @Test func combine_mergesValueAndLog() {
        let lhs = W("foo", ["step 1"])
        let rhs = W("bar", ["step 2"])
        let combined = W.combine(lhs, rhs)
        #expect(combined.value == "foobar")
        #expect(combined.log == ["step 1", "step 2"])
    }

    @Test func combine_isAssociative() {
        let a = W("a", ["1"])
        let b = W("b", ["2"])
        let c = W("c", ["3"])
        let leftFirst = W.combine(W.combine(a, b), c)
        let rightFirst = W.combine(a, W.combine(b, c))
        #expect(leftFirst.value == rightFirst.value)
        #expect(leftFirst.log == rightFirst.log)
    }

    // MARK: - identity

    @Test func identity_isEmptyValueAndLog() {
        let identity = W.identity
        #expect(identity.value == "")
        #expect(identity.log == [])
    }

    @Test func identity_isNeutralForCombine() {
        let w = W("value", ["entry"])
        let combinedLeft = W.combine(W.identity, w)
        let combinedRight = W.combine(w, W.identity)
        #expect(combinedLeft.value == w.value)
        #expect(combinedLeft.log == w.log)
        #expect(combinedRight.value == w.value)
        #expect(combinedRight.log == w.log)
    }

    // MARK: - sconcat / mconcat

    @Test func sconcat_combinesFirstAndRest() {
        let first = W("a", ["1"])
        let rest = [W("b", ["2"]), W("c", ["3"])]
        let result = W.sconcat(first, rest)
        #expect(result.value == "abc")
        #expect(result.log == ["1", "2", "3"])
    }

    @Test func sconcat_freeFunction_matchesStaticMethod() {
        let first = W("a", ["1"])
        let rest = [W("b", ["2"]), W("c", ["3"])]
        let result = sconcat(first, rest)
        #expect(result.value == "abc")
        #expect(result.log == ["1", "2", "3"])
    }

    @Test func mconcat_overSmallCollection() {
        let writers = [W("a", ["1"]), W("b", ["2"]), W("c", ["3"])]
        let result = W.mconcat(writers)
        #expect(result.value == "abc")
        #expect(result.log == ["1", "2", "3"])
    }

    @Test func mconcat_freeFunction_matchesStaticMethod() {
        let writers = [W("a", ["1"]), W("b", ["2"]), W("c", ["3"])]
        let result: W = mconcat(writers)
        #expect(result.value == "abc")
        #expect(result.log == ["1", "2", "3"])
    }

    @Test func mconcat_emptyCollection_returnsIdentity() {
        let result = W.mconcat([])
        #expect(result.value == "")
        #expect(result.log == [])
    }
}
