// MARK: - IdentifiedArray<ID, Element>
//
// An ordered, value-type collection that keeps its elements in a user-defined
// order — exactly like `Array` — while offering O(1) lookup and in-place update
// by a stable identifier.
//
// ## Storage (Phase 2)
//
// Three parallel buffers:
//
//   - `storage: [Element]` — THE order. Append puts at the tail, `insert(_:at:)`
//     puts where you ask, `remove` shifts the tail. Iteration order is the
//     element order, identical to `Array`. The identifier never dictates order.
//   - `keys: [ID]` — parallel to `storage`: `keys[i] == id(storage[i])`. Caches
//     the identifiers so probing/reindexing never calls the `id` closure and
//     compares `ID`s directly.
//   - `buckets: [UInt32]` — a custom open-addressing hash table (linear probing,
//     power-of-two capacity, 0.75 load factor). Each slot holds either `empty`
//     (`UInt32.max`) or a *position* into `storage`. This replaces the Swift
//     `Dictionary` index used in Phase 1: cheaper inserts, lower-constant probes,
//     and — crucially — positional `insert`/`remove` reindex the tail with a flat
//     integer increment scan over `buckets` instead of rehashing every element.
//
// ## Invariant
//
// Identifiers are unique. Inserting an element whose id already exists replaces
// the existing element in place, keeping its position (last-wins). There is no
// way to represent two elements with the same id.
//
// ## Copy behaviour
//
//   - Lookup by id probes `buckets` then reads `storage` — never copies.
//   - In-place mutation through `ix(id:)` mutates `&storage[i]` directly; when
//     the value is uniquely referenced this is zero-copy on the element buffer.
//     Such a mutation must NOT change the element's id (the id keys the table).
//   - Copying an `IdentifiedArray` retains its CoW buffers — O(1), no element
//     copy. A full buffer copy happens only on a write while shared.

/// An ordered, `Sendable` value-type collection with O(1) lookup and in-place
/// update by a stable identifier, preserving a user-defined order like `Array`.
///
/// The identifier is supplied by a stored closure, so `Element` need not be
/// `Identifiable`: use the `id:` initialisers for a `KeyPath` or closure, or the
/// `Identifiable` convenience init / ``IdentifiedArrayOf`` typealias.
///
/// ```swift
/// struct User: Identifiable { let id: Int; var name: String }
///
/// var users: IdentifiedArrayOf<User> = [User(id: 1, name: "Alice"), User(id: 2, name: "Bob")]
/// users[id: 1]?.name            // "Alice"   (O(1))
/// users[id: 2] = User(id: 2, name: "Robert") // replace in place (O(1))
/// users.append(User(id: 3, name: "Carol"))   // tail (O(1))
/// ```
///
/// Lookup and in-place update are O(1); append is O(1) amortised; positional
/// `insert`/`remove` are O(n) because order is preserved and the tail reindexes.
///
/// - SeeAlso: ``IdentifiedArrayOf``
public struct IdentifiedArray<ID: Hashable, Element> {
    /// Element payload, in user-defined order.
    @usableFromInline
    var storage: [Element]

    /// Cached identifiers, parallel to `storage` (`keys[i] == id(storage[i])`).
    @usableFromInline
    var keys: [ID]

    /// Open-addressing table mapping an identifier's hash to a position in
    /// `storage`. `empty` slots hold ``IdentifiedArray/empty``.
    @usableFromInline
    var buckets: [UInt32]

    /// Sentinel marking an unused bucket. Caps element count at `UInt32.max - 1`.
    @usableFromInline
    static var empty: UInt32 { .max }

    /// Extracts the stable identifier from an element. Pure and total.
    public let id: @Sendable (Element) -> ID

    /// Creates an empty collection that derives identifiers via `id`.
    @inlinable
    public init(id: @escaping @Sendable (Element) -> ID) {
        self.storage = []
        self.keys = []
        self.buckets = []
        self.id = id
    }

