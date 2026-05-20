import Foundation

public func equals<T>(_ lhs: T, _ rhs: T) -> Bool where T: Equatable {
    lhs == rhs
}
public func equals<T>(_ lhs: T?, _ rhs: T?) -> Bool where T: Equatable {
    lhs == rhs
}
public func equals<T>(_ value: T) -> (T) -> Bool where T: Equatable {
    curry(equals)(value)
}
public func equals<T>(_ value: T?) -> (T?) -> Bool where T: Equatable {
     curry(equals)(value)
}
public func notEquals<T>(_ lhs: T, _ rhs: T) -> Bool where T: Equatable {
    lhs != rhs
}
public func notEquals<T>(_ value: T) -> (T) -> Bool where T: Equatable {
     curry(notEquals)(value)
}
public func not() -> (Bool) -> Bool {
    { !$0 }
}
public func not(_ value: Bool) -> Bool {
   !value
}
public func not<A>(_ predicate: @escaping @Sendable (A) -> Bool) -> (A) -> Bool {
    { !predicate($0) }
}
public func and(_ value: Bool) -> (Bool) -> Bool {
    { value && $0 }
}
public func and<A>(_ p1: @escaping @Sendable (A) -> Bool, _ p2: @escaping @Sendable (A) -> Bool) -> (A) -> Bool {
    { p1($0) && p2($0) }
}
public func or(_ value: Bool) -> (Bool) -> Bool {
    { value || $0 }
}
public func or<A>(_ p1: @escaping @Sendable (A) -> Bool, _ p2: @escaping @Sendable (A) -> Bool) -> (A) -> Bool {
    { p1($0) || p2($0) }
}
