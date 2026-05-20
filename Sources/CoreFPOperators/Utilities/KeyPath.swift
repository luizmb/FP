import CoreFP

public extension WritableKeyPath where Root: Sendable, Value: Sendable {
    /// Lifts a `WritableKeyPath` into a `Lens<Root, Value>`.
    ///
    /// ```swift
    /// let ageLens: Lens<Person, Int> = ^\Person.age
    /// ```
    static prefix func ^ (keyPath: WritableKeyPath) -> Lens<Root, Value> {
        lens(keyPath)
    }
}

public extension KeyPath where Root: Sendable, Value: Sendable {
    /// Lifts a `KeyPath` into a partial `Lens` builder. Supply a setter to complete the lens.
    /// Use this for `let` properties where `WritableKeyPath` is unavailable.
    ///
    /// ```swift
    /// let nameLens: Lens<Person, String> = (^\Person.name) { Person(name: $1, age: $0.age) }
    /// ```
    static prefix func ^ (keyPath: KeyPath) -> (@escaping @Sendable (Root, Value) -> Root) -> Lens<Root, Value> {
        { setter in lens(keyPath, set: setter) }
    }

    /// Lifts a `KeyPath` into a `@Sendable` getter function.
    ///
    /// Swift's implicit `KeyPath → (Root) -> Value` conversion is not `@Sendable`, so passing
    /// `\User.name` directly into a `@Sendable`-typed position fails. `^` performs the lift
    /// explicitly, returning a `@Sendable` closure that captures the (Sendable) key path:
    ///
    /// ```swift
    /// let predicate = compose(^\User.name, equals("Alice"))
    /// let reducer   = userReducer.lift(state: ^\AppState.user)
    /// ```
    ///
    /// This overload coexists with the curried Lens-builder above; Swift picks based on the
    /// expected type at the call site. If both shapes are accepted in context (rare), give the
    /// binding an explicit `@Sendable (Root) -> Value` or `Lens<…>` annotation — or use the
    /// free function `get(_:)` from `CoreFP` for an unambiguous getter.
    static prefix func ^ (keyPath: KeyPath) -> @Sendable (Root) -> Value {
        get(keyPath)
    }
}
