// SPDX-License-Identifier: Apache-2.0
import CoreFP
@testable import DataStructure
import Foundation
import Testing

// MARK: - Fixtures

private let one = NonEmpty(head: 1)
private let two = NonEmpty(head: 1, tail: [2])
private let three = NonEmpty(head: 1, tail: [2, 3])

private enum TestError: Error, Equatable { case bad(String) }

@Suite struct NonEmptyTests {
    // MARK: - Construction

    @Test func init_singleElement() {
        let ne = NonEmpty(head: 42)
        #expect(ne.head == 42)
        #expect(ne.tail == [])
    }

    @Test func init_withTail() {
        let ne = NonEmpty(head: 1, tail: [2, 3])
        #expect(ne.head == 1)
        #expect(ne.tail == [2, 3])
    }

    @Test func freeConstructor_headTail() {
        let ne = nonEmpty(head: 1, tail: [2, 3])
        #expect(ne.toArray == [1, 2, 3])
    }

    @Test func freeConstructor_fromArray_nonEmpty() {
        let ne = nonEmpty([1, 2, 3])
        #expect(ne?.toArray == [1, 2, 3])
    }

    @Test func freeConstructor_fromArray_empty() {
        let ne = nonEmpty([Int]())
        #expect(ne == nil)
    }

    // MARK: - Primitives

    @Test func last_singleElement() {
        #expect(NonEmpty(head: 7).last == 7)
    }

    @Test func last_multipleElements() {
        #expect(three.last == 3)
    }

    @Test func count() {
        #expect(one.count == 1)
        #expect(two.count == 2)
        #expect(three.count == 3)
    }

    @Test func toArray() {
        #expect(three.toArray == [1, 2, 3])
    }

    @Test func prepend() {
        let ne = three.prepend(0)
        #expect(ne.toArray == [0, 1, 2, 3])
    }

    @Test func append_single() {
        let ne = three.append(4)
        #expect(ne.toArray == [1, 2, 3, 4])
    }

    @Test func append_contentsOf() {
        let ne = three.append(contentsOf: [4, 5])
        #expect(ne.toArray == [1, 2, 3, 4, 5])
    }

    @Test func reversed() {
        #expect(three.reversed.toArray == [3, 2, 1])
    }

    @Test func safeSubscript_valid() {
        #expect(three[safe: 0] == 1)
        #expect(three[safe: 2] == 3)
    }

    @Test func safeSubscript_outOfBounds() {
        #expect(three[safe: 5] == nil)
        #expect(three[safe: -1] == nil)
    }

    // MARK: - Equatable / Comparable

    @Test func equatable() {
        let ne1 = NonEmpty(head: 1, tail: [2])
        let ne2 = NonEmpty(head: 1, tail: [2])
        #expect(ne1 == ne2)
        #expect(NonEmpty(head: 1, tail: [2]) != NonEmpty(head: 1, tail: [3]))
    }

    @Test func comparable() {
        #expect(NonEmpty(head: 1, tail: [2]) < NonEmpty(head: 1, tail: [3]))
        #expect(NonEmpty(head: 2) > NonEmpty(head: 1, tail: [9, 9]))
    }

    // MARK: - Semigroup (NO Monoid)

    @Test func semigroup_combine() {
        let lhs = NonEmpty(head: 1, tail: [2])
        let rhs = NonEmpty(head: 3, tail: [4])
        #expect(NonEmpty.combine(lhs, rhs).toArray == [1, 2, 3, 4])
    }

    @Test func semigroup_combine_associativity() {
        let a = NonEmpty(head: 1)
        let b = NonEmpty(head: 2)
        let c = NonEmpty(head: 3)
        let left = NonEmpty.combine(NonEmpty.combine(a, b), c)
        let right = NonEmpty.combine(a, NonEmpty.combine(b, c))
        #expect(left == right)
    }

    @Test func sconcat_nonEmpty() {
        let ne: NonEmpty<NonEmpty<Int>> = NonEmpty(
            head: NonEmpty(head: 1, tail: [2]),
            tail: [NonEmpty(head: 3), NonEmpty(head: 4, tail: [5])]
        )
        #expect(sconcat(ne).toArray == [1, 2, 3, 4, 5])
    }

    // MARK: - Functor

    @Test func map() {
        #expect(three.map { $0 * 10 }.toArray == [10, 20, 30])
    }

    @Test func map_instance() {
        #expect(three.map { $0 + 1 }.toArray == [2, 3, 4])
    }

    @Test func fmap_static() {
        let double = NonEmpty<Int>.fmap { $0 * 2 }
        #expect(double(three).toArray == [2, 4, 6])
    }

