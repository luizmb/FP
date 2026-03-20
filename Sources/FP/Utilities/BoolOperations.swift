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
public func and(_ value: Bool) -> (Bool) -> Bool {
    { value && $0 }
}
public func or(_ value: Bool) -> (Bool) -> Bool {
    { value || $0 }
}
