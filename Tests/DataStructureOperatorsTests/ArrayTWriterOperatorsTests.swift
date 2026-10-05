// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ArrayTWriterOperatorsTests {
    @Test func bind() {
        let arr: [Writer<[String], Int>] = [Writer(3, ["a"]), Writer(4, ["b"])]
        let fn: @Sendable (Int) -> ArrayTWriter<[String], String> = { n in ArrayTWriter([Writer("\(n)", ["x"]), Writer("\(-n)", ["y"])]) }
        let from3: [Writer<[String], String>] = [Writer("3", ["a", "x"]), Writer("-3", ["a", "y"])]
        let from4: [Writer<[String], String>] = [Writer("4", ["b", "x"]), Writer("-4", ["b", "y"])]
        let expected = from3 + from4
        #expect((arr.arrayT >>- fn).rawValue == expected)
    }

    @Test func bindContinuationPrunes() {
        let arr: [Writer<[String], Int>] = [Writer(3, ["a"]), Writer(4, ["b"])]
        let fn: @Sendable (Int) -> ArrayTWriter<[String], Int> = { n in ArrayTWriter(n.isMultiple(of: 2) ? [Writer(n, ["even"])] : []) }
        #expect((arr.arrayT >>- fn).rawValue == [Writer(4, ["b", "even"])])
    }

    @Test func flippedBind() {
        let arr: [Writer<[String], Int>] = [Writer(3, ["a"])]
        let fn: @Sendable (Int) -> ArrayTWriter<[String], String> = { n in ArrayTWriter([Writer("\(n)", ["inner"])]) }
        #expect((fn -<< arr.arrayT).rawValue == [Writer("3", ["a", "inner"])])
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> ArrayTWriter<[String], Int> = { n in ArrayTWriter([Writer(n, ["f1"]), Writer(n + 1, ["f2"])]) }
        let g: @Sendable (Int) -> ArrayTWriter<[String], String> = { n in ArrayTWriter([Writer("\(n)", ["g"])]) }
        #expect((f >=> g)(5).rawValue == [Writer("5", ["f1", "g"]), Writer("6", ["f2", "g"])])
    }

    @Test func reverseKleisli() {
        let f: @Sendable (Int) -> ArrayTWriter<[String], Int> = { n in ArrayTWriter([Writer(n, ["f1"]), Writer(n + 1, ["f2"])]) }
        let g: @Sendable (Int) -> ArrayTWriter<[String], String> = { n in ArrayTWriter([Writer("\(n)", ["g"])]) }
        #expect((g <=< f)(5).rawValue == [Writer("5", ["f1", "g"]), Writer("6", ["f2", "g"])])
    }

    @Test func apply() {
        let fns: [Writer<[String], @Sendable (Int) -> String>] = [Writer({ "\($0)" }, ["fn"])]
        let vals: [Writer<[String], Int>] = [Writer(5, ["val"])]
        let result = (fns.arrayT <*> vals.arrayT).rawValue
        #expect(result.count == 1)
        #expect(result[0].value == "5")
        #expect(result[0].log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs: [Writer<[String], Int>] = [Writer(1, ["a"])]
        let rhs: [Writer<[String], String>] = [Writer("hello", ["b"])]
        let result = (lhs.arrayT *> rhs.arrayT).rawValue
        #expect(result.count == 1)
        #expect(result[0].value == "hello")
        #expect(result[0].log == ["a", "b"])
    }

    @Test func seqLeft() {
        let lhs: [Writer<[String], Int>] = [Writer(99, ["a"])]
        let rhs: [Writer<[String], String>] = [Writer("ignored", ["b"])]
        let result = (lhs.arrayT <* rhs.arrayT).rawValue
        #expect(result.count == 1)
        #expect(result[0].value == 99)
        #expect(result[0].log == ["a", "b"])
    }
}
