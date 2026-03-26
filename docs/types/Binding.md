# Binding

SwiftUI's `Binding<Value>` is, semantically, a `Lens` with the root already captured: it holds a `get: () -> Value` and a `set: (Value) -> Void`. The library makes this relationship concrete by extending `Binding` with a single `subscript(optic:)` that accepts any of the four optic types — `Lens`, `Iso`, `Prism`, and `AffineTraversal`. Import `CoreFP` to get these subscripts.

```swift
import CoreFP
import SwiftUI
```

---

## The bridge: `[optic:]`

All four optic types are distinct concrete structs with no shared supertype, so Swift resolves the overload by the type of the argument alone. A single `optic:` label covers every case — no separate `lens:`, `prism:`, or `iso:` labels are needed.

| Subscript | Return type | When |
|---|---|---|
| `binding[optic: someLens]` | `Binding<A>` | Always — a Lens always has a focus |
| `binding[optic: someIso]` | `Binding<A>` | Always — an Iso is total in both directions |
| `binding[optic: somePrism]` | `Binding<A>?` | `nil` when the focused case is inactive |
| `binding[optic: someAffineTraversal]` | `Binding<A>?` | `nil` when the focus is absent |

---

## Lens — focusing on a struct field

A `Lens<S, A>` focuses on a single field of a struct. Use `lens(\_:)` to lift a `WritableKeyPath` into a `Lens`, then pass it to `[optic:]` to get a `Binding` directly into that field.

```swift
struct User {
    var name: String
    var age: Int
}

let nameLens: Lens<User, String> = lens(\.name)

struct ProfileView: View {
    @State var user = User(name: "Alice", age: 30)

    var body: some View {
        TextField("Name", text: $user[optic: nameLens])
    }
}
```

The resulting `Binding<String>` reads `user.name` and writes back a full `User` value — no manual copy-and-mutate needed.

---

## Iso — reversible type transformations

An `Iso<S, A>` is a total, lossless bijection. When bridged to a `Binding`, the getter runs `iso.get` and the setter runs `iso.reverseGet`. This makes it ideal for any situation where you store data in one representation but want to present it in another.

### Units conversion

```swift
let metersToFeet: Iso<Double, Double> = iso(
    get: { $0 * 3.28084 },
    reverseGet: { $0 / 3.28084 }
)

struct AltitudeView: View {
    @State var altitudeMeters: Double = 100.0

    var body: some View {
        // The text field shows and edits in feet; storage stays in meters.
        TextField("Altitude (ft)", value: $altitudeMeters[optic: metersToFeet], format: .number)
    }
}
```

### Reversible string conversion

```swift
let stringToInt: Iso<Int, String> = iso(
    get: { String($0) },
    reverseGet: { Int($0) ?? 0 }
)

@State var count: Int = 42
// Bind to a text field that works in String while the model stays Int:
TextField("Count", text: $count[optic: stringToInt])
```

---

## Prism — gating a sub-view on an active enum case

A `Prism<S, A>` focuses on one case of an enum. `preview` returns `nil` when the focused case is not active; `review` reconstructs the whole value from the focused part. The subscript returns `Binding<A>?` — use `if let` to gate the sub-view.

```swift
enum Sheet {
    case settings(Settings)
    case profile(Profile)
}

let settingsPrism: Prism<Sheet, Settings> = prism(
    preview: { if case .settings(let s) = $0 { s } else { nil } },
    review: Sheet.settings
)

struct ContentView: View {
    @State var sheet: Sheet = .settings(Settings())

    var body: some View {
        if let settingsBinding = $sheet[optic: settingsPrism] {
            SettingsView(settings: settingsBinding)
        }
    }
}
```

When `sheet` changes to `.profile(…)`, `settingsBinding` becomes `nil` and `SettingsView` is removed from the hierarchy by SwiftUI's normal re-evaluation.

---

## AffineTraversal — reaching inside a conditional focus

An `AffineTraversal<S, A>` combines the "whole always present" guarantee of a Lens with the "focus may be absent" character of a Prism. It is the natural result of composing a `Prism` with a `Lens` (or a `Lens` with a `Prism`). Like `Prism`, the subscript returns `Binding<A>?`.

```swift
enum AppState {
    case loggedOut
    case loggedIn(User)
}

struct User {
    var address: Address
}

struct Address {
    var city: String
}

// Compose a Prism (loggedIn case) with two Lenses (address, city)
let loggedInPrism: Prism<AppState, User> = prism(
    preview: { if case .loggedIn(let u) = $0 { u } else { nil } },
    review: AppState.loggedIn
)

let cityTraversal: AffineTraversal<AppState, String> =
    loggedInPrism >>> lens(\.address) >>> lens(\.city)

struct CityEditor: View {
    @State var app: AppState = .loggedIn(User(address: Address(city: "London")))

    var body: some View {
        if let cityBinding = $app[optic: cityTraversal] {
            TextField("City", text: cityBinding)
        }
    }
}
```

The `cityBinding` is only non-nil when the app is in the `.loggedIn` case. Editing the text field writes the new city string all the way back through the traversal to the root `AppState` value.

---

## Safety when the focus disappears

For `Prism` and `AffineTraversal`, the returned `Binding<A>` captures the last-known focus value as a fallback:

```swift
// Inside Binding+Optics.swift:
Binding<A>(
    get: { optic.preview(wrappedValue) ?? current },
    set: { wrappedValue = optic.set(wrappedValue, $0) }
)
```

If the underlying value changes to a case where the focus is absent while a `Binding<A>` is still held (e.g. a concurrent update arrives between SwiftUI re-evaluations), the getter returns `current` — the value that was present at the moment the binding was created. This prevents crashes without any force-unwrap. SwiftUI will remove the bound view on its next render pass once it re-evaluates the `if let`.

---

## Composing before bridging

Because optics compose with `>>>` and `<<<`, you can build arbitrarily deep traversals before passing the result to `[optic:]`. The final composed type determines which subscript overload fires.

```swift
// Lens >>> Lens → Lens (always succeeds)
let addressLens: Lens<User, Address> = lens(\.address)
let cityLens:    Lens<Address, String> = lens(\.city)
let userCityLens: Lens<User, String> = addressLens >>> cityLens

@State var user = User(address: Address(city: "Paris"))
TextField("City", text: $user[optic: userCityLens])

// Prism >>> Lens → AffineTraversal (may be nil)
let activeUserCity: AffineTraversal<AppState, String> =
    loggedInPrism >>> lens(\.address) >>> lens(\.city)

if let binding = $app[optic: activeUserCity] { ... }

// Iso >>> Lens → Lens (always succeeds, since Iso is total)
let metersToFeetLens: Lens<Double, Double> = metersToFeet.asLens
```

Compose with `<<<` when you want right-to-left ordering, which can read more naturally when building optics from the innermost field outward.

---

## Platform availability

`Binding+Optics` is conditionally compiled with `#if canImport(SwiftUI)`. On Linux or other platforms where SwiftUI is not available, the file compiles away entirely. The subscripts are only available on Apple platforms (iOS, macOS, tvOS, watchOS, visionOS) where SwiftUI can be imported.

```swift
import CoreFP   // Binding+Optics subscripts are included here
```
