import DataStructureOperators
import DataStructure
import Testing
@testable import CoreFP
@testable import CoreFPOperators

@Suite struct EitherTransformerTests {

    private enum L: Equatable { case err }
    private enum E: Error, Equatable { case fail }

    // MARK: - ArrayTEither

    @Test func arrayTEitherMapT() {
        let arr: [Either<L, Int>] = [.right(1), .left(.err), .right(3)]
        let result = arr.mapT { $0 * 2 }
        #expect(result == [.right(2), .left(.err), .right(6)])
    }

    @Test func arrayTEitherFlatMapT() {
        let arr: [Either<L, Int>] = [.right(1), .left(.err), .right(2)]
        let result = arr.flatMapT { n in [Either<L, Int>.right(n), .right(n * 10)] }
        #expect(result == [.right(1), .right(10), .left(.err), .right(2), .right(20)])
    }

    @Test func arrayTEitherLiftA2() {
        let a: [Either<L, Int>] = [.right(1), .right(2)]
        let b: [Either<L, Int>] = [.right(10), .right(20)]
        let result = liftA2ArrayEither(+)(a, b)
        #expect(result == [.right(11), .right(21), .right(12), .right(22)])
    }

    @Test func arrayTEitherFmapOperator() {
        let arr: [Either<L, Int>] = [.right(5), .left(.err)]
        let result = { $0 * 2 } <£> arr
        #expect(result == [.right(10), .left(.err)])
    }

    @Test func arrayTEitherBindOperator() {
        let arr: [Either<L, Int>] = [.right(1), .right(2)]
        let result = arr >>- { n in [Either<L, Int>.right(n * 2)] }
        #expect(result == [.right(2), .right(4)])
    }

    // MARK: - OptionalTEither

    @Test func optionalTEitherMapTSomeRight() {
        let opt: Either<L, Int>? = .right(5)
        let result = opt.mapT { $0 * 2 }
        #expect(result == .some(.right(10)))
    }

    @Test func optionalTEitherMapTSomeLeft() {
        let opt: Either<L, Int>? = .left(.err)
        let result = opt.mapT { $0 * 2 }
        #expect(result == .some(.left(.err)))
    }

    @Test func optionalTEitherMapTNone() {
        let opt: Either<L, Int>? = nil
        let result = opt.mapT { $0 * 2 }
        #expect(result == nil)
    }

    @Test func optionalTEitherFlatMapTNone() {
        let opt: Either<L, Int>? = nil
        let result = opt.flatMapT { n in Either<L, String>.right("\(n)") }
        #expect(result == nil)
    }

    @Test func optionalTEitherFlatMapTSomeLeft() {
        let opt: Either<L, Int>? = .left(.err)
        let result = opt.flatMapT { n in Either<L, String>.right("\(n)") }
        #expect(result == .some(.left(.err)))
    }

    @Test func optionalTEitherFlatMapTSomeRight() {
        let opt: Either<L, Int>? = .right(5)
        let result = opt.flatMapT { n in Either<L, String>?.some(.right("\(n)")) }
        #expect(result == .some(.right("5")))
    }

    // MARK: - EitherTOptional

    @Test func eitherTOptionalMapTRightSome() {
        let either: Either<L, Int?> = .right(.some(5))
        let result = fmapTEitherOptional { $0 * 2 }(either)
        #expect(result == .right(.some(10)))
    }

    @Test func eitherTOptionalMapTRightNone() {
        let either: Either<L, Int?> = .right(.none)
        let result = fmapTEitherOptional { $0 * 2 }(either)
        #expect(result == .right(.none))
    }

    @Test func eitherTOptionalMapTLeft() {
        let either: Either<L, Int?> = .left(.err)
        let result = fmapTEitherOptional { $0 * 2 }(either)
        #expect(result == .left(.err))
    }

    @Test func eitherTOptionalFlatMapTRightSome() {
        let either: Either<L, Int?> = .right(.some(5))
        let result = flatMapTEitherOptional(either) { n in Either<L, String?>.right(.some("\(n)")) }
        #expect(result == .right(.some("5")))
    }

    @Test func eitherTOptionalFlatMapTRightNone() {
        let either: Either<L, Int?> = .right(.none)
        let result = flatMapTEitherOptional(either) { n in Either<L, String?>.right(.some("\(n)")) }
        #expect(result == .right(.none))
    }

    @Test func eitherTOptionalFlatMapTLeft() {
        let either: Either<L, Int?> = .left(.err)
        let result = flatMapTEitherOptional(either) { n in Either<L, String?>.right(.some("\(n)")) }
        #expect(result == .left(.err))
    }

    // MARK: - EitherTArray

    @Test func eitherTArrayMapTRight() {
        let either: Either<L, [Int]> = .right([1, 2, 3])
        let result = fmapTEitherArray { $0 * 2 }(either)
        #expect(result == .right([2, 4, 6]))
    }

    @Test func eitherTArrayMapTLeft() {
        let either: Either<L, [Int]> = .left(.err)
        let result = fmapTEitherArray { $0 * 2 }(either)
        #expect(result == .left(.err))
    }

    @Test func eitherTArrayFlatMapTRight() {
        let either: Either<L, [Int]> = .right([1, 2])
        let result = flatMapTEitherArray(either) { n in Either<L, [String]>.right(["\(n)", "\(n * 10)"]) }
        #expect(result == .right(["1", "10", "2", "20"]))
    }

    @Test func eitherTArrayFlatMapTLeft() {
        let either: Either<L, [Int]> = .left(.err)
        let result = flatMapTEitherArray(either) { n in Either<L, [String]>.right(["\(n)"]) }
        #expect(result == .left(.err))
    }

    // MARK: - EitherTResult

    @Test func eitherTResultMapTRightSuccess() throws {
        let either: Either<L, Result<Int, E>> = .right(.success(5))
        let result = fmapTEitherResult { $0 * 2 }(either)
        #expect(result == .right(.success(10)))
    }

    @Test func eitherTResultMapTRightFailure() {
        let either: Either<L, Result<Int, E>> = .right(.failure(.fail))
        let result = fmapTEitherResult { $0 * 2 }(either)
        #expect(result == .right(.failure(.fail)))
    }

    @Test func eitherTResultMapTLeft() {
        let either: Either<L, Result<Int, E>> = .left(.err)
        let result = fmapTEitherResult { $0 * 2 }(either)
        #expect(result == .left(.err))
    }

    @Test func eitherTResultFlatMapTRightSuccess() {
        let either: Either<L, Result<Int, E>> = .right(.success(5))
        let result = flatMapTEitherResult(either) { n in Either<L, Result<String, E>>.right(.success("\(n)")) }
        #expect(result == .right(.success("5")))
    }

    @Test func eitherTResultFlatMapTRightFailure() {
        let either: Either<L, Result<Int, E>> = .right(.failure(.fail))
        let result = flatMapTEitherResult(either) { n in Either<L, Result<String, E>>.right(.success("\(n)")) }
        #expect(result == .right(.failure(.fail)))
    }

    @Test func eitherTResultFlatMapTLeft() {
        let either: Either<L, Result<Int, E>> = .left(.err)
        let result = flatMapTEitherResult(either) { n in Either<L, Result<String, E>>.right(.success("\(n)")) }
        #expect(result == .left(.err))
    }
}
