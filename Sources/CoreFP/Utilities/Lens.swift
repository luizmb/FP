public struct Lens<S, A>: @unchecked Sendable {
    public let get: (S) -> A
    public let set: (S, A) -> S

    public init(get: @escaping (S) -> A, set: @escaping (S, A) -> S) {
        self.get = get
        self.set = set
    }

    public func callAsFunction(_ whole: S) -> A { get(whole) }

    public func over(_ transform: @escaping (A) -> A) -> (S) -> S {
        { s in set(s, transform(get(s))) }
    }
}

extension Lens where S == A {
    /// The identity `Lens`: get returns the whole unchanged, set replaces it entirely.
    public static var id: Lens<S, S> {
        Lens(get: { $0 }, set: { _, a in a })
    }
}

/// Lifts a `WritableKeyPath` into a `Lens`. The getter and setter are derived automatically.
public func lens<S, A>(_ keyPath: WritableKeyPath<S, A>) -> Lens<S, A> {
    Lens(
        get: { $0[keyPath: keyPath] },
        set: { s, a in
            var copy = s
            copy[keyPath: keyPath] = a
            return copy
        }
    )
}

/// Lifts a `KeyPath` into a `Lens` using a manually provided setter. Use this for `let`
/// properties or computed values where `WritableKeyPath` is unavailable.
///
/// ```swift
/// struct Person {
///     let name: String
///     let age: Int
/// }
///
/// let nameLens: Lens<Person, String> = lens(\.name) { Person(name: $1, age: $0.age) }
/// ```
public func lens<S, A>(_ keyPath: KeyPath<S, A>, set: @escaping (S, A) -> S) -> Lens<S, A> {
    Lens(get: { $0[keyPath: keyPath] }, set: set)
}
