// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

/// Smoke tests for the generated newtype stacks (named API): each family's struct must compile and
/// produce the expected nested values.
@Suite struct TransformerStackSmokeTests {
    private enum Err: Error, Equatable { case fail }

    // MARK: - ArrayTOptional (MaybeT over a data outer)

    @Test func arrayTOptionalNamedSurface() {
        let nested: [Int?] = [1, nil, 3]
        let stack = nested.arrayT
        let double: @Sendable (Int) -> Int = { $0 * 2 }
        let next: @Sendable (Int) -> ArrayTOptional<Int> = { ArrayTOptional([$0, $0 + 10]) }

        #expect(stack.map(double).rawValue == [2, nil, 6])
        #expect(ArrayTOptional<Int>.fmap(double)(stack).rawValue == [2, nil, 6])
        #expect(stack.flatMap(next).rawValue == [1, 11, nil, 3, 13])
        #expect(ArrayTOptional<Int>.bind(next)(stack).rawValue == [1, 11, nil, 3, 13])
        #expect(ArrayTOptional<Int>.pure(7).rawValue == [7])
    }

    @Test func arrayTOptionalApplicativeNamedSurface() {
        let fns: [(@Sendable (Int) -> Int)?] = [{ $0 + 1 }, nil]
        let values: [Int?] = [10, 20]
        let add: @Sendable (Int, Int) -> Int = { $0 + $1 }

        #expect(ArrayTOptional.apply(ArrayTOptional(fns), ArrayTOptional(values)).rawValue == [11, 21, nil])
        #expect(ArrayTOptional<Int>.liftA2(add)(values.arrayT, values.arrayT).rawValue == [20, 30, 30, 40])
        #expect(values.arrayT.seqRight(values.arrayT).rawValue == [10, 20, 10, 20])
        #expect(values.arrayT.seqLeft(values.arrayT).rawValue == [10, 10, 20, 20])
    }

    @Test func arrayTOptionalKleisliAndEscapeHatch() {
        let half: @Sendable (Int) -> ArrayTOptional<Int> = { ArrayTOptional([$0.isMultiple(of: 2) ? $0 / 2 : nil]) }
        let show: @Sendable (Int) -> ArrayTOptional<String> = { ArrayTOptional([String($0)]) }

        #expect(ArrayTOptional<Int>.kleisli(half, show)(8).rawValue == ["4"])
        #expect(ArrayTOptional<Int>.kleisliBack(show, half)(3).rawValue == [nil])
        #expect(ArrayTOptional<Int>([1, nil]).mapMaybeT { $0.reversed() }.rawValue == [nil, 1])
    }

    // MARK: - OptionalTArray (Compose-like stack, Optional outer)

    @Test func optionalTArrayNamedSurface() {
        let nested = Optional([1, 2])
        let stack = nested.optionalT
        let double: @Sendable (Int) -> Int = { $0 * 2 }
        let typed: OptionalTArray<Int> = stack.map(double)

        #expect(typed.rawValue == [2, 4])
        #expect(stack.flatMap { OptionalTArray([$0, $0]) }.rawValue == [1, 1, 2, 2])
        #expect(stack.mapOptionalT { $0.map { $0.dropFirst().map(double) } }.rawValue == [4])
        #expect(OptionalTArray<Int>.pure(1).rawValue == [1])
    }

    // MARK: - ArrayTResult (ExceptT over a data outer)

    @Test func arrayTResultNamedSurface() {
        let nested: [Result<Int, Err>] = [.success(1), .failure(.fail)]
        let stack = nested.arrayT
        let double: @Sendable (Int) -> Int = { $0 * 2 }

        #expect(stack.map(double).rawValue == [.success(2), .failure(.fail)])
        #expect(stack.mapExceptT { $0.reversed() }.rawValue == [.failure(.fail), .success(1)])
    }
}
