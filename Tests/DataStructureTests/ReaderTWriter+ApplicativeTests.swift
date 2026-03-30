import DataStructure
import Testing

@Suite struct ReaderTWriterApplicativeTests {
    struct Env { let value: Int }

    // MARK: - Reader<Env, Writer<W, A>> — Reader as outer, Writer as inner

    @Test func apply() {
        let rf: Reader<Env, Writer<[String], (Int) -> String>> = Reader { _ in Writer({ "\($0)" }, ["fn"]) }
        let ra: Reader<Env, Writer<[String], Int>> = Reader { env in Writer(env.value, ["val"]) }
        let result = applyReaderWriter(rf, ra)
        let w = result(Env(value: 7))
        #expect(w.value == "7")
        #expect(w.log == ["fn", "val"])
    }

    @Test func applyUsesEnv() {
        let rf: Reader<Env, Writer<[String], (Int) -> Int>> = Reader { env in Writer({ $0 + env.value }, ["fn"]) }
        let ra: Reader<Env, Writer<[String], Int>> = Reader { env in Writer(env.value * 2, ["val"]) }
        let result = applyReaderWriter(rf, ra)
        let env = Env(value: 3)
        let w = result(env)
        #expect(w.value == 9)
        #expect(w.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs: Reader<Env, Writer<[String], Int>> = Reader { _ in Writer(1, ["a"]) }
        let rhs: Reader<Env, Writer<[String], String>> = Reader { _ in Writer("hello", ["b"]) }
        let result = seqRightReaderWriter(lhs, rhs)
        let w = result(Env(value: 0))
        #expect(w.value == "hello")
        #expect(w.log == ["a", "b"])
    }

    @Test func seqLeft() {
        let lhs: Reader<Env, Writer<[String], Int>> = Reader { _ in Writer(99, ["a"]) }
        let rhs: Reader<Env, Writer<[String], String>> = Reader { _ in Writer("ignored", ["b"]) }
        let result = seqLeftReaderWriter(lhs, rhs)
        let w = result(Env(value: 0))
        #expect(w.value == 99)
        #expect(w.log == ["a", "b"])
    }

    @Test func liftA2() {
        let ra: Reader<Env, Writer<[String], Int>> = Reader { env in Writer(env.value, ["a"]) }
        let rb: Reader<Env, Writer<[String], Int>> = Reader { env in Writer(env.value * 2, ["b"]) }
        let result = liftA2ReaderWriter(+)(ra, rb)
        let env = Env(value: 4)
        let w = result(env)
        #expect(w.value == 12)
        #expect(w.log == ["a", "b"])
    }
}
