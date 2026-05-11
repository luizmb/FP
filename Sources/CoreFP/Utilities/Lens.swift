public struct Lens<S, A>: @unchecked Sendable {
    public let get: (S) -> A
    public let set: (S, A) -> S
    public let modifyMut: (inout S, (inout A) -> Void) -> Void

    public init(get: @escaping (S) -> A, set: @escaping (S, A) -> S) {
        self.get = get
        self.set = set
        self.modifyMut = { s, f in
            var part = get(s)
            f(&part)
            s = set(s, part)
        }
    }

    public init(get: @escaping (S) -> A, set: @escaping (S, A) -> S,
                modifyMut: @escaping (inout S, (inout A) -> Void) -> Void) {
        self.get = get
        self.set = set
        self.modifyMut = modifyMut
    }

    public func callAsFunction(_ whole: S) -> A { get(whole) }

    public func over(_ transform: @escaping (A) -> A) -> (S) -> S {
        { s in set(s, transform(get(s))) }
    }

    public func lift(_ f: EndoMut<A>) -> EndoMut<S> {
        EndoMut { s in modifyMut(&s) { a in f(&a) } }
    }
}

extension Lens where S == A {
    public static var id: Lens<S, S> {
        Lens(get: { $0 }, set: { _, a in a }, modifyMut: { s, f in f(&s) })
    }
}

/// Lifts a `WritableKeyPath` into a `Lens`. Uses Swift's modify coroutine for zero-copy
/// in-place mutation via `lift(_:)`.
public func lens<S, A>(_ keyPath: WritableKeyPath<S, A>) -> Lens<S, A> {
    Lens(
        get: { $0[keyPath: keyPath] },
        set: { s, a in var c = s; c[keyPath: keyPath] = a; return c },
        modifyMut: { s, f in f(&s[keyPath: keyPath]) }
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
