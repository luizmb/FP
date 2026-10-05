// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct WriterTArrayTests {
    // MARK: - Writer<W, [A]> — Writer as outer, Array as inner

    @Test func map() {
        let w = Writer<[String], [Int]>([1, 2, 3], ["log"])
        let mapped = w.writerT.map { $0 * 10 }.rawValue
        #expect(mapped.value == [10, 20, 30])
        #expect(mapped.log == ["log"])
    }

    // MARK: - [Writer<W, A>] — Array as outer, Writer as inner

    @Test func arrayTWriterMapT() {
        let arr: [Writer<[String], Int>] = [Writer(2, ["a"]), Writer(3, ["b"])]
        let mapped = arr.mapT { $0 * 10 }
        #expect(mapped[0].value == 20)
        #expect(mapped[0].log == ["a"])
        #expect(mapped[1].value == 30)
        #expect(mapped[1].log == ["b"])
    }

    @Test func arrayTWriterFlatMapT() {
        let arr: [Writer<[String], Int>] = [Writer(5, ["outer"])]
        let result = arr.flatMapT { n in [Writer<[String], String>("\(n)", ["inner"])] }
        #expect(result[0].value == "5")
        #expect(result[0].log == ["outer", "inner"])
    }
}
