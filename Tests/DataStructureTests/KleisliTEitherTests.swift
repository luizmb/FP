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
        let pipeline = ArrayTEither<String, Int>.kleisli({ positive($0).arrayT }, { fanOut($0).arrayT })
        #expect(pipeline(3).rawValue == [.right(3), .right(30)])
        #expect(pipeline(-1).rawValue == [.left("non-positive")])
    }

    // MARK: - EitherTOptional: Either<L, A?>

    @Test func eitherTOptionalComposition() {
        let halved: @Sendable (Int) -> Either<String, Int?> = { n in
            n.isMultiple(of: 2) ? .right(n / 2) : .right(nil)
        }
        let positive: @Sendable (Int) -> Either<String, Int?> = { n in
            n > 0 ? .right(n) : .left("non-positive")
        }
        let pipeline = EitherTOptional<String, Int>.kleisli({ halved($0).eitherT }, { positive($0).eitherT })
        #expect(pipeline(8).rawValue == .right(4))
        #expect(pipeline(3).rawValue == .right(nil))
        #expect(pipeline(-2).rawValue == .left("non-positive"))
    }

    // MARK: - EitherTResult: Either<L, Result<A, E>>

    @Test func eitherTResultComposition() {
        let validated: @Sendable (Int) -> Either<String, Result<Int, ComputationError>> = { n in
            n > 0 ? .right(.success(n)) : .right(.failure(.tooSmall))
        }
        let doubled: @Sendable (Int) -> Either<String, Result<Int, ComputationError>> = { n in
            n < 100 ? .right(.success(n * 2)) : .left("overflow")
        }
        let pipeline = EitherTResult<String, ComputationError, Int>.kleisli({ validated($0).eitherT }, { doubled($0).eitherT })
        #expect(pipeline(21).rawValue == .right(.success(42)))
        #expect(pipeline(-1).rawValue == .right(.failure(.tooSmall)))
        #expect(pipeline(200).rawValue == .left("overflow"))
    }

    // MARK: - EitherTWriter: Either<L, Writer<W, A>>

    @Test func eitherTWriterComposition() {
        let doubled: @Sendable (Int) -> Either<String, Writer<[String], Int>> = { n in
            n > 0 ? .right(Writer(n * 2, ["doubled"])) : .left("non-positive")
        }
        let stringified: @Sendable (Int) -> Either<String, Writer<[String], String>> = { n in
            .right(Writer("\(n)", ["stringified"]))
        }
        let pipeline = EitherTWriter<String, [String], Int>.kleisli({ doubled($0).eitherT }, { stringified($0).eitherT })
        let success = pipeline(21).rawValue
        #expect(success.mapRight { $0.value } == .right("42"))
        #expect(success.mapRight { $0.log } == .right(["doubled", "stringified"]))
        #expect(pipeline(0).rawValue.mapRight { $0.value } == .left("non-positive"))
    }

    // MARK: - OptionalTEither: Either<L, A>?

    @Test func optionalTEitherComposition() {
        let positive: @Sendable (Int) -> Either<String, Int>? = { n in
            n > 0 ? .right(n) : .left("non-positive")
        }
        let bounded: @Sendable (Int) -> Either<String, Int>? = { n in
            n < 100 ? .right(n * 2) : nil
        }
        let pipeline = OptionalTEither<String, Int>.kleisli({ positive($0).optionalT }, { bounded($0).optionalT })
        #expect(pipeline(21).rawValue == .right(42))
        #expect(pipeline(-1).rawValue == .left("non-positive"))
        #expect(pipeline(200).rawValue == nil)
    }
}
