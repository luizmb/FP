// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ArrayTWriterOperatorsTests {
    @Test func fmap() {
        let arr: [Writer<[String], Int>] = [Writer(3, ["a"]), Writer(4, ["b"])]
        let result = { $0 * 2 } <£^> arr
        #expect(result[0].value == 6)
        #expect(result[0].log == ["a"])
        #expect(result[1].value == 8)
        #expect(result[1].log == ["b"])
    }

    @Test func flippedFmap() {
        let arr: [Writer<[String], Int>] = [Writer(3, ["a"]), Writer(4, ["b"])]
        let result = arr <&^> { $0 * 2 }
        #expect(result[0].value == 6)
        #expect(result[0].log == ["a"])
        #expect(result[1].value == 8)
        #expect(result[1].log == ["b"])
    }

    @Test func bind() {
        let arr: [Writer<[String], Int>] = [Writer(3, ["a"]), Writer(4, ["b"])]
        let fn: @Sendable (Int) -> [Writer<[String], String>] = { n in [Writer("\(n)", ["x"]), Writer("\(-n)", ["y"])] }
        let from3: [Writer<[String], String>] = [Writer("3", ["a", "x"]), Writer("-3", ["a", "y"])]
        let from4: [Writer<[String], String>] = [Writer("4", ["b", "x"]), Writer("-4", ["b", "y"])]
        let expected = from3 + from4
        #expect((arr >>- fn) == expected)
    }

    @Test func bindContinuationPrunes() {
        let arr: [Writer<[String], Int>] = [Writer(3, ["a"]), Writer(4, ["b"])]
        let fn: @Sendable (Int) -> [Writer<[String], Int>] = { n in n.isMultiple(of: 2) ? [Writer(n, ["even"])] : [] }
        #expect((arr >>- fn) == [Writer(4, ["b", "even"])])
    }

    @Test func flippedBind() {
        let arr: [Writer<[String], Int>] = [Writer(3, ["a"])]
        let fn: @Sendable (Int) -> [Writer<[String], String>] = { n in [Writer("\(n)", ["inner"])] }
        #expect((fn -<< arr) == [Writer("3", ["a", "inner"])])
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> [Writer<[String], Int>] = { n in [Writer(n, ["f1"]), Writer(n + 1, ["f2"])] }
        let g: @Sendable (Int) -> [Writer<[String], String>] = { n in [Writer("\(n)", ["g"])] }
        #expect((f >=> g)(5) == [Writer("5", ["f1", "g"]), Writer("6", ["f2", "g"])])
    }

    @Test func reverseKleisli() {
        let f: @Sendable (Int) -> [Writer<[String], Int>] = { n in [Writer(n, ["f1"]), Writer(n + 1, ["f2"])] }
        let g: @Sendable (Int) -> [Writer<[String], String>] = { n in [Writer("\(n)", ["g"])] }
        #expect((g <=< f)(5) == [Writer("5", ["f1", "g"]), Writer("6", ["f2", "g"])])
    }

    @Test func apply() {
        let fns: [Writer<[String], @Sendable (Int) -> String>] = [Writer({ "\($0)" }, ["fn"])]
        let vals: [Writer<[String], Int>] = [Writer(5, ["val"])]
        let result = fns <*> vals
        #expect(result.count == 1)
        #expect(result[0].value == "5")
        #expect(result[0].log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs: [Writer<[String], Int>] = [Writer(1, ["a"])]
        let rhs: [Writer<[String], String>] = [Writer("hello", ["b"])]
        let result = lhs *> rhs
        #expect(result.count == 1)
        #expect(result[0].value == "hello")
        #expect(result[0].log == ["a", "b"])
    }

    @Test func seqLeft() {
        let lhs: [Writer<[String], Int>] = [Writer(99, ["a"])]
        let rhs: [Writer<[String], String>] = [Writer("ignored", ["b"])]
        let result = lhs <* rhs
        #expect(result.count == 1)
        #expect(result[0].value == 99)
        #expect(result[0].log == ["a", "b"])
    }
}
