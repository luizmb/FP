import DataStructureOperators
import DataStructure
import Testing
import CoreFP
import CoreFPOperators

@Suite struct ReaderTNonEmptyOperatorsTests {

    struct Env { let factor: Int }

    @Test func fmapOperator_forward() {
        let reader = Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor, tail: [env.factor * 2]) }
        let result = { $0 + 1 } <£^> reader
        #expect(result.runReader(Env(factor: 3)) == NonEmpty(head: 4, tail: [7]))
    }

    @Test func fmapOperator_flipped() {
        let reader = Reader<Env, NonEmpty<Int>> { env in NonEmpty(head: env.factor) }
        let result = reader <&^> { $0 * 2 }
        #expect(result.runReader(Env(factor: 5)) == NonEmpty(head: 10))
    }
}