    /// Creates a collection from `elements`, deriving identifiers via `id`.
    ///
    /// Elements are inserted in order with last-wins semantics: if two elements
    /// share an identifier, the earlier one fixes the position and the later one
    /// supplies the value.
    @inlinable
    public init<S: Sequence>(_ elements: S, id: @escaping @Sendable (Element) -> ID) where S.Element == Element {
        // Build into a local value, then assign `self`. Appending directly to `self`
        // inside this generic initializer defeats the optimizer's copy-on-write
        // uniqueness analysis — every `append` then copies the buffers (O(n) extra
        // allocations). A local `var` keeps the fast in-place path.
        var result = IdentifiedArray(id: id)
        result.reserveCapacity(elements.underestimatedCount)
        for element in elements { result.append(element) }
        self = result
    }
}

// MARK: - Identifiable conveniences

extension IdentifiedArray where Element: Identifiable & Sendable, ID == Element.ID, ID: Sendable {
    /// Creates an empty collection keyed by `Element.id`.
    @inlinable
    public init() {
        self.init(id: { $0.id })
    }

    /// Creates a collection from `elements`, keyed by `Element.id` (last-wins on duplicates).
    ///
    /// `@inlinable` so the construction loop specialises at the call site — without it,
    /// the generic build path can't keep its copy-on-write buffers unique and allocates
    /// O(n) extra buffers.
    @inlinable
    public init<S: Sequence>(_ elements: S) where S.Element == Element {
        self.init(elements, id: { $0.id })
    }
}

/// An ``IdentifiedArray`` keyed by an `Identifiable` element's own `id`.
public typealias IdentifiedArrayOf<Element: Identifiable> = IdentifiedArray<Element.ID, Element>

// MARK: - Open-addressing table (internal)

extension IdentifiedArray {
    /// Bucket slot for a key under the current `mask`. `hashValue` is folded into
    /// the low bits of the power-of-two table.
    @inlinable
    func hashSlot(_ key: ID, _ mask: Int) -> Int {
        Int(UInt(bitPattern: key.hashValue) & UInt(bitPattern: mask))
    }

    /// The bucket slot whose stored position resolves to `key`, or `nil` if absent.
    func bucketSlot(of key: ID) -> Int? {
        let capacity = buckets.count
        guard capacity > 0 else { return nil }
        let mask = capacity &- 1
        var slot = hashSlot(key, mask)
        while true {
            let value = buckets[slot]
            if value == Self.empty { return nil }
            if keys[Int(value)] == key { return slot }
            slot = (slot &+ 1) & mask
        }
    }

    /// The position in `storage` of the element with `key`, or `nil`. O(1).
    func position(of key: ID) -> Int? {
        bucketSlot(of: key).map { Int(buckets[$0]) }
    }

    /// Inserts `position` for `key` into the table. The caller guarantees spare
    /// capacity (via ``reserveTable(forCount:)``) and that `key` is absent.
    @inlinable
    mutating func tableInsert(_ key: ID, _ position: Int) {
        let mask = buckets.count &- 1
        var slot = hashSlot(key, mask)
        while buckets[slot] != Self.empty { slot = (slot &+ 1) & mask }
        buckets[slot] = UInt32(position)
    }

    /// Grows and rehashes the table if `count` would exceed the 0.75 load factor.
    @inlinable
    mutating func reserveTable(forCount count: Int) {
        let capacity = buckets.count
        guard capacity == 0 || count &* 4 > capacity &* 3 else { return }
        var newCapacity = capacity == 0 ? 16 : capacity
        while count &* 4 > newCapacity &* 3 { newCapacity &*= 2 }
        rebuildTable(capacity: newCapacity)
    }

