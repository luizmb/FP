import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterTStatefulOperatorsTests {
    @Test func fmap() {
        let w = Writer<[String], Stateful<Int, Int>>(Stateful { s in s }, ["log"])
        let result = { $0 * 2 } <£^> w
        #expect(result.value.eval(5) == 10)
        #expect(result.log == ["log"])
    }

    @Test func flippedFmap() {
        let w = Writer<[String], Stateful<Int, Int>>(Stateful { s in s }, ["log"])
        let result = w <&^> { $0 * 2 }
        #expect(result.value.eval(5) == 10)
        #expect(result.log == ["log"])
    }

    @Test func apply() {
        let wf = Writer<[String], Stateful<Int, (Int) -> String>>(
            Stateful { _ in { "\($0)" } },
            ["fn"]
        )
        let wa = Writer<[String], Stateful<Int, Int>>(Stateful { s in s }, ["val"])
        let result = wf <*> wa
        #expect(result.value.eval(9) == "9")
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs = Writer<[String], Stateful<Int, Int>>(Stateful { s in s }, ["a"])
        let rhs = Writer<[String], Stateful<Int, String>>(Stateful { _ in "done" }, ["b"])
        let result = lhs *> rhs
        #expect(result.value.eval(0) == "done")
        #expect(result.log == ["a", "b"])
    }

    @Test func seqLeft() {
        let lhs = Writer<[String], Stateful<Int, Int>>(Stateful { s in s }, ["a"])
        let rhs = Writer<[String], Stateful<Int, String>>(Stateful { _ in "done" }, ["b"])
        let result = lhs <* rhs
        #expect(result.value.eval(7) == 7)
        #expect(result.log == ["a", "b"])
    }

    @Test func bind() {
        let w = Writer<[String], Stateful<Int, Int>>(Stateful { s in s }, ["outer"])
        let result = w >>- { n in
            Writer<[String], Stateful<Int, String>>(
                Stateful { state in
                    state += n
                    return "\(state)"
                },
                ["inner"]
            )
        }
        let (output, finalState) = result.value.runStateful(3)
        #expect(output == "6")
        #expect(finalState == 6)
        #expect(result.log == ["outer"])
    }

    @Test func kleisli() {
        let f: (Int) -> Writer<[String], Stateful<Int, Int>> = { n in
            Writer(Stateful { _ in n + 1 }, ["f"])
        }
        let g: (Int) -> Writer<[String], Stateful<Int, String>> = { n in
            Writer(Stateful { _ in "\(n)" }, ["g"])
        }
        let result = (f >=> g)(4)
        #expect(result.value.eval(0) == "5")
        #expect(result.log == ["f"])
    }
}