    @Test func map_preservesHead() {
        let ne = three.map { $0 * 0 }
        #expect(ne.head == 0)
    }

    // MARK: - Functor laws

    @Test func functorLaw_identity() {
        #expect(three.map(id) == three)
    }

    @Test func functorLaw_composition() {
        let f: @Sendable (Int) -> Int = { $0 + 1 }
        let g: @Sendable (Int) -> Int = { $0 * 2 }
        #expect(three.map(compose(f, g)) == three.map(f).map(g))
    }

    // MARK: - Applicative

    @Test func pure() {
        let ne = NonEmpty<Int>.pure(42)
        #expect(ne.toArray == [42])
    }

    @Test func apply_singleFunction() {
        let nf = NonEmpty<@Sendable (Int) -> Int>(head: { $0 * 2 })
        let na = NonEmpty(head: 1, tail: [2, 3])
        #expect(NonEmpty.apply(nf, na).toArray == [2, 4, 6])
    }

    @Test func apply_multipleFunctions() {
        let nf = NonEmpty<@Sendable (Int) -> Int>(head: { $0 + 1 }, tail: [{ $0 * 10 }])
        let na = NonEmpty(head: 1, tail: [2])
        // cartesian: (+1)(1), (+1)(2), (*10)(1), (*10)(2)
        #expect(NonEmpty.apply(nf, na).toArray == [2, 3, 10, 20])
    }

    @Test func zip_byIndex() {
        let na = NonEmpty(head: 1, tail: [2, 3])
        let nb = NonEmpty(head: "a", tail: ["b"])
        let zipped = NonEmpty<(Int, String)>.zip(na, nb)
        // shortest wins: 2 elements
        #expect(zipped.count == 2)
        #expect(zipped.head == (1, "a"))
    }

    @Test func liftA2() {
        let add = NonEmpty<Int>.liftA2(+)
        let result = add(NonEmpty(head: 1, tail: [2]), NonEmpty(head: 10, tail: [20]))
        #expect(result.toArray == [11, 21, 12, 22])
    }

    // MARK: - Monad

    @Test func flatMap_expandsElements() {
        let ne = NonEmpty(head: 1, tail: [2, 3])
        let result = ne.flatMap { n in NonEmpty(head: n, tail: [n * 10]) }
        #expect(result.toArray == [1, 10, 2, 20, 3, 30])
    }

    @Test func flatMap_singleton() {
        let ne = NonEmpty(head: 5)
        let result = ne.flatMap { n in NonEmpty(head: n + 1) }
        #expect(result.toArray == [6])
    }

