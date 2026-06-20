// SPDX-License-Identifier: Apache-2.0

// MARK: - WritableFocus<Value>

/// A two-way reference to a mutable value — a platform-neutral analogue of SwiftUI's `Binding`
/// that carries no UIKit/AppKit/SwiftUI dependency, so it works on Linux, Windows, and Android.
///
/// `WritableFocus` pairs a `get` with a `set` over some external storage (typically a reference
/// cell). It can be projected through an optic to focus on a sub-value, and supports `\.field`
/// navigation through struct fields via `@dynamicMemberLookup` — giving value-level `focus.a.b.c`
/// paths backed by live read/write.
///
/// ```swift
/// final class Box<A>: @unchecked Sendable { var value: A; init(_ v: A) { value = v } }
/// let box = Box(User(name: "Alice", address: Address(city: "Berlin")))
/// let focus = WritableFocus(get: { box.value }, set: { box.value = $0 })
///
/// focus.name.wrappedValue = "Bob"          // struct-field navigation, live write
/// focus[optic: cityLens].wrappedValue      // optic projection
/// ```
///
/// For projecting through a ``Prism`` or ``AffineTraversal`` (where the focus may be absent), the
/// subscripts return an optional `WritableFocus` — `nil` when the focus is currently absent.
///
/// - SeeAlso: ``Lens``, ``Iso``, ``Prism``, ``AffineTraversal``, ``PrismFocus``, ``AffineFocus``
@dynamicMemberLookup
public struct WritableFocus<Value>: Sendable {
    public let get: @Sendable () -> Value
    public let set: @Sendable (Value) -> Void

    public init(get: @escaping @Sendable () -> Value, set: @escaping @Sendable (Value) -> Void) {
        self.get = get
        self.set = set
    }

    /// The currently focused value. Reading calls `get`; writing calls `set`.
    public var wrappedValue: Value {
        get { get() }
        nonmutating set { set(newValue) }
    }

    /// Struct-field navigation: focuses a writable sub-field, reading and writing it live.
    public subscript<A: Sendable>(
        dynamicMember keyPath: WritableKeyPath<Value, A>
    ) -> WritableFocus<A> where Value: Sendable {
        WritableFocus<A>(
            get: { get()[keyPath: keyPath] },
            set: { a in var whole = get(); whole[keyPath: keyPath] = a; set(whole) }
        )
    }

    /// Projects through a ``Lens``. Always returns a valid focus — the whole is always present.
    public subscript<A>(optic optic: Lens<Value, A>) -> WritableFocus<A> {
        WritableFocus<A>(
            get: { optic.get(get()) },
            set: { set(optic.set(get(), $0)) }
        )
    }

    /// Projects through an ``Iso``. Always returns a valid focus — the bijection is total.
    public subscript<A>(optic optic: Iso<Value, A>) -> WritableFocus<A> {
        WritableFocus<A>(
            get: { optic.get(get()) },
            set: { set(optic.reverseGet($0)) }
        )
    }

    /// Projects through a ``Prism``. Returns `nil` when the focused case is currently inactive.
    ///
    /// The returned focus is safe across changes: if the underlying value moves to a different
    /// case while the focus is held, `get` falls back to the last known value.
    public subscript<A: Sendable>(optic optic: Prism<Value, A>) -> WritableFocus<A>? {
        guard let current = optic.preview(get()) else { return nil }
        return WritableFocus<A>(
            get: { optic.preview(get()) ?? current },
            set: { set(optic.review($0)) }
        )
    }

    /// Projects through an ``AffineTraversal``. Returns `nil` when the focus is currently absent.
    public subscript<A: Sendable>(optic optic: AffineTraversal<Value, A>) -> WritableFocus<A>? {
        guard let current = optic.preview(get()) else { return nil }
        return WritableFocus<A>(
            get: { optic.preview(get()) ?? current },
            set: { set(optic.set(get(), $0)) }
        )
    }
}
