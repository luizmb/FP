// SPDX-License-Identifier: Apache-2.0
import Foundation

/// `equals`.
public func equals<T>(_ lhs: T, _ rhs: T) -> Bool where T: Equatable {
    lhs == rhs
}

/// `equals`.
public func equals<T>(_ lhs: T?, _ rhs: T?) -> Bool where T: Equatable {
    lhs == rhs
}

/// `equals`.
public func equals<T>(_ value: T) -> @Sendable (T) -> Bool where T: Equatable & Sendable {
    curry(equals)(value)
}

/// `equals`.
public func equals<T>(_ value: T?) -> @Sendable (T?) -> Bool where T: Equatable & Sendable {
    curry(equals)(value)
}

/// `notEquals`.
public func notEquals<T>(_ lhs: T, _ rhs: T) -> Bool where T: Equatable {
    lhs != rhs
}

/// `notEquals`.
public func notEquals<T>(_ value: T) -> @Sendable (T) -> Bool where T: Equatable & Sendable {
    curry(notEquals)(value)
}

/// `not`.
public func not() -> @Sendable (Bool) -> Bool {
    { !$0 }
}

/// `not`.
public func not(_ value: Bool) -> Bool {
    !value
}

/// `not`.
public func not<A>(_ predicate: @escaping @Sendable (A) -> Bool) -> @Sendable (A) -> Bool {
    { !predicate($0) }
}

/// `and`.
public func and(_ value: Bool) -> @Sendable (Bool) -> Bool {
    { value && $0 }
}

/// `and`.
public func and<A>(_ p1: @escaping @Sendable (A) -> Bool, _ p2: @escaping @Sendable (A) -> Bool) -> @Sendable (A) -> Bool {
    { p1($0) && p2($0) }
}

/// `or`.
public func or(_ value: Bool) -> @Sendable (Bool) -> Bool {
    { value || $0 }
}

/// `or`.
public func or<A>(_ p1: @escaping @Sendable (A) -> Bool, _ p2: @escaping @Sendable (A) -> Bool) -> @Sendable (A) -> Bool {
    { p1($0) || p2($0) }
}
