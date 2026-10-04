// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

/// Smoke tests for the generated newtype stacks (named API): each family's struct must compile and
/// agree with the nested-type functions it delegates to. Full law tests come with the move of the logic.
@Suite struct TransformerStackSmokeTests {
    private enum Err: Error, Equatable { case fail }

    // MARK: - ArrayTOptional (MaybeT over a data outer)

    @Test func arrayTOptionalMatchesNestedSurface() {
        let nested: [Int?] = [1, nil, 3]
        let stack = nested.arrayT
        let double: @Sendable (Int) -> Int = { $0 * 2 }
        let next: @Sendable (Int) -> ArrayTOptional<Int> = { ArrayTOptional([$0, $0 + 10]) }

        #expect(stack.map(double).rawValue == nested.mapT(double))
        #expect(ArrayTOptional<Int>.fmap(double)(stack).rawValue == nested.mapT(double))
        #expect(stack.flatMap(next).rawValue == nested.flatMapT { next($0).rawValue })
        #expect(ArrayTOptional<Int>.bind(next)(stack).rawValue == nested.flatMapT { next($0).rawValue })
        #expect(ArrayTOptional<Int>.pure(7).rawValue == [7])
    }

    @Test func arrayTOptionalApplicativeMatchesNestedSurface() {
        let fns: [(@Sendable (Int) -> Int)?] = [{ $0 + 1 }, nil]
        let values: [Int?] = [10, 20]
        let add: @Sendable (Int, Int) -> Int = { $0 + $1 }

        #expect(ArrayTOptional.apply(ArrayTOptional(fns), ArrayTOptional(values)).rawValue == applyArrayOptional(fns, values))
        #expect(ArrayTOptional<Int>.liftA2(add)(values.arrayT, values.arrayT).rawValue == liftA2ArrayOptional(add)(values, values))
        #expect(values.arrayT.seqRight(values.arrayT).rawValue == seqRightArrayOptional(values, values))
        #expect(values.arrayT.seqLeft(values.arrayT).rawValue == seqLeftArrayOptional(values, values))
    }

    @Test func arrayTOptionalKleisliAndEscapeHatch() {
        let half: @Sendable (Int) -> ArrayTOptional<Int> = { ArrayTOptional([$0.isMultiple(of: 2) ? $0 / 2 : nil]) }
        let show: @Sendable (Int) -> ArrayTOptional<String> = { ArrayTOptional([String($0)]) }

        #expect(ArrayTOptional<Int>.kleisli(half, show)(8).rawValue == ["4"])
        #expect(ArrayTOptional<Int>.kleisliBack(show, half)(3).rawValue == [nil])
        #expect(ArrayTOptional<Int>([1, nil]).mapMaybeT { $0.reversed() }.rawValue == [nil, 1])
    }

    // MARK: - OptionalTArray (Compose-like stack, Optional outer)

    @Test func optionalTArrayMatchesNestedSurface() {
        let nested = Optional([1, 2])
        let stack = nested.optionalT
        let double: @Sendable (Int) -> Int = { $0 * 2 }
        let typed: OptionalTArray<Int> = stack.map(double)

        #expect(typed.rawValue == nested.mapT(double))
        #expect(stack.flatMap { OptionalTArray([$0, $0]) }.rawValue == nested.flatMapT { [$0, $0] })
        #expect(stack.mapOptionalT { $0.map { $0.dropFirst().map(double) } }.rawValue == [4])
        #expect(OptionalTArray<Int>.pure(1).rawValue == [1])
    }

    // MARK: - ArrayTResult (ExceptT over a data outer)

    @Test func arrayTResultMatchesNestedSurface() {
        let nested: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let stack = nested.arrayT
        let double: @Sendable (Int) -> Int = { $0 * 2 }

        #expect(stack.map(double).rawValue == nested.mapT(double))
        #expect(stack.mapExceptT { $0.reversed() }.rawValue == [.failure(.fail), .success(1)])
    }
}
