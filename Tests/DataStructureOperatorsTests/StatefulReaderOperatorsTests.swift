// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct StatefulReaderOperatorsTests {
    // MARK: - Reader<Env, Stateful<S, A>> applicative operators

    @Test func readerTStatefulApply() {
        let rf: Reader<Int, Stateful<Int, @Sendable (Int) -> String>> = Reader(const(.pure { "\($0)" }))
        let ra: Reader<Int, Stateful<Int, Int>> = Reader { env in .pure(env) }
        let result = (rf.readerT <*> ra.readerT).rawValue
        #expect(result.runReader(5).eval(0) == "5")
    }

    @Test func readerTStatefulSeqRight() {
        let lhs: Reader<Int, Stateful<Int, Int>> = Reader(const(.pure(1)))
        let rhs: Reader<Int, Stateful<Int, String>> = Reader(const(.pure("hello")))
        let result = (lhs.readerT *> rhs.readerT).rawValue
        #expect(result.runReader(0).eval(0) == "hello")
    }

    @Test func readerTStatefulSeqLeft() {
        let lhs: Reader<Int, Stateful<Int, Int>> = Reader(const(.pure(99)))
        let rhs: Reader<Int, Stateful<Int, String>> = Reader(const(.pure("ignored")))
        let result = (lhs.readerT <* rhs.readerT).rawValue
        #expect(result.runReader(0).eval(0) == 99)
    }
}
