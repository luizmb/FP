// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

// Operator syntax for ExceptT / WriterT over AsyncStream: bind is ordered concat,
// `<*>`/`*>`/`<*` are `ap` derived from it.

@Suite struct AsyncStreamEitherConcatOperatorsTests {
    @Test func applicativeOperators() async {
        let fns: [Either<String, @Sendable (Int) -> String>] = [.right(label("f")), .left("no")]
        let xs: [Either<String, Int>] = [.right(1), .right(2)]
        let applied = await collectAll((streamOf(fns).asyncStreamT <*> streamOf(xs).asyncStreamT).rawValue)
        let lhs = streamOf([Either<String, String>.right("a"), .left("x")]).asyncStreamT
        let right = await collectAll((lhs *> streamOf(xs).asyncStreamT).rawValue)
        let left = await collectAll((streamOf([Either<String, String>.right("a")]).asyncStreamT <* streamOf(xs).asyncStreamT).rawValue)
        #expect(applied == [.right("f1"), .right("f2"), .left("no")])
        #expect(right == [.right(1), .right(2), .left("x")])
        #expect(left == [.right("a"), .right("a")])
    }

    @Test func monadOperators() async {
        let f: @Sendable (Int) -> AsyncStreamTEither<String, Int> = { x in AsyncStreamTEither(streamOf([.right(x), .left("e\(x)")])) }
        let g: @Sendable (Int) -> AsyncStreamTEither<String, Int> = { x in AsyncStreamTEither(streamOf([.right(x * 10)])) }
        let bound = await collectAll((streamOf([Either<String, Int>.right(1), .right(2)]).asyncStreamT >>- f).rawValue)
        let flipped = await collectAll((f -<< streamOf([Either<String, Int>.right(1)]).asyncStreamT).rawValue)
        #expect(bound == [.right(1), .left("e1"), .right(2), .left("e2")])
        #expect(flipped == [.right(1), .left("e1")])
        let observed1 = await collectAll((f >=> g)(1).rawValue)
        #expect(observed1 == [.right(10), .left("e1")])
        let observed2 = await collectAll((g <=< f)(1).rawValue)
        #expect(observed2 == [.right(10), .left("e1")])
    }
}

@Suite struct AsyncStreamWriterConcatOperatorsTests {
    @Test func applicativeOperators() async {
        let fns = [Writer<[String], @Sendable (Int) -> String>(label("f"), ["F"]), Writer(label("g"), ["G"])]
        let xs = [Writer(1, ["x1"]), Writer(2, ["x2"])]
        let applied = await collectAll((streamOf(fns).asyncStreamT <*> streamOf(xs).asyncStreamT).rawValue)
        let right = await collectAll((streamOf([Writer("a", ["la"])]).asyncStreamT *> streamOf(xs).asyncStreamT).rawValue)
        let left = await collectAll((streamOf([Writer("a", ["la"])]).asyncStreamT <* streamOf(xs).asyncStreamT).rawValue)
        #expect(applied == [
            Writer("f1", ["F", "x1"]), Writer("f2", ["F", "x2"]),
            Writer("g1", ["G", "x1"]), Writer("g2", ["G", "x2"])
        ])
        #expect(right == [Writer(1, ["la", "x1"]), Writer(2, ["la", "x2"])])
        #expect(left == [Writer("a", ["la", "x1"]), Writer("a", ["la", "x2"])])
    }

    @Test func monadOperators() async {
        let f: @Sendable (Int) -> AsyncStreamTWriter<[String], Int> = { x in
            AsyncStreamTWriter(streamOf([Writer(x, ["f\(x)a"]), Writer(x * 10, ["f\(x)b"])]))
        }
        let g: @Sendable (Int) -> AsyncStreamTWriter<[String], Int> = { x in AsyncStreamTWriter(streamOf([Writer(x + 1, ["g\(x)"])])) }
        let bound = await collectAll((streamOf([Writer(1, ["m"])]).asyncStreamT >>- f).rawValue)
        let flipped = await collectAll((f -<< streamOf([Writer(1, ["m"])]).asyncStreamT).rawValue)
        let expected = [Writer(1, ["m", "f1a"]), Writer(10, ["m", "f1b"])]
        #expect(bound == expected)
        #expect(flipped == expected)
        let composed = [Writer(2, ["f1a", "g1"]), Writer(11, ["f1b", "g10"])]
        let observed3 = await collectAll((f >=> g)(1).rawValue)
        #expect(observed3 == composed)
        let observed4 = await collectAll((g <=< f)(1).rawValue)
        #expect(observed4 == composed)
    }
}

private func label(_ name: String) -> @Sendable (Int) -> String {
    { x in "\(name)\(x)" }
}
