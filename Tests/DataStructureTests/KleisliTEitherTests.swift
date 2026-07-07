// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

private enum ComputationError: Error, Equatable {
    case tooSmall
}

@Suite struct KleisliTEitherTests {
    // MARK: - ArrayTEither: [Either<L, A>]

    @Test func arrayTEitherComposition() {
        let positive: @Sendable (Int) -> [Either<String, Int>] = { n in
            n > 0 ? [.right(n)] : [.left("non-positive")]
        }
        let fanOut: @Sendable (Int) -> [Either<String, Int>] = { n in
            [.right(n), .right(n * 10)]
        }
        let pipeline = kleisliT(positive, fanOut)
        #expect(pipeline(3) == [.right(3), .right(30)])
        #expect(pipeline(-1) == [.left("non-positive")])
    }

    // MARK: - EitherTArray: Either<L, [A]>

    @Test func eitherTArrayComposition() {
        let positive: @Sendable (Int) -> Either<String, [Int]> = { n in
            n > 0 ? .right([n, n + 1]) : .left("non-positive")
        }
        let doubled: @Sendable (Int) -> Either<String, [Int]> = { n in
            .right([n * 2])
        }
        let pipeline = kleisliT(positive, doubled)
        #expect(pipeline(3) == .right([6, 8]))
        #expect(pipeline(0) == .left("non-positive"))
    }

    // MARK: - EitherTOptional: Either<L, A?>

    @Test func eitherTOptionalComposition() {
        let halved: @Sendable (Int) -> Either<String, Int?> = { n in
            n.isMultiple(of: 2) ? .right(n / 2) : .right(nil)
        }
        let positive: @Sendable (Int) -> Either<String, Int?> = { n in
            n > 0 ? .right(n) : .left("non-positive")
        }
        let pipeline = kleisliT(halved, positive)
        #expect(pipeline(8) == .right(4))
        #expect(pipeline(3) == .right(nil))
        #expect(pipeline(-2) == .left("non-positive"))
    }

    // MARK: - EitherTResult: Either<L, Result<A, E>>

    @Test func eitherTResultComposition() {
        let validated: @Sendable (Int) -> Either<String, Result<Int, ComputationError>> = { n in
            n > 0 ? .right(.success(n)) : .right(.failure(.tooSmall))
        }
        let doubled: @Sendable (Int) -> Either<String, Result<Int, ComputationError>> = { n in
            n < 100 ? .right(.success(n * 2)) : .left("overflow")
        }
        let pipeline = kleisliT(validated, doubled)
        #expect(pipeline(21) == .right(.success(42)))
        #expect(pipeline(-1) == .right(.failure(.tooSmall)))
        #expect(pipeline(200) == .left("overflow"))
    }

    // MARK: - EitherTStateful: Either<L, Stateful<S, A>>

    @Test func eitherTStatefulComposition() {
        let positive: @Sendable (Int) -> Either<String, Stateful<Int, Int>> = { n in
            n > 0 ? .right(.pure(n)) : .left("non-positive")
        }
        let addedToState: @Sendable (Int) -> Stateful<Int, Int> = { n in
            .gets { s in s + n }
        }
        let pipeline = kleisliT(positive, addedToState)
        #expect(pipeline(5).mapRight { $0.eval(10) } == .right(15))
        #expect(pipeline(-1).mapRight { $0.eval(10) } == .left("non-positive"))
    }

    // MARK: - EitherTWriter: Either<L, Writer<W, A>>

    @Test func eitherTWriterComposition() {
        let doubled: @Sendable (Int) -> Either<String, Writer<[String], Int>> = { n in
            n > 0 ? .right(Writer(n * 2, ["doubled"])) : .left("non-positive")
        }
        let stringified: @Sendable (Int) -> Writer<[String], String> = { n in
            Writer("\(n)", ["stringified"])
        }
        let pipeline = kleisliT(doubled, stringified)
        let success = pipeline(21)
        #expect(success.mapRight { $0.value } == .right("42"))
        #expect(success.mapRight { $0.log } == .right(["doubled", "stringified"]))
        #expect(pipeline(0).mapRight { $0.value } == .left("non-positive"))
    }

    // MARK: - OptionalTEither: Either<L, A>?

    @Test func optionalTEitherComposition() {
        let positive: @Sendable (Int) -> Either<String, Int>? = { n in
            n > 0 ? .right(n) : .left("non-positive")
        }
        let bounded: @Sendable (Int) -> Either<String, Int>? = { n in
            n < 100 ? .right(n * 2) : nil
        }
        let pipeline = kleisliT(positive, bounded)
        #expect(pipeline(21) == .right(42))
        #expect(pipeline(-1) == .left("non-positive"))
        #expect(pipeline(200) == nil)
    }
}
