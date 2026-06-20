// SPDX-License-Identifier: Apache-2.0
import CoreFP

// MARK: - IdentifiedArray optics

//
// First-class optics over `IdentifiedArray`, composable with every other optic
// via `>>>` / `<<<`. The by-id affine traversal is the headline: O(1) focus and
// zero-copy in-place mutation, the indexed counterpart to the O(n)
// `Collection.ix(id:)`.
//
// The optic surfaces are `Sendable`-first (per the library contract): they take
// and return `@Sendable` closures and require `ID`/`Element` to be `Sendable`.

public extension IdentifiedArray where ID: Sendable, Element: Sendable {
    /// An ``AffineTraversal`` focusing the element with `id`. **O(1)** preview and
    /// in-place mutation.
    ///
    /// `tryModifyMut` mutates `&storage[i]` directly after an O(1) index lookup —
    /// zero-copy on the element buffer when the whole value is uniquely referenced.
    ///
    /// - Precondition: the mutation must not change the element's id; the id keys
    ///   the lookup table. Re-key with `remove(id:)` + `append` instead.
    ///
    /// ```swift
    /// IdentifiedArray.ix(id: 2).preview(items)?.name   // O(1)
    /// IdentifiedArray.ix(id: 2) >>> ^\Item.name        // composes with downstream optics
    /// ```
    static func ix(id key: ID) -> AffineTraversal<IdentifiedArray, Element> {
        AffineTraversal(
            preview: { @Sendable whole in whole.position(of: key).map { whole.storage[$0] } },
            set: { @Sendable whole, element in
                guard let i = whole.position(of: key), whole.id(element) == key else { return whole }
                var copy = whole
                copy.storage[i] = element
                return copy
            },
            tryModifyMut: { @Sendable whole, f in
                guard let i = whole.position(of: key) else { return }
                f(&whole.storage[i])
            }
        )
    }

    /// An ``AffineTraversal`` focusing the element at `position`. **O(1)**.
    ///
    /// Unlike ``ix(id:)``, replacing or mutating through a position may change the
    /// element's id; the lookup table for that single slot is patched accordingly
    /// (O(1)). Colliding with an id already present elsewhere is a precondition
    /// violation (ids must stay unique).
    static func ix(_ position: Int) -> AffineTraversal<IdentifiedArray, Element> {
        AffineTraversal(
            preview: { @Sendable whole in whole.storage.indices.contains(position) ? whole.storage[position] : nil },
            set: { @Sendable whole, element in
                guard whole.storage.indices.contains(position) else { return whole }
                var copy = whole
                let oldKey = copy.keys[position]
                copy.storage[position] = element
                copy.rekeyIfNeeded(at: position, previousKey: oldKey)
                return copy
            },
            tryModifyMut: { @Sendable whole, f in
                guard whole.storage.indices.contains(position) else { return }
                let oldKey = whole.keys[position]
                f(&whole.storage[position])
                whole.rekeyIfNeeded(at: position, previousKey: oldKey)
            }
        )
    }

    /// A ``Traversal`` over every element, in order. `modifyMut` mutates each
    /// element in place (zero-copy on the buffer when uniquely referenced), then
    /// rebuilds the lookup table — so mutations through this traversal MAY change
    /// ids (unlike ``ix(id:)``).
    static var traversed: Traversal<IdentifiedArray, Element> {
        Traversal(
            getAll: { @Sendable whole in whole.storage },
            modifyMut: { @Sendable whole, f in
                for i in whole.storage.indices {
                    f(&whole.storage[i])
                }
                whole.rebuildIndex()
            }
        )
    }

    /// A ``Traversal`` over every element satisfying `isIncluded`, in order.
    /// Rebuilds the lookup table after mutating, so ids may change.
    static func traversed(
        where isIncluded: @escaping @Sendable (Element) -> Bool
    ) -> Traversal<IdentifiedArray, Element> {
        Traversal(
            getAll: { @Sendable whole in whole.storage.filter(isIncluded) },
            modifyMut: { @Sendable whole, f in
                for i in whole.storage.indices where isIncluded(whole.storage[i]) {
                    f(&whole.storage[i])
                }
                whole.rebuildIndex()
            }
        )
    }
}

