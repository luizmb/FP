// SPDX-License-Identifier: Apache-2.0

// MARK: - Zipper<A>

/// A focused, navigable non-empty sequence — the classic "list zipper".
///
/// `Zipper<A>` encodes a sequence together with a distinguished "cursor" position
/// (``focus``), plus O(1) navigation one step to either side. It is the canonical
/// functional data structure for walking back and forth over a sequence with a cursor,
/// keeping every earlier position as a valid value — see Gérard Huet's 1997 paper "The Zipper", or
/// Haskell's `Data.List.Zipper`.
///
/// Internally a zipper is the whole sequence plus the index of the focus:
///
/// ```swift
/// public struct Zipper<A> {
///     public let elements: [A] // the full sequence, in order
///     public let focusedIndex: Int // always a valid index of `elements`
/// }
/// ```
///
/// Moving the focus never writes to `elements`: ``moveLeft()`` / ``moveRight()`` return a new
/// zipper that shares the same buffer with the index shifted by one, so they are O(1) and
/// every zipper derived from another (including the ones ``duplicate()`` builds) shares one
/// buffer. ``left`` and ``right`` are lazy views into that buffer, never copies.
///
/// The trade-off versus a linked-list zipper is editing: replacing or inserting at the focus
/// would write to the shared buffer and copy it (O(n)). Navigation and reading are O(1).
///
/// ## Creating a Zipper
///
/// ```swift
/// // Direct init, cursor placed explicitly:
/// let z = Zipper(left: [2, 1], focus: 3, right: [4, 5])   // sequence: 1, 2, 3, 4, 5
///
/// // From a plain array, cursor starts at the first element:
/// let fromArray = Zipper([1, 2, 3, 4, 5])   // focus == 1, nil if the array is empty
/// ```
///
/// ## Navigating
///
/// ```swift
/// let z = Zipper([1, 2, 3])         // focus == 1
/// let stepped = z.moveRight()       // focus == 2, Array(left) == [1]
/// stepped?.moveLeft()               // back to focus == 1
/// z.moveLeft()                      // nil — already at the start
/// ```
///
/// ## Functor / Comonad
///
/// `Zipper` is a `Functor` (mapping preserves cursor position) and a `Comonad`
/// (every position has a well-defined "context" you can `extract` or `extend` over):
///
/// ```swift
/// let doubled: Zipper<Int> = z.map { $0 * 2 }
///
/// // duplicate: every reachable position, each holding a zipper focused there.
/// let contexts: Zipper<Zipper<Int>> = z.duplicate()
/// contexts.extract.toArray() == z.toArray()   // true
/// ```
///
/// - SeeAlso: ``NonEmpty``
public struct Zipper<A> {
    /// The full sequence, in order. Never empty. Moving the focus never writes to it, so
    /// zippers derived from one another share this buffer.
    public let elements: [A]
    /// The position of ``focus`` in ``elements``. Always a valid index.
    public let focusedIndex: Int

    /// Unchecked memberwise init; callers guarantee `elements.indices.contains(focusedIndex)`.
    init(uncheckedElements elements: [A], focusedIndex: Int) {
        self.elements = elements
        self.focusedIndex = focusedIndex
    }

    /// Builds a zipper from the elements around the focus, each side closest-to-focus first:
    /// `Zipper(left: [2, 1], focus: 3, right: [4, 5])` is the sequence `1, 2, 3, 4, 5`
    /// focused on `3`. O(n): the sequence is assembled once.
    public init(left: [A] = [], focus: A, right: [A] = []) {
        var elements: [A] = []
        elements.reserveCapacity(left.count + 1 + right.count)
        elements.append(contentsOf: left.reversed())
        elements.append(focus)
        elements.append(contentsOf: right)
        self.init(uncheckedElements: elements, focusedIndex: left.count)
    }

    /// Attempt to construct a `Zipper` focused at the first element of `array`.
    /// Returns `nil` when `array` is empty. O(1): the array is shared, not copied.
    public init?(_ array: [A]) {
        self.init(array, focusedAt: 0)
    }

    /// Attempt to construct a `Zipper` over `elements` focused at `index`.
    /// Returns `nil` when `index` is not a valid index (which includes an empty array).
    /// O(1): the array is shared, not copied.
    public init?(_ elements: [A], focusedAt index: Int) {
        guard elements.indices.contains(index) else { return nil }
        self.init(uncheckedElements: elements, focusedIndex: index)
    }

    /// The element currently under focus. O(1).
    public var focus: A { elements[focusedIndex] }

    /// Elements before the focus, closest-to-focus first. A lazy, reversed view into
    /// ``elements``: O(1) to obtain, and nothing is copied unless you build an `Array` from it.
    public var left: ReversedCollection<ArraySlice<A>> { elements[..<focusedIndex].reversed() }

    /// Elements after the focus, closest-to-focus first (natural order). A slice of
    /// ``elements``: O(1) to obtain, and nothing is copied unless you build an `Array` from it.
    public var right: ArraySlice<A> { elements[(focusedIndex + 1)...] }

    /// `true` when there are no elements to the left of the focus.
    public var isAtStart: Bool { focusedIndex == 0 }

    /// `true` when there are no elements to the right of the focus.
    public var isAtEnd: Bool { focusedIndex == elements.count - 1 }

    /// Total number of elements held by the zipper.
    public var count: Int { elements.count }
}

// MARK: - Free constructors

/// Attempt to construct a `Zipper` from a plain array.
/// Returns `nil` when the array is empty.
public func zipper<A>(_ array: [A]) -> Zipper<A>? {
    Zipper(array)
}

// MARK: - Protocol conformances

extension Zipper: Equatable where A: Equatable {}
extension Zipper: Hashable where A: Hashable {}
extension Zipper: Sendable where A: Sendable {}

// Codable keeps the `left` / `focus` / `right` format (each side closest-to-focus first) that the
// array-triple representation used to synthesise, so persisted zippers still decode.
private enum ZipperCodingKeys: String, CodingKey {
    case left, focus, right
}

extension Zipper: Encodable where A: Encodable {
    // swiftlint:disable:next throws_instead_result
    public func encode(to encoder: any Encoder) throws { // Encodable protocol mandates throws
        var container = encoder.container(keyedBy: ZipperCodingKeys.self)
        try container.encode(Array(left), forKey: .left)
        try container.encode(focus, forKey: .focus)
        try container.encode(Array(right), forKey: .right)
    }
}

extension Zipper: Decodable where A: Decodable {
    public init(from decoder: any Decoder) throws { // Decodable protocol mandates throws
        let container = try decoder.container(keyedBy: ZipperCodingKeys.self)
        try self.init(
            left: container.decode([A].self, forKey: .left),
            focus: container.decode(A.self, forKey: .focus),
            right: container.decode([A].self, forKey: .right)
        )
    }
}

extension Zipper: CustomStringConvertible {
    public var description: String {
        "Zipper(left: \(Array(left)), focus: \(focus), right: \(Array(right)))"
    }
}
