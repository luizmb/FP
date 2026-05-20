import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct ComonadOperatorsTests {
    // MARK: - Writer ->>

    @Test func writerExtendOperator() {
        let w = Writer<String, Int>(3, "log")
        let result = w ->> { writer in writer.value * 10 }
        #expect(result.value == 30)
        #expect(result.log == "log")
    }

    @Test func writerExtendOperatorChained() {
        // Left-associative: (w ->> f) ->> g
        let w = Writer<String, Int>(2, "ab")
        let result = w ->> { $0.value + 1 } ->> { $0.value * 3 }
        // first step: Writer(3, "ab"); second: Writer(9, "ab")
        #expect(result.value == 9)
        #expect(result.log == "ab")
    }

    // MARK: - Writer <<-

    @Test func writerFlippedExtendOperator() {
        let w = Writer<String, Int>(5, "log")
        let result: Writer<String, Int> = { writer in writer.value + 100 } <<- w
        #expect(result.value == 105)
        #expect(result.log == "log")
    }

    // MARK: - Reader ->>

    @Test func readerExtendOperator() {
        let r = Reader<String, Int> { $0.count }
        let result = r ->> { inner in inner.runReader("!!!") }
        // result.runReader("ab") = f(Reader { e' -> ("ab" <> e').count }) with e' = "!!!"
        //   = ("ab" + "!!!").count = 5
        #expect(result.runReader("ab") == 5)
    }

    @Test func readerExtendOperatorChained() {
        let r = Reader<String, Int> { $0.count }
        let result = r
            ->> { inner in inner.runReader("!") }   // shift env by "!"
            ->> { inner in inner.runReader("?") }   // shift that shifted env by "?"
        // result.runReader("a") = r.run("a" + "?" + "!") = 3
        #expect(result.runReader("a") == 3)
    }

    // MARK: - Reader <<-

    @Test func readerFlippedExtendOperator() {
        let r = Reader<String, Int> { $0.count }
        let f: @Sendable (Reader<String, Int>) -> Int = { inner in inner.runReader("xyz") }
        let result: Reader<String, Int> = f <<- r
        // result.runReader("ab") = ("ab" + "xyz").count = 5
        #expect(result.runReader("ab") == 5)
    }
}
