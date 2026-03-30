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
        let result = arr >>- { n in Writer<[String], String>("\(n)", ["inner"]) }
        #expect(result[0].value == "3")
        #expect(result[0].log == ["a", "inner"])
        #expect(result[1].value == "4")
        #expect(result[1].log == ["b", "inner"])
    }

    @Test func kleisli() {
        let f: (Int) -> [Writer<[String], Int>] = { n in [Writer(n, ["f1"]), Writer(n + 1, ["f2"])] }
        let g: (Int) -> Writer<[String], String> = { n in Writer("\(n)", ["g"]) }
        let result = (f >=> g)(5)
        #expect(result[0].value == "5")
        #expect(result[1].value == "6")
    }

    @Test func apply() {
        let fns: [Writer<[String], (Int) -> String>] = [Writer({ "\($0)" }, ["fn"])]
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
