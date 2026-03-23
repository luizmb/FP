import CoreFP

public extension WritableKeyPath {
    /// Lifts a `WritableKeyPath` into a `Lens<Root, Value>`.
    ///
    /// ```swift
    /// let ageLens: Lens<Person, Int> = ^\Person.age
    /// ```
    static prefix func ^ (keyPath: WritableKeyPath) -> Lens<Root, Value> {
        lens(keyPath)
    }
}

public extension KeyPath {
    /// Lifts a `KeyPath` into a partial `Lens` builder. Supply a setter to complete the lens.
    /// Use this for `let` properties where `WritableKeyPath` is unavailable.
    ///
    /// ```swift
    /// let nameLens: Lens<Person, String> = (^\Person.name) { Person(name: $1, age: $0.age) }
    /// ```
    static prefix func ^ (keyPath: KeyPath) -> (@escaping (Root, Value) -> Root) -> Lens<Root, Value> {
        { setter in lens(keyPath, set: setter) }
    }
}
