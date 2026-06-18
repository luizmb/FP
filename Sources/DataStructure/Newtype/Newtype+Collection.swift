// SPDX-License-Identifier: Apache-2.0
// Sequence / Collection stack — every conformance delegates to RawValue.

// MARK: - Sequence

extension Newtype: Sequence where RawValue: Sequence {
    public typealias Element = RawValue.Element
    public typealias Iterator = RawValue.Iterator

    public func makeIterator() -> RawValue.Iterator {
        rawValue.makeIterator()
    }
}

// MARK: - Collection

extension Newtype: Collection where RawValue: Collection {
    public typealias Index = RawValue.Index
    public typealias Indices = RawValue.Indices
    public typealias SubSequence = RawValue.SubSequence

    public var startIndex: RawValue.Index { rawValue.startIndex }
    public var endIndex: RawValue.Index { rawValue.endIndex }
    public var indices: RawValue.Indices { rawValue.indices }

    public subscript(position: RawValue.Index) -> RawValue.Element {
        rawValue[position]
    }

    public subscript(bounds: Range<RawValue.Index>) -> RawValue.SubSequence {
        rawValue[bounds]
    }

    public func index(after i: RawValue.Index) -> RawValue.Index {
        rawValue.index(after: i)
    }
}

// MARK: - BidirectionalCollection

extension Newtype: BidirectionalCollection where RawValue: BidirectionalCollection {
    public func index(before i: RawValue.Index) -> RawValue.Index {
        rawValue.index(before: i)
    }
}

// MARK: - RandomAccessCollection

extension Newtype: RandomAccessCollection where RawValue: RandomAccessCollection {}

// MutableCollection cannot be supported. Its `subscript` requires both `get` and `set`
// witnesses, but the `Collection` conformance above must already provide a `subscript`
// whose witness is used for both protocols — and that witness can't have a setter when
// RawValue is only `Collection` (not `MutableCollection`). Two overlapping conditional
// subscripts don't help either: Swift picks the first one it finds as the witness and
// then rejects MutableCollection because it lacks a setter. Mutate via the `rawValue`
// property instead. (pointfree's `Tagged` has the same limitation.)

// MARK: - RangeReplaceableCollection

extension Newtype: RangeReplaceableCollection where RawValue: RangeReplaceableCollection {
    public init() {
        self.init(RawValue())
    }

    public mutating func replaceSubrange<C: Collection>(
        _ subrange: Range<RawValue.Index>,
        with newElements: C
    ) where C.Element == RawValue.Element {
        rawValue.replaceSubrange(subrange, with: newElements)
    }
}
