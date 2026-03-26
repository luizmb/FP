import DataStructure
import Testing
import CoreFP

@Suite struct WriterTNonEmptyTests {

    // MARK: - Writer<W, NonEmpty<A>> — mapT (functor)

    @Test func mapT() {
        let w = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1, tail: [2, 3]), ["log"])
        let result = w.mapT { $0 * 10 }
        #expect(result.value == NonEmpty(head: 10, tail: [20, 30]))
        #expect(result.log == ["log"])
    }

    @Test func fmapT_curried() {
        let w = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 5), ["entry"])
        let result = Writer<[String], NonEmpty<Int>>.fmapT({ $0 + 1 })(w)
        #expect(result.value == NonEmpty(head: 6))
        #expect(result.log == ["entry"])
    }

    // MARK: - Writer<W, NonEmpty<A>> — flatMapT (monad)

    @Test func flatMapT_combines_logs_and_values() {
        let w = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1, tail: [2]), ["outer"])
        let result = w.flatMapT { n in
            Writer<[String], NonEmpty<Int>?>(NonEmpty(head: n * 10), ["inner\(n)"])
        }
        #expect(result.value == NonEmpty(head: 10, tail: [20]))
        #expect(result.log == ["outer", "inner1", "inner2"])
    }

    @Test func flatMapT_nil_results_excluded() {
        let w = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1, tail: [2, 3]), ["outer"])
        let result = w.flatMapT { n -> Writer<[String], NonEmpty<Int>?> in
            n == 2 ? Writer(nil, ["skip"]) : Writer(NonEmpty(head: n * 10), ["keep\(n)"])
        }
        #expect(result.value == NonEmpty(head: 10, tail: [30]))
        #expect(result.log == ["outer", "keep1", "skip", "keep3"])
    }

    @Test func flatMapT_all_nil_returns_nil_value() {
        let w = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 1), ["outer"])
        let result = w.flatMapT { _ -> Writer<[String], NonEmpty<Int>?> in
            Writer(nil, ["empty"])
        }
        #expect(result.value == nil)
        #expect(result.log == ["outer", "empty"])
    }

    @Test func bindT_curried() {
        let w = Writer<[String], NonEmpty<Int>>(NonEmpty(head: 3), ["init"])
        let bound = Writer<[String], NonEmpty<Int>>.bindT({ n in
            Writer<[String], NonEmpty<Int>?>(NonEmpty(head: n + 1), ["step"])
        })(w)
        #expect(bound.value == NonEmpty(head: 4))
        #expect(bound.log == ["init", "step"])
    }
}