// MARK: - Iso / Prism to Array and Dictionary

public extension IdentifiedArray where ID: Sendable, Element: Sendable {
    /// A lawful ``Iso`` between `IdentifiedArray` and its ordered `[Element]`.
    ///
    /// `get` exposes the elements in order; `reverseGet` normalises an arbitrary
    /// array back into an `IdentifiedArray` (last-wins on duplicate ids). The iso
    /// laws hold on the `IdentifiedArray` side (round-trip from a well-formed value
    /// is the identity); building *from* an array with duplicate ids normalises.
    ///
    /// - SeeAlso: ``dedupPrism(id:)`` for the array→`IdentifiedArray` direction as a
    ///   lawful ``Prism`` that succeeds only on duplicate-free input.
    static func arrayIso(id: @escaping @Sendable (Element) -> ID) -> Iso<IdentifiedArray, [Element]> {
        Iso(
            get: { @Sendable whole in whole.storage },
            reverseGet: { @Sendable array in IdentifiedArray(array, id: id) }
        )
    }

    /// A ``Prism`` from `[Element]` into `IdentifiedArray` that succeeds only when
    /// every id is unique (`preview` returns `nil` on duplicates). `review` is the
    /// total `IdentifiedArray → [Element]` direction. Both prism laws hold.
    static func dedupPrism(id: @escaping @Sendable (Element) -> ID) -> Prism<[Element], IdentifiedArray> {
        Prism(
            preview: { @Sendable array in
                let identified = IdentifiedArray(array, id: id)
                return identified.count == array.count ? identified : nil
            },
            review: { @Sendable whole in whole.storage }
        )
    }

    /// A lawful ``Iso`` between `IdentifiedArray` and its *ordered* keyed form:
    /// `(ids, lookup)` where `ids` carries the order and `lookup` the payload.
    ///
    /// This is the honest dictionary iso — pairing the lookup table with the order
    /// it would otherwise lose. A plain `Iso` to `[ID: Element]` cannot be lawful
    /// because a bare dictionary has no order to round-trip. For the lossy, explicit
    /// projection use ``dictionary``.
    static func orderedDictionaryIso(
        id: @escaping @Sendable (Element) -> ID
    ) -> Iso<IdentifiedArray, (ids: [ID], lookup: [ID: Element])> {
        Iso(
            get: { @Sendable whole in (ids: whole.ids, lookup: whole.dictionary) },
            reverseGet: { @Sendable pair in
                var result = IdentifiedArray(id: id)
                for key in pair.ids {
                    if let element = pair.lookup[key] { result.append(element) }
                }
                return result
            }
        )
    }
}

// MARK: - Keyed projection (lossy)

public extension IdentifiedArray {
    /// A keyed projection of the elements. **Lossy: drops order** — this is a
    /// getter, NOT an iso. For a lawful keyed iso use ``orderedDictionaryIso(id:)``.
    var dictionary: [ID: Element] {
        var result = [ID: Element](minimumCapacity: storage.count)
        var i = 0
        while i < storage.count {
            result[keys[i]] = storage[i]
            i &+= 1
        }
        return result
    }
}

// MARK: - Identifiable conveniences

public extension IdentifiedArray where Element: Identifiable & Sendable, ID == Element.ID, ID: Sendable {
    /// `arrayIso` keyed by `Element.id`.
    static var arrayIso: Iso<IdentifiedArray, [Element]> { arrayIso(id: { $0.id }) }

    /// `dedupPrism` keyed by `Element.id`.
    static var dedupPrism: Prism<[Element], IdentifiedArray> { dedupPrism(id: { $0.id }) }

    /// `orderedDictionaryIso` keyed by `Element.id`.
    static var orderedDictionaryIso: Iso<IdentifiedArray, (ids: [ID], lookup: [ID: Element])> {
        orderedDictionaryIso(id: { $0.id })
    }
}
