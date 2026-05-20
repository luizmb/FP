import Foundation

public extension Stateful {
    static var get: Stateful<S, S> {
        Stateful<S, S> { s in s }
    }

    static func gets<B>(_ f: @escaping @Sendable (S) -> B) -> Stateful<S, B> {
        Stateful<S, B> { s in f(s) }
    }

    static func put(_ new: S) -> Stateful<S, Void> where S: Sendable {
        Stateful<S, Void> { s in s = new }
    }

    static func modify(_ f: @escaping @Sendable (S) -> S) -> Stateful<S, Void> {
        Stateful<S, Void> { s in s = f(s) }
    }

    static func modifyInPlace(_ f: @escaping @Sendable (inout S) -> Void) -> Stateful<S, Void> {
        Stateful<S, Void> { s in f(&s) }
    }

    static func pure(_ value: A) -> Stateful<S, A> where A: Sendable {
        Stateful<S, A> { _ in value }
    }
}