    /// Rebuilds `buckets` at `capacity` (a power of two) from the current `keys`.
    ///
    /// The probe writes are random-access and dominate table growth, so they run
    /// through an unsafe buffer pointer to drop per-write bounds and CoW-uniqueness
    /// checks. `keys` is read through a local (CoW share) to avoid overlapping
    /// access to `self` while `self.buckets` is exclusively borrowed.
    @inlinable
    mutating func rebuildTable(capacity: Int) {
        buckets = [UInt32](repeating: Self.empty, count: capacity)
        guard capacity > 0 else { return }
        let mask = capacity &- 1
        let localKeys = keys
        localKeys.withUnsafeBufferPointer { keyBuffer in
            buckets.withUnsafeMutableBufferPointer { bucketBuffer in
                guard let keyBase = keyBuffer.baseAddress, let bucketBase = bucketBuffer.baseAddress else { return }
                var i = 0
                let count = keyBuffer.count
                while i < count {
                    var slot = Int(UInt(bitPattern: keyBase[i].hashValue) & UInt(bitPattern: mask))
                    while bucketBase[slot] != Self.empty { slot = (slot &+ 1) & mask }
                    bucketBase[slot] = UInt32(i)
                    i &+= 1
                }
            }
        }
    }

    /// Pre-sizes the element/key buffers and the table for at least `minimumCapacity`
    /// elements, so building a collection of known size avoids the incremental
    /// reallocation-and-rehash chain. O(minimumCapacity); no-op for non-positive input.
    @inlinable
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        guard minimumCapacity > 0 else { return }
        storage.reserveCapacity(minimumCapacity)
        keys.reserveCapacity(minimumCapacity)
        reserveTable(forCount: minimumCapacity)
    }

    /// Removes the entry at bucket `slot`, restoring the probe invariant via
    /// backward-shift deletion (no tombstones).
    mutating func tableRemoveSlot(_ slot: Int) {
        let mask = buckets.count &- 1
        var hole = slot
        var probe = slot
        buckets[hole] = Self.empty
        while true {
            probe = (probe &+ 1) & mask
            let value = buckets[probe]
            if value == Self.empty { break }
            let home = hashSlot(keys[Int(value)], mask)
            // Keep the entry where it is when its home lies cyclically in (hole, probe].
            let keep = hole <= probe ? (hole < home && home <= probe) : (hole < home || home <= probe)
            if keep { continue }
            buckets[hole] = value
            buckets[probe] = Self.empty
            hole = probe
        }
    }

    /// Shifts every stored position `>= threshold` by `delta` (used after a
    /// positional insert/remove moves the tail). A flat scan of `buckets`.
    mutating func shiftPositions(threshold: Int, by delta: Int) {
        buckets.withUnsafeMutableBufferPointer { bucketBuffer in
            guard let base = bucketBuffer.baseAddress else { return }
            let count = bucketBuffer.count
            var slot = 0
            while slot < count {
                let value = base[slot]
                if value != Self.empty && Int(value) >= threshold {
                    base[slot] = UInt32(Int(value) &+ delta)
                }
                slot &+= 1
            }
        }
    }

    /// Re-keys the element at `position` whose identifier changed from `oldKey`.
    /// No-op when the new identifier equals `oldKey`.
    mutating func rekeyIfNeeded(at position: Int, previousKey oldKey: ID) {
        let newKey = id(storage[position])
        guard newKey != oldKey else { return }
        if let slot = bucketSlot(of: oldKey) { tableRemoveSlot(slot) }
        keys[position] = newKey
        tableInsert(newKey, position)
    }

    /// Recomputes `keys` from `storage` and rebuilds the table. O(n). Used after
    /// bulk mutations (e.g. `traversed`) that may have changed identifiers.
    mutating func rebuildIndex() {
        var i = 0
        while i < storage.count {
            keys[i] = id(storage[i])
            i &+= 1
        }
        rebuildTable(capacity: buckets.isEmpty ? 0 : buckets.count)
    }
}

// MARK: - Lookup & mutation

extension IdentifiedArray {
    /// The elements in their user-defined order. O(1); shares the backing buffer.
    public var elements: [Element] { storage }

    /// The identifiers in element order. O(1); shares the backing buffer.
    public var ids: [ID] { keys }

