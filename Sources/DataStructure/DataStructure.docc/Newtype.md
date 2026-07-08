# ``Newtype``

`Newtype<Tag, RawValue>` — a zero-cost wrapper that gives a raw value a distinct compile-time identity.

`Newtype` is this library's answer to *primitive obsession*: the habit of representing every ID, amount, or measurement as a bare `Int`, `String`, or `Double`. Bare primitives are interchangeable by construction — the compiler has no way to stop a `UserID` from being passed where an `OrderID` is expected, because as far as the type checker is concerned, both are just `Int`. `Newtype` fixes this by attaching a phantom `Tag` type parameter that exists only at compile time and costs nothing at runtime.

---

## The problem

```swift
struct User  { let id: Int; let name: String }
struct Order { let id: Int; let userID: Int }

func fetchUser(id: Int) -> User { … }

let order = Order(id: 501, userID: 42)
fetchUser(id: order.id)       // compiles — but this is the ORDER's id, not the user's!
```

Nothing here is a type error. `order.id` and `order.userID` are both plain `Int`, so the compiler cannot distinguish "an order identifier" from "a user identifier" — the mistake only surfaces at runtime, if it surfaces at all.

---

## The fix — a phantom-tagged wrapper

```swift
import DataStructure

enum UserTag {}
enum OrderTag {}
typealias UserID  = Newtype<UserTag,  Int>
typealias OrderID = Newtype<OrderTag, Int>

struct User  { let id: UserID;  let name: String }
struct Order { let id: OrderID; let userID: UserID }

func fetchUser(id: UserID) -> User { … }

let order = Order(id: OrderID(501), userID: UserID(42))
fetchUser(id: order.userID)   // ✅ — a UserID, exactly what fetchUser expects
fetchUser(id: order.id)       // ❌ compile error — OrderID is not UserID
```

`UserID` and `OrderID` both wrap `Int` and both behave like an `Int` at runtime (there is exactly one stored property, `rawValue`), but `Newtype<UserTag, Int>` and `Newtype<OrderTag, Int>` are different instantiations of the same generic type — Swift treats them as unrelated nominal types, so mixing them is a compile error, not a bug waiting to happen.

A common convention: skip the separate empty-enum tag and use the owning type itself:

```swift
struct User {
    let id: Newtype<User, Int>
    let name: String
}
```

### Property-wrapper form

`Newtype` is also declared `@propertyWrapper`, so a field can be branded while still reading and writing like its raw type:

```swift
struct Account {
    @Newtype<UserTag, Int> var id: Int = 42
}

let account = Account()
account.id     // Int                    — the unwrapped raw value, via `wrappedValue`
account.$id    // Newtype<UserTag, Int>  — the branded wrapper, via `projectedValue`
```

---

## Bridging to `Iso`

Every `Newtype` carries a static, total `Iso` to its raw value — `get` unwraps, `reverseGet` re-wraps, and neither direction can fail (unlike a general `RawRepresentable` iso, whose `init?(rawValue:)` may be failable for enums):

```swift
import CoreFP

UserID.iso.get(UserID(42))     // 42
UserID.iso.reverseGet(42)      // UserID(42)
```

Because it is a real `Iso`, it composes with the rest of the optics hierarchy via `>>>`/`<<<` exactly like any other optic — see [Optics](../../corefp/optics) for the full `Iso`/`Lens`/`Prism`/`AffineTraversal` composition story.

---

## Retroactive conformances — it behaves like `RawValue`

A `Newtype` is not just a box you have to keep unwrapping. Every conformance `RawValue` has, `Newtype` picks up conditionally, delegating straight through — so the wrapper is usable almost everywhere the raw type would be, without ever calling `.rawValue` by hand.

### Arithmetic (`Newtype+Numeric`)

When `RawValue` conforms to the corresponding numeric protocol, `Newtype` conforms too, and every native operator (`+`, `-`, `*`, `/`, `%`, `<<`, `>>`, `&`, `|`, `^`, unary `-`) delegates to `RawValue`'s implementation:

```swift
let a = UserID(10)
let b = UserID(32)
a + b            // UserID(42) — AdditiveArithmetic, delegates to Int's `+`
a < b            // true       — Comparable, delegates to Int's `<`
```

