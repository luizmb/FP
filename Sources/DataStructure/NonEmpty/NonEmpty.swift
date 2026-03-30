// MARK: - NonEmpty<A>

/// A sequence guaranteed to contain at least one element.
///
/// `NonEmpty<A>` is a `Semigroup` — two non-empty sequences always combine into a
/// non-empty sequence. It deliberately has **no `Monoid`** instance because there is
/// no empty value to serve as the identity element. Use `sconcat` (not `mconcat`)
/// when folding a collection of them.
///
/// ```swift
/// let digits  = NonEmpty(head: 1, tail: [2, 3])
/// let letters = NonEmpty(head: "a", tail: ["b"])
///
/// digits.head   // 1
/// digits.last   // 3
/// digits.count  // 3
/// digits.toArray  // [1, 2, 3]
/// ```
public struct NonEmpty<A> {
    public let head: A
    public let tail: [A]

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