    @Test func bind_static() {
        let double: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0, tail: [$0]) }
        let result = NonEmpty<Int>.bind(double)(NonEmpty(head: 3))
        #expect(result.toArray == [3, 3])
    }

    @Test func kleisli_composition() {
        let f: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0 + 1) }
        let g: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0 * 2) }
        let fg = NonEmpty<Int>.kleisli(f, g)
        #expect(fg(3).toArray == [8]) // (3+1)*2
    }

    @Test func join_flattens() {
        let nested = NonEmpty<NonEmpty<Int>>(
            head: NonEmpty(head: 1, tail: [2]),
            tail: [NonEmpty(head: 3)]
        )
        #expect(NonEmpty<NonEmpty<Int>>.join(nested).toArray == [1, 2, 3])
    }

    @Test func seqRight_cartesian() {
        let a = NonEmpty(head: 1, tail: [2])
        let b = NonEmpty(head: "x", tail: ["y"])
        // each element of a produces b: [x, y, x, y]
        #expect(a.seqRight(b).toArray == ["x", "y", "x", "y"])
    }

    @Test func seqLeft_cartesian() {
        let a = NonEmpty(head: 1, tail: [2])
        let b = NonEmpty(head: "x", tail: ["y"])
        // each element of b produces one copy of a element: [1, 1, 2, 2]
        #expect(a.seqLeft(b).toArray == [1, 1, 2, 2])
    }

    // MARK: - Monad laws

    @Test func monadLaw_leftIdentity() {
        let f: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0 * 2) }
        #expect(NonEmpty.pure(3).flatMap(f) == f(3))
    }

    @Test func monadLaw_rightIdentity() {
        #expect(three.flatMap(NonEmpty.pure) == three)
    }

    @Test func monadLaw_associativity() {
        let f: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0 + 1) }
        let g: @Sendable (Int) -> NonEmpty<Int> = { NonEmpty(head: $0 * 2) }
        #expect(three.flatMap(f).flatMap(g) == three.flatMap { f($0).flatMap(g) })
    }

    // MARK: - Foldable

    @Test func foldLeft() {
        #expect(three.foldLeft(0, +) == 6)
        #expect(three.foldLeft(1, *) == 6)
    }

    @Test func foldRight() {
        // foldRight(-)(0)([1,2,3]) = 1-(2-(3-0)) = 2
        #expect(three.foldRight(0, -) == 2)
    }

    @Test func foldMap() {
        let sum = three.foldMap { Int.Monoids.Sum($0) }
        #expect(sum.rawValue == 6)
    }

    @Test func toList() {
        #expect(three.toList == [1, 2, 3])
    }

    // MARK: - Traversable (Optional effect)

    @Test func traverse_optional_allPresent() {
        let ne = NonEmpty(head: "1", tail: ["2", "3"])
        let result = ne.traverse { Int($0) }
        #expect(result?.toArray == [1, 2, 3])
    }

    @Test func traverse_optional_someFail() {
        let ne = NonEmpty(head: "1", tail: ["x", "3"])
        #expect(ne.traverse { Int($0) } == nil)
    }

    @Test func sequence_optional_allPresent() {
        let ne = NonEmpty<Int?>(head: 1, tail: [2, 3])
        #expect(ne.sequence()?.toArray == [1, 2, 3])
    }

    @Test func sequence_optional_hasNil() {
        let ne = NonEmpty<Int?>(head: 1, tail: [nil, 3])
        #expect(ne.sequence() == nil)
    }

    // MARK: - Traversable (Result effect)

    @Test func traverse_result_allSuccess() {
        let ne = NonEmpty(head: "1", tail: ["2", "3"])
        let result = ne.traverse { s -> Result<Int, TestError> in
            Int(s).map { .success($0) } ?? .failure(.bad(s))
        }
        #expect(result == .success(NonEmpty(head: 1, tail: [2, 3])))
    }

    @Test func traverse_result_firstFailure() {
        let ne = NonEmpty(head: "1", tail: ["x", "3"])
        let result = ne.traverse { s -> Result<Int, TestError> in
            Int(s).map { .success($0) } ?? .failure(.bad(s))
        }
        #expect(result == .failure(.bad("x")))
    }

    // MARK: - Transformer: NonEmpty<A?>

    @Test func nonEmptyTOptional_mapT() {
        let ne = NonEmpty<Int?>(head: 1, tail: [nil, 3])
        let result = ne.mapT { $0 * 10 }
        #expect(result.toArray == [Optional(10), nil, Optional(30)])
    }

    @Test func nonEmptyTOptional_flatMapT() {
        let ne = NonEmpty<Int?>(head: 2, tail: [nil])
        let result = ne.flatMapT { n in NonEmpty<Int?>(head: n * 2) }
        #expect(result.toArray == [Optional(4), nil])
    }

    // MARK: - Transformer: NonEmpty<Result<E, A>>

    @Test func nonEmptyTResult_mapT() {
        let ne = NonEmpty<Result<Int, TestError>>(
            head: .success(1),
            tail: [.failure(.bad("err")), .success(3)]
        )
        let result = ne.mapT { $0 * 10 }
        #expect(result.toArray == [.success(10), .failure(.bad("err")), .success(30)])
    }

    @Test func nonEmptyTResult_flatMapT() {
        let ne = NonEmpty<Result<Int, TestError>>(
            head: .success(5),
            tail: [.failure(.bad("err"))]
        )
        let result = ne.flatMapT { n in
            NonEmpty<Result<Int, TestError>>(head: .success(n * 2))
        }
        #expect(result.toArray == [.success(10), .failure(.bad("err"))])
    }

    // MARK: - Traversable (Either effect)

    @Test func traverse_either_allRight() {
        let ne = NonEmpty(head: "1", tail: ["2", "3"])
        let result: Either<String, NonEmpty<Int>> = ne.traverse { s in
            Int(s).map { Either.right($0) } ?? .left("bad: \(s)")
        }
        #expect(result == .right(NonEmpty(head: 1, tail: [2, 3])))
    }

    @Test func traverse_either_firstLeft() {
        let ne = NonEmpty(head: "1", tail: ["x", "3"])
        let result: Either<String, NonEmpty<Int>> = ne.traverse { s in
            Int(s).map { Either.right($0) } ?? .left("bad: \(s)")
        }
        #expect(result == .left("bad: x"))
    }

    @Test func sequence_either_allRight() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.right(2), .right(3)])
        #expect(ne.sequence() == .right(NonEmpty(head: 1, tail: [2, 3])))
    }

    @Test func sequence_either_hasLeft() {
        let ne = NonEmpty<Either<String, Int>>(head: .right(1), tail: [.left("err"), .right(3)])
        #expect(ne.sequence() == .left("err"))
    }

    // MARK: - Traversable (Validation effect)

    @Test func traverse_validation_allSuccess() {
        let ne = NonEmpty(head: "1", tail: ["2", "3"])
        let result: Validation<NonEmpty<String>, NonEmpty<Int>> = ne.traverse { s in
            Int(s).map { .success($0) } ?? .failure(NonEmpty(head: "bad: \(s)"))
        }
        #expect(result == .success(NonEmpty(head: 1, tail: [2, 3])))
    }

    @Test func traverse_validation_accumulatesAllFailures() {
        let ne = NonEmpty(head: "x", tail: ["2", "y"])
        let result: Validation<NonEmpty<String>, NonEmpty<Int>> = ne.traverse { s in
            Int(s).map { .success($0) } ?? .failure(NonEmpty(head: "bad: \(s)"))
        }
        #expect(result == .failure(NonEmpty(head: "bad: x", tail: ["bad: y"])))
    }

    @Test func sequence_validation_allSuccess() {
        let ne = NonEmpty<Validation<NonEmpty<String>, Int>>(
            head: .success(1), tail: [.success(2), .success(3)]
        )
        #expect(ne.sequence() == .success(NonEmpty(head: 1, tail: [2, 3])))
    }

    @Test func sequence_validation_accumulatesAllFailures() {
        let ne = NonEmpty<Validation<NonEmpty<String>, Int>>(
            head: .failure(NonEmpty(head: "e1")),
            tail: [.success(2), .failure(NonEmpty(head: "e3"))]
        )
        #expect(ne.sequence() == .failure(NonEmpty(head: "e1", tail: ["e3"])))
    }

    // MARK: - Transformer: Optional<NonEmpty<A>>

    @Test func optionalTNonEmpty_mapT() {
        let opt: NonEmpty<Int>? = NonEmpty(head: 1, tail: [2, 3])
        let result = opt.mapT { $0 * 10 }
        #expect(result?.toArray == [10, 20, 30])
    }

    @Test func optionalTNonEmpty_mapT_nil() {
        let opt: NonEmpty<Int>? = nil
        #expect(opt.mapT { $0 * 10 } == nil)
    }

    @Test func optionalTNonEmpty_flatMapT() {
        let opt: NonEmpty<Int>? = NonEmpty(head: 1, tail: [2])
        let result = opt.flatMapT { n -> NonEmpty<Int>? in
            n > 1 ? NonEmpty(head: n * 10) : nil
        }
        // 1 → nil (dropped), 2 → NonEmpty(20) → combined result = NonEmpty(20)
        #expect(result?.toArray == [20])
    }

    @Test func optionalTNonEmpty_flatMapT_allNil() {
        let opt: NonEmpty<Int>? = NonEmpty(head: 1)
        let result = opt.flatMapT { _ -> NonEmpty<Int>? in nil }
        #expect(result == nil)
    }

    // MARK: - Conditional conformances

    @Test func codable_roundTrip() throws {
        let ne = NonEmpty(head: 1, tail: [2, 3])
        let data = try JSONEncoder().encode(ne)
        let decoded = try JSONDecoder().decode(NonEmpty<Int>.self, from: data)
        #expect(decoded == ne)
    }

    @Test func codable_singleElement() throws {
        let ne = NonEmpty(head: "only")
        let data = try JSONEncoder().encode(ne)
        let decoded = try JSONDecoder().decode(NonEmpty<String>.self, from: data)
        #expect(decoded == ne)
    }

    @Test func rawRepresentable_rawValue() {
        let ne = NonEmpty(head: 1, tail: [2, 3])
        #expect(ne.rawValue == [1, 2, 3])
    }

    @Test func rawRepresentable_initFromNonEmptyArray() {
        let ne = NonEmpty<Int>(rawValue: [1, 2, 3])
        #expect(ne?.head == 1)
        #expect(ne?.tail == [2, 3])
    }

    @Test func rawRepresentable_initFromEmptyArrayIsNil() {
        let ne = NonEmpty<Int>(rawValue: [])
        #expect(ne == nil)
    }

    @Test func rawRepresentable_roundTrip() {
        let original = NonEmpty(head: 1, tail: [2, 3])
        let roundTripped = NonEmpty<Int>(rawValue: original.rawValue)
        #expect(roundTripped == original)
    }
}
