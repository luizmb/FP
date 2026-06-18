// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct ComonadTests {
    // MARK: - Writer Comonad

    @Test func writerExtract() {
        let w = Writer<String, Int>(42, "log")
        #expect(w.extract == 42)
    }

    @Test func writerExtractFreeFunction() {
        let w = Writer<String, Int>(7, "x")
        #expect(extract(w) == 7)
    }

    @Test func writerExtend() {
        let w = Writer<String, Int>(3, "log")
        // extend f w = Writer(f(w), w.log)
        let result = w.extend { writer in writer.value * 10 }
        #expect(result.value == 30)
        #expect(result.log == "log")
    }

    @Test func writerExtendPreservesLog() {
        let w = Writer<String, Int>(5, "mylog")
        let result = w.extend { $0.log.count }
        #expect(result.value == 5)     // f(w) = w.log.count = 5
        #expect(result.log == "mylog") // original log preserved
    }

    @Test func writerCoflatMap() {
        let w = Writer<String, Int>(4, "abc")
        let result = w.coflatMap { writer in writer.log + "!" }
        #expect(result.value == "abc!")
        #expect(result.log == "abc")
    }

    @Test func writerDuplicate() {
        let w = Writer<String, Int>(9, "log")
        let dup = w.duplicate
        #expect(dup.value == w)
        #expect(dup.log == "log")
    }

    @Test func writerDuplicateFreeFunction() {
        let w = Writer<String, Int>(1, "x")
        let dup = duplicate(w)
        #expect(dup.value == w)
        #expect(dup.log == "x")
    }

    @Test func writerExtendFreeCurried() {
        let addLogLen = extend { (w: Writer<String, Int>) in w.value + w.log.count }
        let result = addLogLen(Writer<String, Int>(10, "abc"))
        #expect(result.value == 13)
        #expect(result.log == "abc")
    }

    // Comonad law: extract . duplicate == id
    @Test func writerComonadLawExtractDuplicate() {
        let w = Writer<String, Int>(5, "law")
        #expect(extract(duplicate(w)) == w)
    }

    // Comonad law: fmap extract . duplicate == id
    @Test func writerComonadLawFmapExtractDuplicate() {
        let w = Writer<String, Int>(5, "law")
        let result = w.duplicate.map { extract($0) }
        #expect(result == w)
    }

    // Comonad law: extend extract == id
    @Test func writerComonadLawExtendExtract() {
        let w = Writer<String, Int>(5, "law")
        #expect(w.extend(\.extract) == w)
    }

    // MARK: - Reader Comonad (requires Env: Monoid)

    @Test func readerExtract() {
        // String is Monoid (identity = ""), so Reader<String, Int> has a Comonad instance.
        let r = Reader<String, Int> { env in env.count }
        // extract runs with identity = ""
        #expect(r.extract == 0)
    }

    @Test func readerExtractFreeFunction() {
        let r = Reader<String, Int> { env in env.count + 1 }
        #expect(extract(r) == 1)
    }

    @Test func readerExtend() {
        // r = Reader { env -> Int: env.count }
        // extend f r = Reader { e -> f(Reader { e' -> r.run(e <> e') }) }
        let r = Reader<String, Int> { $0.count }
        // f takes a reader and runs it with "!" to get the length of (e <> "!")
        let result = r.extend { inner in inner.runReader("!") }
        // result.runReader("abc") = f(Reader { e' -> ("abc" <> e').count }) with e' = "!"
        //   = ("abc" + "!").count = 4
        #expect(result.runReader("abc") == 4)
    }

    @Test func readerExtendFreeCurried() {
        let r = Reader<String, Int> { $0.count }
        let shifted = extend { (inner: Reader<String, Int>) in inner.runReader("xx") }
        // shifted(r).runReader("hello") = r.runReader("hello" <> "xx") = 7
        #expect(shifted(r).runReader("hello") == 7)
    }

    @Test func readerDuplicate() {
        let r = Reader<String, Int> { $0.count }
        let dup = r.duplicate
        // dup.runReader("abc") = Reader { e' -> r.runReader("abc" <> e') }
        // dup.runReader("abc").runReader("de") = r.runReader("abc" + "de") = 5
        #expect(dup.runReader("abc").runReader("de") == 5)
    }

    @Test func readerDuplicateFreeFunction() {
        let r = Reader<String, Int> { $0.count }
        let dup = duplicate(r)
        #expect(dup.runReader("hi").runReader("!!!") == 5)
    }

    // Comonad law: extract . extend f == f
    @Test func readerComonadLawExtractExtend() {
        let r = Reader<String, Int> { $0.count }
        let f: @Sendable (Reader<String, Int>) -> Int = { inner in inner.runReader("!!") * 2 }
        // extract(extend f r) should equal f(r)
        #expect(extract(r.extend(f)) == f(r))
    }

    // Comonad law: extend extract == id
    @Test func readerComonadLawExtendExtract() {
        let r = Reader<String, Int> { $0.count }
        let result = r.extend { extract($0) }
        // result.runReader(e) = extract(Reader { e' -> r.runReader(e <> e') })
        //   = r.runReader(e <> "") = r.runReader(e)
        #expect(result.runReader("hello") == r.runReader("hello"))
        #expect(result.runReader("") == r.runReader(""))
    }
}
