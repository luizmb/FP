import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct StatefulReaderOperatorsTests {
    // MARK: - Reader<Env, Stateful<S, A>> applicative operators

    @Test func readerTStatefulApply() {
        let rf: Reader<Int, Stateful<Int, (Int) -> String>> = Reader { _ in .pure({ "\($0)" }) }
        let ra: Reader<Int, Stateful<Int, Int>> = Reader { env in .pure(env) }
        let result = rf <*> ra
        #expect(result.runReader(5).eval(0) == "5")
    }

    @Test func readerTStatefulSeqRight() {
        let lhs: Reader<Int, Stateful<Int, Int>> = Reader { _ in .pure(1) }
        let rhs: Reader<Int, Stateful<Int, String>> = Reader { _ in .pure("hello") }
        let result = lhs *> rhs
        #expect(result.runReader(0).eval(0) == "hello")
    }

    @Test func readerTStatefulSeqLeft() {
        let lhs: Reader<Int, Stateful<Int, Int>> = Reader { _ in .pure(99) }
        let rhs: Reader<Int, Stateful<Int, String>> = Reader { _ in .pure("ignored") }
        let result = lhs <* rhs
        #expect(result.runReader(0).eval(0) == 99)
    }

    // MARK: - Stateful<S, Reader<Env, A>> fmap (from existing)

    @Test func statefulReaderImportSmoke() {
        // Smoke test: importing all three modules compiles successfully.
        let s = Stateful<Int, Reader<Int, Int>> { _ in Reader { env in env } }
        let mapped = { $0 * 2 } <£^> s
        #expect(mapped.eval(0).runReader(5) == 10)
    }

    @Test func statefulReaderFlippedFmap() {
        let s = Stateful<Int, Reader<Int, Int>> { _ in Reader { env in env } }
        let mapped = s <&^> { $0 * 2 }
        #expect(mapped.eval(0).runReader(5) == 10)
    }
}
