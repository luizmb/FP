import DataStructure
import Testing

@Suite struct ArrayTWriterApplicativeTests {
    // MARK: - [Writer<W, A>] — Array as outer, Writer as inner

    @Test func apply() {
        let fns: [Writer<[String], @Sendable (Int) -> String>] = [
            Writer({ "\($0)" }, ["fn"])
        ]
        let vals: [Writer<[String], Int>] = [
            Writer(5, ["val"])
        ]
        let result = applyArrayWriter(fns, vals)
        #expect(result.count == 1)
        #expect(result[0].value == "5")
        #expect(result[0].log == ["fn", "val"])
    }

    @Test func applyCartesianProduct() {
        let fns: [Writer<[String], @Sendable (Int) -> Int>] = [
            Writer({ $0 + 1 }, ["f1"]),
            Writer({ $0 * 2 }, ["f2"])
        ]
        let vals: [Writer<[String], Int>] = [
            Writer(3, ["a"]),
            Writer(4, ["b"])
        ]
        let result = applyArrayWriter(fns, vals)
        #expect(result.count == 4)
        #expect(result[0].value == 4)
        #expect(result[0].log == ["f1", "a"])
        #expect(result[1].value == 5)
        #expect(result[1].log == ["f1", "b"])
        #expect(result[2].value == 6)
        #expect(result[2].log == ["f2", "a"])
        #expect(result[3].value == 8)
        #expect(result[3].log == ["f2", "b"])
    }

    @Test func seqRight() {
        let lhs: [Writer<[String], Int>] = [Writer(1, ["a"]), Writer(2, ["b"])]
        let rhs: [Writer<[String], String>] = [Writer("x", ["c"])]
        let result = seqRightArrayWriter(lhs, rhs)
        #expect(result.count == 2)
        #expect(result[0].value == "x")
        #expect(result[0].log == ["a", "c"])
        #expect(result[1].value == "x")
        #expect(result[1].log == ["b", "c"])
    }

    @Test func seqLeft() {
        let lhs: [Writer<[String], Int>] = [Writer(99, ["a"])]
        let rhs: [Writer<[String], String>] = [Writer("ignored", ["b"])]
        let result = seqLeftArrayWriter(lhs, rhs)
        #expect(result.count == 1)
        #expect(result[0].value == 99)
        #expect(result[0].log == ["a", "b"])
    }

    @Test func applyEmptyFns() {
        let fns: [Writer<[String], @Sendable (Int) -> Int>] = []
        let vals: [Writer<[String], Int>] = [Writer(5, ["a"])]
        let result = applyArrayWriter(fns, vals)
        #expect(result.isEmpty)
    }

    @Test func applyEmptyVals() {
        let fns: [Writer<[String], @Sendable (Int) -> Int>] = [Writer({ $0 }, ["f"])]
        let vals: [Writer<[String], Int>] = []
        let result = applyArrayWriter(fns, vals)
        #expect(result.isEmpty)
    }
}
