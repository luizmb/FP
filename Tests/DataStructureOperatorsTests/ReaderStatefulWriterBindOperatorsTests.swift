// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

// `>>-`, `-<<`, `>=>` and `<=<` for the full-stack transformer binds:
// ReaderTWriter, ReaderTStateful, StatefulTWriter and ReaderTNonEmpty.

@Suite struct ReaderTWriterBindOperatorsTests {
    let m = Reader<Int, Writer<[String], Int>> { env in Writer(env, ["m"]) }.readerT
    let f: @Sendable (Int) -> ReaderTWriter<Int, [String], Int> = { a in
        Reader { env in Writer(a + env, ["f"]) }.readerT
    }

    let g: @Sendable (Int) -> ReaderTWriter<Int, [String], String> = { b in
        Reader { env in Writer("\(b * env)", ["g"]) }.readerT
    }

    @Test func bindForward() {
        #expect((m >>- f).rawValue(3) == Writer(6, ["m", "f"]))
    }

    @Test func bindFlipped() {
        #expect((f -<< m).rawValue(3) == Writer(6, ["m", "f"]))
    }

    @Test func kleisliForward() {
        #expect((f >=> g)(1).rawValue(3) == Writer("12", ["f", "g"]))
    }

    @Test func kleisliReverse() {
        #expect((g <=< f)(1).rawValue(3) == Writer("12", ["f", "g"]))
    }
}

@Suite struct ReaderTStatefulBindOperatorsTests {
    let m = Reader<Int, Stateful<Int, Int>> { env in
        Stateful { s in
            s += env
            return s
        }
    }.readerT

    let f: @Sendable (Int) -> ReaderTStateful<Int, Int, Int> = { a in
        Reader { env in
            Stateful { s in
                s *= env
                return a + 1
            }
        }.readerT
    }

    let g: @Sendable (Int) -> ReaderTStateful<Int, Int, String> = { b in
        Reader { env in
            Stateful { s in
                s -= env
                return "\(b)"
            }
        }.readerT
    }

    @Test func bindForward() {
        let (value, state) = (m >>- f).rawValue(3).runStateful(1)
        #expect(value == 5)
        #expect(state == 12)
    }

    @Test func bindFlipped() {
        let (value, state) = (f -<< m).rawValue(3).runStateful(1)
        #expect(value == 5)
        #expect(state == 12)
    }

    @Test func kleisliForward() {
        let (value, state) = (f >=> g)(7).rawValue(3).runStateful(2)
        #expect(value == "8")
        #expect(state == 3)
    }

    @Test func kleisliReverse() {
        let (value, state) = (g <=< f)(7).rawValue(3).runStateful(2)
        #expect(value == "8")
        #expect(state == 3)
    }
}

@Suite struct StatefulTWriterBindOperatorsTests {
    let m = StatefulTWriter(Stateful<Int, Writer<[String], Int>> { s in
        s += 1
        return Writer(s, ["m"])
    })

    let f: @Sendable (Int) -> StatefulTWriter<Int, [String], Int> = { a in
        StatefulTWriter(Stateful { s in
            s *= 10
            return Writer(a + 1, ["f"])
        })
    }

    let g: @Sendable (Int) -> StatefulTWriter<Int, [String], String> = { b in
        StatefulTWriter(Stateful { s in
            s -= b
            return Writer("\(b)", ["g"])
        })
    }

    @Test func bindForward() {
        let (writer, state) = (m >>- f).rawValue.runStateful(4)
        #expect(writer == Writer(6, ["m", "f"]))
        #expect(state == 50)
    }

    @Test func bindFlipped() {
        let (writer, state) = (f -<< m).rawValue.runStateful(4)
        #expect(writer == Writer(6, ["m", "f"]))
        #expect(state == 50)
    }

    @Test func kleisliForward() {
        let (writer, state) = (f >=> g)(2).rawValue.runStateful(1)
        #expect(writer == Writer("3", ["f", "g"]))
        #expect(state == 7)
    }

    @Test func kleisliReverse() {
        let (writer, state) = (g <=< f)(2).rawValue.runStateful(1)
        #expect(writer == Writer("3", ["f", "g"]))
        #expect(state == 7)
    }
}

@Suite struct ReaderTNonEmptyBindOperatorsTests {
    let m = Reader<Int, NonEmpty<Int>> { env in NonEmpty(head: env, tail: [env + 1]) }.readerT
    let f: @Sendable (Int) -> ReaderTNonEmpty<Int, Int> = { a in
        Reader { env in NonEmpty(head: a, tail: [a * env]) }.readerT
    }

    let g: @Sendable (Int) -> ReaderTNonEmpty<Int, String> = { b in
        Reader { env in NonEmpty(head: "\(b)@\(env)") }.readerT
    }

    @Test func bindForward() {
        #expect((m >>- f).rawValue(2) == NonEmpty(head: 2, tail: [4, 3, 6]))
    }

    @Test func bindFlipped() {
        #expect((f -<< m).rawValue(2) == NonEmpty(head: 2, tail: [4, 3, 6]))
    }

    @Test func kleisliForward() {
        #expect((f >=> g)(5).rawValue(2) == NonEmpty(head: "5@2", tail: ["10@2"]))
    }

    @Test func kleisliReverse() {
        #expect((g <=< f)(5).rawValue(2) == NonEmpty(head: "5@2", tail: ["10@2"]))
    }
}
