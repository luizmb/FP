import DataStructure
import Testing
import CoreFP

@Suite struct ReaderTStatefulApplicativeTests {

    struct Env { let multiplier: Int }

    // MARK: - Reader<Env, Stateful<S, A>> — Reader as outer, Stateful as inner

    @Test func apply() {
        let rf: Reader<Env, Stateful<Int, (Int) -> String>> = Reader { _ in .pure({ "\($0)" }) }
        let ra: Reader<Env, Stateful<Int, Int>> = Reader { env in .pure(env.multiplier) }
        let result = applyReaderStateful(rf, ra)
        let env = Env(multiplier: 5)
        #expect(result(env).eval(0) == "5")
    }

    @Test func applyUsesEnv() {
        let rf: Reader<Env, Stateful<Int, (Int) -> Int>> = Reader { env in .pure({ $0 + env.multiplier }) }
        let ra: Reader<Env, Stateful<Int, Int>> = Reader { _ in .get }
        let result = applyReaderStateful(rf, ra)
        let env = Env(multiplier: 10)
        #expect(result(env).eval(7) == 17)
    }

    @Test func seqRight() {
        let lhs: Reader<Env, Stateful<Int, Int>> = Reader { _ in .pure(1) }
        let rhs: Reader<Env, Stateful<Int, String>> = Reader { _ in .pure("hello") }
        let result = seqRightReaderStateful(lhs, rhs)
        #expect(result(Env(multiplier: 0)).eval(0) == "hello")
    }

    @Test func seqLeft() {
        let lhs: Reader<Env, Stateful<Int, Int>> = Reader { _ in .pure(99) }
        let rhs: Reader<Env, Stateful<Int, String>> = Reader { _ in .pure("ignored") }
        let result = seqLeftReaderStateful(lhs, rhs)
        #expect(result(Env(multiplier: 0)).eval(0) == 99)
    }

    @Test func liftA2() {
        let ra: Reader<Env, Stateful<Int, Int>> = Reader { env in .pure(env.multiplier) }
        let rb: Reader<Env, Stateful<Int, Int>> = Reader { env in .pure(env.multiplier * 2) }
        let result = liftA2ReaderStateful(+)(ra, rb)
        let env = Env(multiplier: 3)
        #expect(result(env).eval(0) == 9)
    }
}
