import DataStructure
import Testing
import Core

@Suite struct WriterTOptionalTests {

    // MARK: - Writer<W, A?> — Writer as outer, Optional as inner

    @Test func mapTSome() {
        let w = Writer<[String], Int?>(.some(5), ["log"])
        let mapped = w.mapT { $0 * 2 }
        #expect(mapped.value == .some(10))
        #expect(mapped.log == ["log"])
    }

    @Test func mapTNone() {
        let w = Writer<[String], Int?>(nil, ["log"])
        let mapped = w.mapT { $0 * 2 }
        #expect(mapped.value == nil)
        #expect(mapped.log == ["log"])
    }

    @Test func flatMapTSome() {
        let w = Writer<[String], Int?>(.some(5), ["outer"])
        let result = w.flatMapT { n in
            Writer<[String], String?>(.some("\(n)"), ["inner"])
        }
        #expect(result.value == .some("5"))
        #expect(result.log == ["outer", "inner"])
    }

    @Test func flatMapTNone() {
        let w = Writer<[String], Int?>(nil, ["outer"])
        let result = w.flatMapT { n in
            Writer<[String], String?>(.some("\(n)"), ["inner"])
        }
        #expect(result.value == nil)
        #expect(result.log == ["outer"])
    }

    @Test func flatMapTInnerNone() {
        let w = Writer<[String], Int?>(.some(5), ["outer"])
        let result = w.flatMapT { _ in Writer<[String], String?>(nil, ["inner"]) }
        #expect(result.value == nil)
        #expect(result.log == ["outer", "inner"])
    }

    // MARK: - Writer<W, A>? — Optional as outer, Writer as inner

    @Test func optionalTWriterMapTSome() {
        let opt: Writer<[String], Int>? = .some(Writer(3, ["x"]))
        let mapped = opt.mapT { $0 * 2 }
        #expect(mapped?.value == 6)
        #expect(mapped?.log == ["x"])
    }

    @Test func optionalTWriterMapTNone() {
        let opt: Writer<[String], Int>? = nil
        let mapped: Writer<[String], Int>? = opt.mapT { $0 * 2 }
        #expect(mapped == nil)
    }

    @Test func optionalTWriterFlatMapTSome() {
        let opt: Writer<[String], Int>? = .some(Writer(5, ["outer"]))
        let result = opt.flatMapT { n in Writer<[String], String>("\(n)", ["inner"]) }
        #expect(result?.value == "5")
        #expect(result?.log == ["outer", "inner"])
    }

    @Test func optionalTWriterFlatMapTNone() {
        let opt: Writer<[String], Int>? = nil
        let result = opt.flatMapT { n in Writer<[String], String>("\(n)", ["inner"]) }
        #expect(result == nil)
    }
}
