# IdentifiedArray

`IdentifiedArray<ID, Element>` is a `Sendable`, value-type (copy-on-write) ordered collection that keeps a **user-defined order exactly like `Array`** while offering **O(1)** lookup and in-place update by a stable identifier.

Order lives in the element buffer; a side index — a custom open-addressing hash table of `UInt32` offsets — maps `id → position` and never dictates order, so unsorted `UUID`s never reshuffle your data. Identifiers are unique: inserting an element whose id already exists replaces it in place (last-wins), keeping its position.

```swift
import DataStructure

struct User: Identifiable { let id: Int; var name: String }

// Construction — Identifiable elements
var users: IdentifiedArrayOf<User> = IdentifiedArray([
    User(id: 1, name: "Alice"),
    User(id: 2, name: "Bob"),
])

users[id: 1]?.name      // "Alice"  — O(1)
users.elements          // [User(1), User(2)] — ordered
users.ids               // [1, 2]
users.count             // 2
```

`IdentifiedArrayOf<E>` is a typealias for `IdentifiedArray<E.ID, E>` where `E: Identifiable`.

---

## Construction

```swift
// Identifiable — id derived from Element.id
let a = IdentifiedArray([User(id: 1, name: "Alice")])

// Non-Identifiable — supply the id via key path…
struct Project { let slug: String; var title: String }
let b = IdentifiedArray(loadedProjects, id: \.slug)

// …or a closure
let c = IdentifiedArray(loadedProjects, id: { $0.slug })

// Empty (Identifiable)
var d = IdentifiedArrayOf<User>()
```

Duplicate ids in the source are resolved last-wins: the first occurrence fixes the position, the last supplies the value.

---

## Lookup & mutation

```swift
var users = IdentifiedArray([User(id: 1, name: "Alice"), User(id: 2, name: "Bob")])

// Lookup — O(1)
users[id: 2]                 // Optional(User(id: 2, name: "Bob"))
users.contains(id: 2)        // true
users.position(id: 2)        // Optional(1)

// Update in place — O(1), keeps position
users[id: 2] = User(id: 2, name: "Robert")

// Append at the tail — O(1) amortised (or replace in place if id exists)
users.append(User(id: 3, name: "Carol"))

// Insert at a position — O(n) (order preserved → tail reindex)
users.insert(User(id: 0, name: "Zed"), at: 0)

// Remove — O(n)
users.remove(id: 1)
users.remove(at: 0)
```

The `[id:]` setter mirrors the collection `[id:]` subscript, including the id-mismatch no-op guard:

| `newValue`            | matching id exists | result            |
|-----------------------|:---:|---------------------------|
| `nil`                 | yes | remove                    |
| `nil`                 | no  | no-op                     |
| `v` where `v.id == id`| yes | replace in place          |
| `v` where `v.id == id`| no  | append to end             |
| `v` where `v.id != id`| —   | no-op (id-mismatch guard) |

---

## Collection conformance

`IdentifiedArray` is a `RandomAccessCollection` over its elements (integer-indexed, like `Array`):

```swift
let users = IdentifiedArray([User(id: 1, name: "Alice"), User(id: 2, name: "Bob")])

users[0]                 // User(id: 1, name: "Alice") — positional
users.first?.name        // "Alice"
users.map(\.id)          // [1, 2]
for user in users { … }  // iterates in order
```

It is also `Equatable` / `Hashable` (by element sequence) and `CustomStringConvertible`.

---

## Complexity

Versus a plain `[Element]` using `first(where:)` / `firstIndex(where:)`:

| Operation | `[Element]` | `IdentifiedArray` |
|---|---|---|
| lookup / update by id | O(n) | **O(1)** |
| append | O(1) | O(1) amortised |
| insert / remove at position | O(n) | O(n) (tail reindex) |
| ordered iteration | O(n) | O(n) |

