import DataStructure
import Testing

@Suite struct EitherTWriterApplicativeTests {
    // MARK: - Either<L, Writer<W, A>> — Either as outer, Writer as inner

    @Test func applyBothRight() {
        let eithF: Either<String, Writer<[String], (Int) -> String>> = .right(Writer({ "\($0)" }, ["fn"]))
        let eithA: Either<String, Writer<[String], Int>> = .right(Writer(7, ["val"]))
        let result = applyEitherWriter(eithF, eithA)
        #expect(result == .right(Writer("7", ["fn", "val"])))
    }

    @Test func applyLeftFn() {
        let eithF: Either<String, Writer<[String], (Int) -> String>> = .left("err")
        let eithA: Either<String, Writer<[String], Int>> = .right(Writer(7, ["val"]))
        let result = applyEitherWriter(eithF, eithA)
        #expect(result == .left("err"))
    }

    @Test func applyLeftVal() {
        let eithF: Either<String, Writer<[String], (Int) -> String>> = .right(Writer({ "\($0)" }, ["fn"]))
        let eithA: Either<String, Writer<[String], Int>> = .left("err")
        let result = applyEitherWriter(eithF, eithA)
        #expect(result == .left("err"))
    }

    @Test func seqRightBothRight() {
        let lhs: Either<String, Writer<[String], Int>> = .right(Writer(1, ["a"]))
        let rhs: Either<String, Writer<[String], String>> = .right(Writer("hello", ["b"]))
        let result = seqRightEitherWriter(lhs, rhs)
        #expect(result == .right(Writer("hello", ["a", "b"])))
    }

    @Test func seqRightLeft() {
        let lhs: Either<String, Writer<[String], Int>> = .left("fail")
        let rhs: Either<String, Writer<[String], String>> = .right(Writer("hello", ["b"]))
        let result = seqRightEitherWriter(lhs, rhs)
        #expect(result == .left("fail"))
    }

    @Test func seqLeftBothRight() {
        let lhs: Either<String, Writer<[String], Int>> = .right(Writer(99, ["a"]))
        let rhs: Either<String, Writer<[String], String>> = .right(Writer("ignored", ["b"]))
        let result = seqLeftEitherWriter(lhs, rhs)
        #expect(result == .right(Writer(99, ["a", "b"])))
    }

    @Test func seqLeftRightSide() {
        let lhs: Either<String, Writer<[String], Int>> = .right(Writer(99, ["a"]))
        let rhs: Either<String, Writer<[String], String>> = .left("fail")
        let result = seqLeftEitherWriter(lhs, rhs)
        #expect(result == .left("fail"))
    }
}
