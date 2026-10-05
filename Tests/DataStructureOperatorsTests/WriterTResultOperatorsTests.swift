// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite struct WriterTResultOperatorsTests {
    enum TestError: Error, Equatable { case failure }

    @Test func apply() {
        let wf = Writer<[String], Result<@Sendable (Int) -> String, TestError>>(.success { "\($0)" }, ["fn"])
        let wa = Writer<[String], Result<Int, TestError>>(.success(9), ["val"])
        let result = (wf.writerT <*> wa.writerT).rawValue
        #expect(result.value == .success("9"))
        #expect(result.log == ["fn", "val"])
    }

    @Test func seqRight() {
        let lhs = Writer<[String], Result<Int, TestError>>(.success(1), ["a"])
        let rhs = Writer<[String], Result<String, TestError>>(.success("b"), ["b"])
        let result = (lhs.writerT *> rhs.writerT).rawValue
        #expect(result.value == .success("b"))
        #expect(result.log == ["a", "b"])
    }

    @Test func bind() {
        let w = Writer<[String], Result<Int, TestError>>(.success(5), ["outer"])
        let result = (w.writerT >>- { n in Writer<[String], Result<String, TestError>>(.success("\(n)"), ["inner"]).writerT }).rawValue
        #expect(result.value == .success("5"))
        #expect(result.log == ["outer", "inner"])
    }

    @Test func kleisli() {
        let f: @Sendable (Int) -> WriterTResult<[String], TestError, Int> = { n in WriterTResult(Writer(.success(n + 1), ["f"])) }
        let g: @Sendable (Int) -> WriterTResult<[String], TestError, String> = { n in WriterTResult(Writer(.success("\(n)"), ["g"])) }
        let result = (f >=> g)(4).rawValue
        #expect(result.value == .success("5"))
        #expect(result.log == ["f", "g"])
    }
}
