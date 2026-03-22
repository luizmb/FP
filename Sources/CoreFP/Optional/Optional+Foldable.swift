/// Allows for transforming a function which returns an optional type to a function which returns non-optional type
/// by passing a fallback of a given type.
///
/// For example:
/// ```
/// let f: (String) -> Character? = \.first
/// let f: (String) -> Character = \.first >>> alternative(nil) >>> alternative("X")
/// ```
/// When `f` function changes its type to return a non-optional, a default value has to be provided. This can be
/// achieved by using the `alternative` function and `>>>` operator:
public func alternative<A>(_ fallback: A?) -> (A?) -> A? {
    { optional in
        optional ?? fallback
    }
}

/// Allows for transforming a function which returns an optional type to a function which returns non-optional type
/// by passing a fallback of a given type.
///
/// For example:
/// ```
/// let f: (String) -> Character? = \.first
/// let f: (String) -> Character = \.first >>> alternative("X")
/// ```
/// When `f` function changes its type to return a non-optional, a default value has to be provided. This can be
/// achieved by using the `alternative` function and `>>>` operator:
public func alternative<A>(_ fallback: A) -> (A?) -> A {
    { optional in
        optional ?? fallback
    }
}

// Execute a closure if and only if the value can be unwrapped.
// Eg: myOptional.then { unwrappedValue in print(unwrappedValue) }
public extension Optional {
    @discardableResult func then(_ f: (Wrapped) -> Void, otherwise: () -> Void = ignore) -> Wrapped? {
        if let wrapped = self {
            f(wrapped)
            return .some(wrapped)
        }
        else {
            otherwise()
            return nil
        }
    }
}