The index is a hand-rolled open-addressing table (linear probing, power-of-two capacity, 0.75 load factor, backward-shift deletion) of `UInt32` offsets, plus a parallel cache of ids so probing and reindexing never call the `id` closure. Positional insert/remove reindex the shifted tail with a flat integer scan rather than rehashing every element.

---

## Optics

`IdentifiedArray` is a first-class optical citizen — every optic composes with `>>>` / `<<<` (import `DataStructureOperators` / `CoreFPOperators`).

```swift
// O(1) AffineTraversal focusing one element by id, zero-copy in-place mutation
IdentifiedArrayOf<User>.ix(id: 2).preview(users)?.name
IdentifiedArrayOf<User>.ix(id: 2) >>> ^\.name          // compose deeper

// AffineTraversal by position
IdentifiedArrayOf<User>.ix(0)

// Traversal over every element (or a predicate subset)
IdentifiedArrayOf<User>.traversed
IdentifiedArrayOf<User>.traversed(where: { $0.id.isMultiple(of: 2) })

// Iso / Prism to Array
IdentifiedArrayOf<User>.arrayIso                       // lawful Iso  <-> [Element]
IdentifiedArrayOf<User>.dedupPrism                     // Prism [Element] -> IdentifiedArray (iff ids unique)

// Lawful keyed iso — pairs the lookup with the order a bare dictionary would lose
IdentifiedArrayOf<User>.orderedDictionaryIso           // Iso <-> (ids: [ID], lookup: [ID: Element])
```

`ix(id:).lift` mutates the focused element in place without CoW-copying the buffer:

```swift
let bump = EndoMut<User> { $0.name = $0.name.uppercased() }
let mutate = IdentifiedArrayOf<User>.ix(id: 2).lift(bump)
mutate(&users)   // only the matched element is touched; the buffer is not copied
```

The `.dictionary` getter projects to `[ID: Element]` but is explicitly **lossy** — it drops order, so it is a getter, *not* an iso. Use `orderedDictionaryIso` when you need a lawful round-trip.

For non-`Identifiable` elements, `arrayIso(id:)`, `dedupPrism(id:)`, and `orderedDictionaryIso(id:)` take an explicit id closure.

---

## Algebra and the lawful surface

`IdentifiedArray` is a **`Semigroup`**: `<>` appends the right-hand elements into the left-hand one with last-wins on duplicate ids, keeping left-hand positions. This is associative.

```swift
let a = IdentifiedArray([User(id: 1, name: "Alice"), User(id: 2, name: "Bob")])
let b = IdentifiedArray([User(id: 2, name: "Bobby"), User(id: 3, name: "Carol")])
(a <> b).ids                 // [1, 2, 3]
(a <> b)[id: 2]?.name        // "Bobby"  — right value wins, left position kept
```

It deliberately has **no `Functor` / `Applicative` / `Monad` / `Monoid`**:

- A lawful (structure-preserving) `Functor` may not change the collection's count. An element-type-changing `map` that re-keys can collapse duplicate ids (last-wins), shrinking the count — so it is not a lawful functor. (Same reason `Set` is not a `Functor`.)
- `Applicative` / `Monad` would require free concatenation, producing duplicate ids the type forbids; collapsing to restore uniqueness breaks their laws.
- `Monoid` needs an empty `identity`, but `static var identity` cannot supply the `id` closure an arbitrary `Element` requires.

For value transforms that change the element type, bridge through `.elements` (the fully lawful `Array` functor/monad) and rebuild with `dedupPrism` (which surfaces id collisions) or `arrayIso` (last-wins normalise) — at a copy cost:

```swift
let renamed = IdentifiedArray(
    users.elements.map { User(id: $0.id, name: $0.name.uppercased()) }
)
```

In-place, same-identity edits stay on the type via `subscript(id:)`, `ix(id:)`, and `traversed`.

---

## See also

- [`NonEmpty`](NonEmpty.md) — the other constrained collection (Semigroup, no Monoid)
- Safe Collection Access (`[safe:]`, `[id:]`, `ix`) in the [README](../../README.md#safe-collection-access-safe-id-and-ix)
