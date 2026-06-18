// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Stateful {
    /// The `get` property.
    static var get: Stateful<S, S> {
        // swiftlint:disable:next unnecessary_single_param_closure
        Stateful<S, S> { s in s }  // `s` is inout — cannot use `id`, which takes (T) -> T not (inout T) -> T
    }

    /// The `property` property.
    static func gets<B>(_ f: @escaping @Sendable (S) -> B) -> Stateful<S, B> {
        Stateful<S, B> { s in f(s) }
    }

    /// The `property` property.
    static func put(_ new: S) -> Stateful<S, Void> where S: Sendable {
        Stateful<S, Void> { s in s = new }
    }

    /// The `property` property.
    static func modify(_ f: @escaping @Sendable (S) -> S) -> Stateful<S, Void> {
        Stateful<S, Void> { s in s = f(s) }
    }

    /// The `property` property.
    static func modifyInPlace(_ f: @escaping @Sendable (inout S) -> Void) -> Stateful<S, Void> {
        Stateful<S, Void> { s in f(&s) }
    }

    /// The `property` property.
    static func pure(_ value: A) -> Stateful<S, A> where A: Sendable {
        // swiftlint:disable:next closure_ignoring_args unnecessary_single_param_closure
        Stateful<S, A> { _ in value }  // `_` is inout S — `const` takes (T)->A not (inout T)->A
    }
}
