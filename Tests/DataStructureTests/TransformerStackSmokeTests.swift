// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

/// Smoke tests for the generated newtype stacks (named API), one representative per family:
/// Reader outer, Writer inner, applicative-only (Compose-like) and Stateful outer.
@Suite struct TransformerStackSmokeTests {
    // MARK: - ReaderTArray (ReaderT family)

    @Test func readerTArraySurface() {
        let nested = Reader<Int, [Int]> { [$0, $0 + 1] }
        let stack = nested.readerT
        let double: @Sendable (Int) -> Int = { $0 * 2 }
        let next: @Sendable (Int) -> ReaderTArray<Int, Int> = { a in ReaderTArray(Reader { [a, $0] }) }

        #expect(stack.map(double).rawValue(1) == [2, 4])
        #expect(stack.flatMap(next).rawValue(1) == [1, 1, 2, 1])
        #expect(ReaderTArray<Int, Int>.pure(5).rawValue(0) == [5])
        #expect(stack.seqLeft(stack).rawValue(1) == [1, 1, 2, 2])
        #expect(ReaderTArray<Int, Int>.kleisli(next, next)(3).rawValue(1) == [3, 1, 1, 1])
        #expect(stack.mapReaderT { $0.local { $0 * 10 } }.rawValue(1) == [10, 11])
    }

    // MARK: - OptionalTWriter (WriterT family)

    @Test func optionalTWriterMatchesNestedSurface() {
        let nested: Writer<[String], Int>? = Writer(1, ["one"])
        let stack = nested.optionalT
        let next: @Sendable (Int) -> OptionalTWriter<[String], Int> = { OptionalTWriter(Writer($0 + 1, ["inc"])) }

        #expect(stack.map { $0 * 2 }.rawValue == nested.mapT { $0 * 2 })
        #expect(stack.flatMap(next).rawValue == Writer(2, ["one", "inc"]))
        #expect(OptionalTWriter<[String], Int>.pure(3).rawValue == Writer(3, []))
        #expect(stack.mapWriterT { (_: Writer<[String], Int>?) -> Writer<[String], Int>? in nil }.rawValue == nil)
    }

    // MARK: - ValidationTArray (applicative-only, Compose-like)

    @Test func validationTArrayMatchesNestedSurface() {
        let left: Validation<[String], [Int]> = .failure(["a"])
        let right: Validation<[String], [Int]> = .failure(["b"])
        let add: @Sendable (Int, Int) -> Int = { $0 + $1 }

        #expect(ValidationTArray<[String], Int>.liftA2(add)(left.validationT, right.validationT).rawValue == .failure(["a", "b"]))
        #expect(left.validationT.seqRight(right.validationT).rawValue == .failure(["a", "b"]))
        #expect(ValidationTArray<[String], Int>.pure(1).rawValue == .success([1]))
    }

    // MARK: - StatefulTEither (StateT family)

    @Test func statefulTEitherMatchesNestedSurface() {
        let nested = Stateful<Int, Either<String, Int>> { state in
            state += 1
            return .right(state)
        }
        let stack = nested.statefulT
        let next: @Sendable (Int) -> StatefulTEither<Int, String, Int> = const(StatefulTEither(Stateful { .right($0 * 10) }))

        let (value, state) = stack.flatMap(next).rawValue.runStateful(0)
        #expect(value == .right(10))
        #expect(state == 1)
    }
}
