// SPDX-License-Identifier: Apache-2.0

// MARK: - Zipper<A>

/// A focused, navigable non-empty sequence — the classic "list zipper".
///
/// `Zipper<A>` encodes a sequence together with a distinguished "cursor" position
/// (``focus``), plus O(1) navigation one step to either side. It is the canonical
/// functional data structure for walking back and forth over a sequence while editing
/// the element currently under focus — see Gérard Huet's 1997 paper "The Zipper", or
/// Haskell's `Data.List.Zipper`.
///
/// Internally, elements are split into three parts:
///
/// ```swift
/// public struct Zipper<A> {
///     public let left: [A]    // elements before the focus, CLOSEST-to-focus first
///     public let focus: A     // the element currently under focus
///     public let right: [A]   // elements after the focus, closest-to-focus first
/// }
/// ```
///
/// `left` is stored in reversed order (closest-to-focus first) so that ``moveLeft()``
/// and ``moveRight()`` are both O(1) — no reversal or re-indexing needed to step the
/// cursor.
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
/// let stepped = z.moveRight()       // focus == 2, left == [1]
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
    /// Elements before the focus, closest-to-focus first (i.e. in reversed order).
    public let left: [A]
    /// The element currently under focus.
    public let focus: A
    /// Elements after the focus, closest-to-focus first (natural order).
    public let right: [A]

    /// Initializer for `Zipper<A>`.
    public init(left: [A] = [], focus: A, right: [A] = []) {
        self.left = left
        self.focus = focus
        self.right = right
    }

    /// Attempt to construct a `Zipper` focused at the first element of `array`.
    /// Returns `nil` when `array` is empty.
    public init?(_ array: [A]) {
        guard let first = array.first else { return nil }

        left = []
        focus = first
        right = Array(array.dropFirst())
    }

    /// `true` when there are no elements to the left of the focus.
    public var isAtStart: Bool { left.isEmpty }

    /// `true` when there are no elements to the right of the focus.
    public var isAtEnd: Bool { right.isEmpty }

    /// Total number of elements held by the zipper.
    public var count: Int { left.count + 1 + right.count }
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
extension Zipper: Encodable where A: Encodable {}
extension Zipper: Decodable where A: Decodable {}

extension Zipper: CustomStringConvertible {
    public var description: String {
        "Zipper(left: \(left), focus: \(focus), right: \(right))"
    }
}
