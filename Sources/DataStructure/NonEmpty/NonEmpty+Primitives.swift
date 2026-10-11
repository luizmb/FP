// SPDX-License-Identifier: Apache-2.0
public extension NonEmpty {
    // MARK: - Accessors

    /// The last element — always safe because at least one element exists.
    var last: A { tail.last ?? head }

    /// Total number of elements.
    var count: Int { tail.count + 1 }

    /// Convert to a plain `Array`.
    var toArray: [A] { [head] + tail }

    // MARK: - Structural operations

    /// Prepend an element, producing a new `NonEmpty` with `element` as the new head.
    func prepend(_ element: A) -> NonEmpty<A> {
        NonEmpty(head: element, tail: toArray)
    }

    /// Append a single element.
    ///
    /// `self` is `consuming`: when the caller hands the value over (a temporary, or
    /// `(consume list).append(x)`) the element is appended to the existing tail buffer
    /// instead of a copy of it.
    consuming func append(_ element: A) -> NonEmpty<A> {
        let first = head
        var rest = tail
        _ = consume self // end `self` here so `rest` is the tail buffer's only owner
        rest.append(element)
        return NonEmpty(head: first, tail: rest)
    }

    /// Append all elements of a plain array. In place on the tail buffer when the
    /// caller hands `self` over, as with ``append(_:)``.
    consuming func append(contentsOf elements: [A]) -> NonEmpty<A> {
        let first = head
        var rest = tail
        _ = consume self // end `self` here so `rest` is the tail buffer's only owner
        rest.append(contentsOf: elements)
        return NonEmpty(head: first, tail: rest)
    }

    /// Reverse the collection.
    var reversed: NonEmpty<A> {
        NonEmpty(head: last, tail: Array(toArray.dropLast().reversed()))
    }

    /// Safe index access — returns `nil` for out-of-bounds indices.
    subscript(safe index: Int) -> A? {
        let arr = toArray
        guard index >= 0, index < arr.count else { return nil }
        return arr[index]
    }
}

// MARK: - Free functions

/// Convert a `NonEmpty` to a plain `Array` — point-free friendly.
public func toArray<A>(_ ne: NonEmpty<A>) -> [A] {
    ne.toArray
}
