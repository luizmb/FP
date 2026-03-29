import CoreFP
import DataStructure
import Testing

@Suite struct OptionalTWriterApplicativeTests {
    // MARK: - Writer<W, A>? — Optional as outer, Writer as inner

    @Test func applyBothSome() {
        let wf: Writer<[String], (Int) -> String>? = Writer({ "\($0)" }, ["fn"])
        let wa: Writer<[String], Int>? = Writer(7, ["val"])
        let result = applyOptionalWriter(wf, wa)
        #expect(result?.value == "7")
        #expect(result?.log == ["fn", "val"])
    }

    @Test func applyNilFn() {
        let wf: Writer<[String], (Int) -> String>? = nil
        let wa: Writer<[String], Int>? = Writer(7, ["val"])
        let result = applyOptionalWriter(wf, wa)
        #expect(result == nil)
    }

    @Test func applyNilVal() {
        let wf: Writer<[String], (Int) -> String>? = Writer({ "\($0)" }, ["fn"])
        let wa: Writer<[String], Int>? = nil
        let result = applyOptionalWriter(wf, wa)
        #expect(result == nil)
    }

    @Test func applyBothNil() {
        let wf: Writer<[String], (Int) -> String>? = nil
        let wa: Writer<[String], Int>? = nil
        let result = applyOptionalWriter(wf, wa)
        #expect(result == nil)
    }

    @Test func seqRightBothSome() {
        let lhs: Writer<[String], Int>? = Writer(1, ["a"])
        let rhs: Writer<[String], String>? = Writer("hello", ["b"])
        let result = seqRightOptionalWriter(lhs, rhs)
        #expect(result?.value == "hello")
        #expect(result?.log == ["a", "b"])
    }

    @Test func seqRightNil() {
        let lhs: Writer<[String], Int>? = nil
        let rhs: Writer<[String], String>? = Writer("hello", ["b"])
        let result = seqRightOptionalWriter(lhs, rhs)
        #expect(result == nil)
    }

    @Test func seqLeftBothSome() {
        let lhs: Writer<[String], Int>? = Writer(99, ["a"])
        let rhs: Writer<[String], String>? = Writer("ignored", ["b"])
        let result = seqLeftOptionalWriter(lhs, rhs)
        #expect(result?.value == 99)
        #expect(result?.log == ["a", "b"])
    }

    @Test func seqLeftNil() {
        let lhs: Writer<[String], Int>? = Writer(99, ["a"])
        let rhs: Writer<[String], String>? = nil
        let result = seqLeftOptionalWriter(lhs, rhs)
        #expect(result == nil)
    }
}
