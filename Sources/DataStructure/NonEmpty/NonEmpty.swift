// SPDX-License-Identifier: Apache-2.0

// MARK: - NonEmpty<A>

/// A sequence guaranteed to contain at least one element.
///
/// `NonEmpty<A>` encodes the invariant "this collection is never empty" at the type level,
/// eliminating the need for `guard !array.isEmpty` checks and optional returns.
///
/// It stores its elements as `head: A` (the guaranteed first element) plus `tail: [A]`
/// (any remaining elements, possibly empty). This structure is efficient and clearly
/// communicates the non-empty contract.
///
/// ## Semigroup, not Monoid
///
/// `NonEmpty<A>` is a ``Semigroup`` — two non-empty sequences always combine into a
/// non-empty sequence via element concatenation. It deliberately has **no ``Monoid``**
/// instance because there is no empty value to serve as the identity element.
///
/// Use ``sconcat(_:_:)`` (not ``mconcat(_:)``) when folding a collection of `NonEmpty` values:
///
/// ```swift
/// let all: NonEmpty<Int> = sconcat(first, rest)
/// ```
///
/// ## Creating NonEmpty
///
/// ```swift
/// // Direct init:
/// let digits = NonEmpty(head: 1, tail: [2, 3])
///
/// // Free functions:
/// let single = nonEmpty(head: 42)               // NonEmpty(head: 42, tail: [])
/// let fromArray: NonEmpty<Int>? = nonEmpty([1, 2, 3])  // nil if empty
/// ```
///
/// ## Accessing elements
///
/// ```swift
/// digits.head     // 1
/// digits.tail     // [2, 3]
/// digits.toArray  // [1, 2, 3]  (from NonEmpty+Primitives)
/// digits.last     // 3          (from NonEmpty+Primitives)
/// digits.count    // 3          (from NonEmpty+Primitives)
/// ```
///
/// ## Functor / Monad
///
/// `NonEmpty` is a `Functor` and `Monad` (the monad is a "non-empty list monad"):
///
/// ```swift
/// let doubled: NonEmpty<Int> = digits.map { $0 * 2 }
///
/// // flatMap (Kleisli arrow for the non-empty list monad):
/// let expanded: NonEmpty<Int> = digits.flatMap { n in NonEmpty(head: n, tail: [-n]) }
/// ```
///
/// ## Use as error accumulator
///
/// `NonEmpty<[E]>` or `NonEmpty<E>` is an ideal error type for ``Validation``
/// because it enforces that at least one error is present in the `failure` case:
///
/// ```swift
/// typealias Errors = NonEmpty<[String]>
/// let result: Validation<Errors, User> = validateForm(input)
/// ```
///
/// - SeeAlso: ``Validation``, ``Semigroup``, ``sconcat(_:_:)``
public struct NonEmpty<A> {
    /// The guaranteed first element.
    public let head: A
    /// The remaining elements, which may be empty.
    public let tail: [A]

    /// Constructs a `NonEmpty` from a guaranteed `head` element plus an optional `tail`.
    /// - Parameters:
    ///   - head: The guaranteed first element.
    ///   - tail: Any remaining elements. Defaults to empty.
    public init(head: A, tail: [A] = []) {
        self.head = head
        self.tail = tail
    }
}

// MARK: - Free constructors

/// Construct a `NonEmpty` from a head and an optional tail.
public func nonEmpty<A>(head: A, tail: [A] = []) -> NonEmpty<A> {
    NonEmpty(head: head, tail: tail)
}

/// Attempt to construct a `NonEmpty` from a plain array.
/// Returns `nil` when the array is empty.
public func nonEmpty<A>(_ array: [A]) -> NonEmpty<A>? {
    guard let head = array.first else { return nil }
    return NonEmpty(head: head, tail: Array(array.dropFirst()))
}

// MARK: - Protocol conformances

extension NonEmpty: Equatable where A: Equatable {}
extension NonEmpty: Hashable where A: Hashable {}
extension NonEmpty: Sendable where A: Sendable {}
extension NonEmpty: Encodable where A: Encodable {}
extension NonEmpty: Decodable where A: Decodable {}

extension NonEmpty: Comparable where A: Comparable {
    public static func < (lhs: NonEmpty<A>, rhs: NonEmpty<A>) -> Bool {
        lhs.toArray.lexicographicallyPrecedes(rhs.toArray)
    }
}

extension NonEmpty: CustomStringConvertible {
    public var description: String {
        "NonEmpty(\(toArray))"
    }
}

extension NonEmpty: RawRepresentable {
    public var rawValue: [A] { toArray }

    public init?(rawValue: [A]) {
        guard let head = rawValue.first else { return nil }
        self.init(head: head, tail: Array(rawValue.dropFirst()))
    }
}
