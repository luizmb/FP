#if canImport(SwiftUI)
import SwiftUI

public extension Binding {
    /// Access a sub-value through a `Lens`. Always returns a valid binding.
    ///
    /// ```swift
    /// struct User { var name: String }
    /// let nameLens: Lens<User, String> = lens(\.name)
    ///
    /// @State var user = User(name: "Alice")
    /// TextField("Name", text: $user[optic: nameLens])
    /// ```
    subscript<A>(optic optic: Lens<Value, A>) -> Binding<A> {
        Binding<A>(
            get: { optic.get(wrappedValue) },
            set: { wrappedValue = optic.set(wrappedValue, $0) }
        )
    }

    /// Access a transformed value through an `Iso`. Always returns a valid binding.
    ///
    /// The most common use case is transforming a binding's type — e.g. editing a
    /// `Double` through a `Binding<String>` backed by a text field.
    ///
    /// ```swift
    /// let metersToFeet = iso(get: { $0 * 3.28084 }, reverseGet: { $0 / 3.28084 })
    ///
    /// @State var meters: Double = 1.0
    /// // Editing in feet while storing in meters:
    /// TextField("Feet", value: $meters[optic: metersToFeet], format: .number)
    /// ```
    subscript<A>(optic optic: Iso<Value, A>) -> Binding<A> {
        Binding<A>(
            get: { optic.get(wrappedValue) },
            set: { wrappedValue = optic.reverseGet($0) }
        )
    }

    /// Access a sub-value through a `Prism`. Returns `nil` when the focused case is inactive.
    ///
    /// Use with `if let` or SwiftUI's `Binding.init?` to gate a view on the active case:
    ///
    /// ```swift
    /// enum Sheet { case settings(Settings); case profile(Profile) }
    /// let settingsPrism: Prism<Sheet, Settings> = ...
    ///
    /// @State var sheet: Sheet = .settings(Settings())
    /// if let settingsBinding = $sheet[optic: settingsPrism] {
    ///     SettingsView(settings: settingsBinding)
    /// }
    /// ```
    ///
    /// The returned `Binding<A>` is safe: if the underlying value changes to a different
    /// case while the binding is held, the getter falls back to the last known value until
    /// SwiftUI re-evaluates and discards the binding.
    subscript<A>(optic optic: Prism<Value, A>) -> Binding<A>? {
        guard let current = optic.preview(wrappedValue) else { return nil }
        return Binding<A>(
            get: { optic.preview(wrappedValue) ?? current },
            set: { wrappedValue = optic.review($0) }
        )
    }

    /// Access a sub-value through an `AffineTraversal`. Returns `nil` when the focus is absent.
    ///
    /// ```swift
    /// // loggedInPrism >>> ^\User.address >>> ^\Address.city
    /// let cityTraversal: AffineTraversal<App, String> = ...
    ///
    /// @State var app: App = .loggedIn(User(...))
    /// if let cityBinding = $app[optic: cityTraversal] {
    ///     TextField("City", text: cityBinding)
    /// }
    /// ```
    subscript<A>(optic optic: AffineTraversal<Value, A>) -> Binding<A>? {
        guard let current = optic.preview(wrappedValue) else { return nil }
        return Binding<A>(
            get: { optic.preview(wrappedValue) ?? current },
            set: { wrappedValue = optic.set(wrappedValue, $0) }
        )
    }
}
#endif