Because `FloatingPoint` itself requires `Magnitude == Self` — a constraint `Numeric`'s `Magnitude = RawValue.Magnitude` binding can't satisfy for signed integer raw values — `Newtype` cannot conform to `FloatingPoint` directly. It still recovers the operators you actually reach for (`/`, `squareRoot()`, `rounded(_:)`, `isNaN`, …) as plain extension members when `RawValue: FloatingPoint`:

```swift
typealias Meters = Newtype<DistanceTag, Double>
let distance = Meters(9.0)
distance.squareRoot()    // Meters(3.0)
```

### Collections (`Newtype+Collection`)

When `RawValue` is a `Sequence`/`Collection`/`BidirectionalCollection`/`RandomAccessCollection`/`RangeReplaceableCollection`, `Newtype` conforms too and iterates/indexes/subscripts straight through:

```swift
typealias Tags = Newtype<TagListTag, [String]>
let tags = Tags(["swift", "fp"])
tags.count           // 2 — via Collection
for tag in tags { … } // iterates the wrapped Array directly
```

(`MutableCollection` is the one exception — see the source comment in `Newtype+Collection.swift`: the `Collection` subscript witness Swift already committed to can't simultaneously satisfy a settable subscript. Mutate through `.rawValue` instead.)

### Literals (`Newtype+Literals`)

Every `ExpressibleBy*Literal` protocol is conditionally conformed, so a `Newtype` can be written as a literal exactly like its raw type — no explicit initializer call:

```swift
typealias Score = Newtype<ScoreTag, Int>
let s: Score = 42          // ExpressibleByIntegerLiteral — no `Score(42)` needed

typealias Label = Newtype<LabelTag, String>
let l: Label = "done"      // ExpressibleByStringLiteral
```

### Semigroup / Monoid (`Newtype+Semigroup`)

When `RawValue` is a `Semigroup`/`Monoid`, so is `Newtype`, and `<>` (from `CoreFPOperators`) works on the wrapper directly:

```swift
import CoreFPOperators

typealias Log = Newtype<LogTag, [String]>
Log(["a"]) <> Log(["b"])    // Log(["a", "b"]) — Array's Semigroup, through the wrapper
```

### Numeric monoid views (`Newtype+NumericMonoid`)

A bare numeric `Newtype` can't itself be *the* `Monoid` for its raw type, because a type like `Int` has two valid monoids — addition (identity `0`) and multiplication (identity `1`) — and a single conformance can only pick one. Instead, `.sum`/`.product` project the wrapped value into the disambiguated view:

```swift
typealias UserScore = Newtype<ScoreTag, Int>
mconcat([UserScore(2), UserScore(3)].map(\.sum)).rawValue        // 5
mconcat([UserScore(2), UserScore(3)].map(\.product)).rawValue    // 6
```

---

## Other always-on behaviour

`Equatable`, `Hashable`, `Sendable`, `Error`, `Encodable`/`Decodable` (as the bare raw value, not a keyed container), and `Identifiable` (using the wrapper itself as `id`) are all conditionally conformed the same way. `CustomStringConvertible`/`CustomDebugStringConvertible` are conformed **unconditionally**, printing the raw value's description — this sidesteps a Swift overload-resolution edge case where a conditional conformance here would make operator inference ambiguous inside monad-transformer expressions.

---

## For Haskell developers

This is the closest 1:1 mapping in the entire library. Haskell's `newtype` keyword:

```haskell
newtype UserID = UserID Int
```

declares a zero-cost wrapper with exactly this semantics — a distinct nominal type, erased at compile time, that shares its runtime representation with the wrapped value. Swift has no equivalent keyword, so `Newtype<Tag, RawValue>` is a generic struct that reconstructs the same guarantee: pick a `Tag` (Haskell's `UserID` name is doing double duty as both the wrapper and its own tag) and get a type the compiler will never silently conflate with another `Newtype` of the same raw representation. The retroactive conformances (`Numeric`, `Collection`, literals, `Semigroup`) are this library's stand-in for `GeneralizedNewtypeDeriving`, which lets a Haskell `newtype` inherit its underlying type's typeclass instances with `deriving newtype`.

For background on the underlying idea, see the Haskell Wiki's [Newtype](https://wiki.haskell.org/Newtype) page.

---

## Module

```swift
import DataStructure   // Newtype type + all retroactive conformances
import CoreFP           // Newtype.iso (bridge to Iso)
import CoreFPOperators   // <> for Newtype: Semigroup/Monoid
```