    /// Whether an element with `id` is present. O(1).
    public func contains(id key: ID) -> Bool { position(of: key) != nil }

    /// The position of the element with `id`, or `nil`. O(1).
    public func position(id key: ID) -> Int? { position(of: key) }

    /// Get-or-set an element by its identifier, with `Dictionary`-like semantics.
    ///
    /// Getter: the element whose id equals `id`, or `nil`. O(1).
    ///
    /// Setter (mirrors the existing `Collection[id:]` setter):
    ///
    /// | `newValue`         | matching id exists | behaviour          |
    /// |--------------------|:---:|--------------------|
    /// | `nil`              | yes | remove the element |
    /// | `nil`              | no  | no-op              |
    /// | `v` (`v.id == id`) | yes | replace in place   |
    /// | `v` (`v.id == id`) | no  | append to end      |
    /// | `v` (`v.id != id`) | —   | no-op (id mismatch)|
    public subscript(id key: ID) -> Element? {
        get { position(of: key).map { storage[$0] } }
        set {
            switch (newValue, position(of: key)) {
            case let (element?, position?):
                guard id(element) == key else { return }
                storage[position] = element
            case let (element?, nil):
                guard id(element) == key else { return }
                append(element)
            case let (nil, position?):
                remove(at: position)
            case (nil, nil):
                return
            }
        }
    }

    /// Appends `element` at the tail, or — if an element with the same id already
    /// exists — replaces it in place keeping its position (last-wins). O(1) amortised.
    ///
    /// Single-probe find-or-insert: because backward-shift deletion leaves no
    /// tombstones, the first `empty` slot in the probe chain is exactly where a new
    /// key belongs, so one walk handles both the replace and the append case.
    @inlinable
    public mutating func append(_ element: Element) {
        let key = id(element)
        reserveTable(forCount: storage.count &+ 1)
        let mask = buckets.count &- 1
        var slot = hashSlot(key, mask)
        while true {
            let value = buckets[slot]
            if value == Self.empty {
                buckets[slot] = UInt32(storage.count)
                keys.append(key)
                storage.append(element)
                return
            }
            if keys[Int(value)] == key {
                storage[Int(value)] = element
                return
            }
            slot = (slot &+ 1) & mask
        }
    }

    /// Inserts `element` at `position`, shifting later elements toward the tail.
    /// If an element with the same id already exists, replaces it in place instead
    /// (the `position` argument is ignored in that case). O(n).
    public mutating func insert(_ element: Element, at position: Int) {
        let key = id(element)
        if let slot = bucketSlot(of: key) {
            storage[Int(buckets[slot])] = element
            return
        }
        reserveTable(forCount: storage.count &+ 1)
        shiftPositions(threshold: position, by: 1)
        tableInsert(key, position)
        keys.insert(key, at: position)
        storage.insert(element, at: position)
    }

    /// Removes and returns the element at `position`, shifting later elements down. O(n).
    @discardableResult
    public mutating func remove(at position: Int) -> Element {
        let removed = storage[position]
        if let slot = bucketSlot(of: keys[position]) { tableRemoveSlot(slot) }
        storage.remove(at: position)
        keys.remove(at: position)
        shiftPositions(threshold: position &+ 1, by: -1)
        return removed
    }

    /// Removes and returns the element with `id`, or `nil` if absent. O(n).
    @discardableResult
    public mutating func remove(id key: ID) -> Element? {
        guard let position = position(of: key) else { return nil }
        return remove(at: position)
    }
}

// MARK: - Protocol conformances

extension IdentifiedArray: Sendable where ID: Sendable, Element: Sendable {}

extension IdentifiedArray: Equatable where Element: Equatable {
    public static func == (lhs: IdentifiedArray, rhs: IdentifiedArray) -> Bool {
        lhs.storage == rhs.storage
    }
}

extension IdentifiedArray: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
    }
}

extension IdentifiedArray: CustomStringConvertible {
    public var description: String {
        "IdentifiedArray(\(storage))"
    }
}
