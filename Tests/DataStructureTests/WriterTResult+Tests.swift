import CoreFP
import DataStructure
import Testing

@Suite struct WriterTResultTests {
    // MARK: - Writer<W, Result<A, E>> — Writer as outer, Result as inner

    @Test func mapTSuccess() {
        let w = Writer<[String], Result<Int, Error>>(.success(5), ["log"])
        let mapped = w.mapT { $0 * 2 }
        if case .success(let v) = mapped.value {
            #expect(v == 10)
        } else {
            Issue.record("Expected success")
        }
        #expect(mapped.log == ["log"])
    }

    @Test func mapTFailure() {
        struct E: Error, Equatable {}
        let w = Writer<[String], Result<Int, E>>(.failure(E()), ["log"])
        let mapped = w.mapT { $0 * 2 }
        if case .failure = mapped.value {} else {
            Issue.record("Expected failure")
        }
        #expect(mapped.log == ["log"])
    }

    @Test func flatMapTSuccess() {
        let w = Writer<[String], Result<Int, Error>>(.success(3), ["outer"])
        let result = w.flatMapT { n in
            Writer<[String], Result<String, Error>>(.success("\(n)"), ["inner"])
        }
        if case .success(let v) = result.value {
            #expect(v == "3")
        } else {
            Issue.record("Expected success")
        }
        #expect(result.log == ["outer", "inner"])
    }

    @Test func flatMapTFailure() {
        struct E: Error, Equatable {}
        let w = Writer<[String], Result<Int, E>>(.failure(E()), ["outer"])
        let result = w.flatMapT { n in
            Writer<[String], Result<String, E>>(.success("\(n)"), ["inner"])
        }
        if case .failure = result.value {} else {
            Issue.record("Expected failure")
        }
        #expect(result.log == ["outer"])
    }

    // MARK: - Result<Writer<W, A>, E> — Result as outer, Writer as inner

    @Test func resultTWriterMapTSuccess() {
        let r: Result<Writer<[String], Int>, Error> = .success(Writer(4, ["x"]))
        let mapped = r.mapT { $0 * 3 }
        if case .success(let w) = mapped {
            #expect(w.value == 12)
            #expect(w.log == ["x"])
        } else {
            Issue.record("Expected success")
        }
    }

    @Test func resultTWriterFlatMapTSuccess() {
        let r: Result<Writer<[String], Int>, Error> = .success(Writer(5, ["outer"]))
        let result = r.flatMapT { n in Writer<[String], String>("\(n)", ["inner"]) }
        if case .success(let w) = result {
            #expect(w.value == "5")
            #expect(w.log == ["outer", "inner"])
        } else {
            Issue.record("Expected success")
        }
    }
}
