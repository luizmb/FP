import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterTArrayOperatorsTests {
    @Test func fmap() {
        let w = Writer<[String], [Int]>([1, 2, 3], ["log"])
        let result = { $0 * 2 } <£^> w
        #expect(result.value == [2, 4, 6])
        #expect(result.log == ["log"])
    }

    @Test func flippedFmap() {
        let w = Writer<[String], [Int]>([1, 2, 3], ["log"])
        let result = w <&^> { $0 * 2 }
        #expect(result.value == [2, 4, 6])
        #expect(result.log == ["log"])
    }

    @Test func apply() {
        let wf = Writer<[String], [@Sendable (Int) -> Int]>([{ $0 + 1 }, { $0 * 10 }], ["fn"])
        let wa = Writer<[String], [Int]>([1, 2], ["val"])
        let result = wf <*> wa
        #expect(result.value == [2, 3, 10, 20])
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs = Writer<[String], [Int]>([1, 2], ["a"])
        let rhs = Writer<[String], [String]>(["x", "y"], ["b"])
        let result = lhs *> rhs
        #expect(result.value == ["x", "y", "x", "y"])
        #expect(result.log == ["a", "b"])
    }

    @Test func bind() {
        let w = Writer<[String], [Int]>([1, 2], ["outer"])
        let result = w >>- { n in Writer<[String], [String]>(["\(n)", "\(n * 10)"], ["inner\(n)"]) }
        #expect(result.value == ["1", "10", "2", "20"])
        // logs from all inner fn calls are accumulated plus outer
        #expect(result.log.first == "outer")
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> Writer<[String], [Int]> = { n in Writer([n, n + 1], ["f"]) }
        let g: @Sendable (Int) -> Writer<[String], [String]> = { n in Writer(["\(n)"], ["g"]) }
        let result = (f >=> g)(3)
        #expect(result.value == ["3", "4"])
    }
}
