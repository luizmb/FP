// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import Testing

// Operator syntax for AsyncStream (and MaybeT / ExceptT over it): bind is ordered concat,
// `<*>`/`*>`/`<*` are `ap` derived from it (cartesian), not zip.

@Suite struct AsyncStreamConcatOperatorsTests {
    @Test func bindOperatorIsOrderedConcat() async throws {
        let bound = streamOf([1, 2]) >>- { x in streamOf([x, x * 10]) }
        let flipped = { (x: Int) in streamOf([x, x * 10]) } -<< streamOf([1, 2])
        let observed1 = try await collectAllThrowing(bound)
        #expect(observed1 == [1, 10, 2, 20])
        let observed2 = try await collectAllThrowing(flipped)
        #expect(observed2 == [1, 10, 2, 20])
    }

    @Test func kleisliOperatorsAreOrderedConcat() async throws {
        let f: @Sendable (Int) async throws -> AsyncStream<Int> = { x in streamOf([x, x + 1]) }
        let g: @Sendable (Int) async throws -> AsyncStream<Int> = { x in streamOf([x * 10]) }
        let forward = f >=> g
        let backward = g <=< f
        let observed3 = try await collectAllThrowing(forward(1))
        #expect(observed3 == [10, 20])
        let observed4 = try await collectAllThrowing(backward(1))
        #expect(observed4 == [10, 20])
    }

    @Test func applyOperatorIsCartesian() async {
        let fns = streamOf([label("f"), label("g")])
        let result = await collectAll(fns <*> streamOf([1, 2]))
        #expect(result == ["f1", "f2", "g1", "g2"])
    }

    @Test func seqOperatorsAreBindDerived() async {
        let right = await collectAll(streamOf(["a", "b"]) *> streamOf([1, 2]))
        let left = await collectAll(streamOf(["a", "b"]) <* streamOf([1, 2]))
        #expect(right == [1, 2, 1, 2])
        #expect(left == ["a", "a", "b", "b"])
    }

    // MARK: - AsyncStreamTOptional

    @Test func optionalTransformerOperators() async {
        let fns: [(@Sendable (Int) -> String)?] = [label("f"), nil]
        let applied = await collectAll((streamOf(fns).asyncStreamT <*> streamOf([1, nil, 2] as [Int?]).asyncStreamT).rawValue)
        let right = await collectAll((streamOf([1, nil] as [Int?]).asyncStreamT *> streamOf([10, 20] as [Int?]).asyncStreamT).rawValue)
        let left = await collectAll((streamOf([1, nil] as [Int?]).asyncStreamT <* streamOf([10, 20] as [Int?]).asyncStreamT).rawValue)
        let bound = await collectAll(
            (streamOf([1, nil] as [Int?]).asyncStreamT >>- { (x: Int) in streamOf([x, x * 10] as [Int?]).asyncStreamT }).rawValue
        )
        #expect(applied == ["f1", nil, "f2", nil])
        #expect(right == [10, 20, nil])
        #expect(left == [1, 1, nil])
        #expect(bound == [1, 10, nil])
    }

    @Test func optionalTransformerKleisli() async {
        let f: @Sendable (Int) -> AsyncStreamTOptional<Int> = { x in streamOf([x, nil]).asyncStreamT }
        let g: @Sendable (Int) -> AsyncStreamTOptional<Int> = { x in streamOf([x + 1, x + 2] as [Int?]).asyncStreamT }
        let observed5 = await collectAll((f >=> g)(1).rawValue)
        #expect(observed5 == [2, 3, nil])
        let observed6 = await collectAll((g <=< f)(1).rawValue)
        #expect(observed6 == [2, 3, nil])
    }

    // MARK: - AsyncStreamTResult

    private enum Err: Error, Equatable { case boom }

    @Test func resultTransformerOperators() async {
        let fns: [Result<@Sendable (Int) -> String, Err>] = [.success(label("f")), .failure(.boom)]
        let xs: [Result<Int, Err>] = [.success(1), .success(2)]
        let applied = await collectAll((streamOf(fns).asyncStreamT <*> streamOf(xs).asyncStreamT).rawValue)
        let lhs = AsyncStreamTResult<Err, String>(streamOf([.success("a"), .failure(.boom)]))
        let right = await collectAll((lhs *> streamOf(xs).asyncStreamT).rawValue)
        let left = await collectAll((streamOf([Result<String, Err>.success("a")]).asyncStreamT <* streamOf(xs).asyncStreamT).rawValue)
        let bound = await collectAll(
            (streamOf(xs).asyncStreamT >>- { (x: Int) in streamOf([Result<Int, Err>.success(x), .failure(.boom)]).asyncStreamT }).rawValue
        )
        #expect(applied == [.success("f1"), .success("f2"), .failure(.boom)])
        #expect(right == [.success(1), .success(2), .failure(.boom)])
        #expect(left == [.success("a"), .success("a")])
        #expect(bound == [.success(1), .failure(.boom), .success(2), .failure(.boom)])
    }

    @Test func resultTransformerKleisli() async {
        let f: @Sendable (Int) -> AsyncStreamTResult<Err, Int> = { x in AsyncStreamTResult(streamOf([.success(x), .failure(.boom)])) }
        let g: @Sendable (Int) -> AsyncStreamTResult<Err, Int> = { x in AsyncStreamTResult(streamOf([.success(x * 10)])) }
        let observed7 = await collectAll((f >=> g)(1).rawValue)
        #expect(observed7 == [.success(10), .failure(.boom)])
        let observed8 = await collectAll((g <=< f)(1).rawValue)
        #expect(observed8 == [.success(10), .failure(.boom)])
    }
}

private func label(_ name: String) -> @Sendable (Int) -> String {
    { x in "\(name)\(x)" }
}
