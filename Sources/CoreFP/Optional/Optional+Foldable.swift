/// Allows for transforming a function which returns an optional type to a function which returns non-optional type
/// by passing a fallback of a given type.
///
/// For example:
/// ```
/// let f: (String) -> Character? = \.first
/// let f: (String) -> Character = \.first >>> withDefault(nil) >>> withDefault("X")
/// ```
/// When `f` function changes its type to return a non-optional, a default value has to be provided. This can be
/// achieved by using the `alternative` function and `>>>` operator:
public func withDefault<A: Sendable>(_ fallback: A?) -> @Sendable (A?) -> A? {
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
/// let f: (String) -> Character = \.first >>> withDefault("X")
/// ```
/// When `f` function changes its type to return a non-optional, a default value has to be provided. This can be
/// achieved by using the `alternative` function and `>>>` operator:
public func withDefault<A: Sendable>(_ fallback: A) -> @Sendable (A?) -> A {
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
        } else {
            otherwise()
            return nil
        }
    }

    /// Collapse an Optional to a single value.
    /// fold :: b -> (a -> b) -> Maybe a -> b
    func fold<B>(onNone: B, onSome: (Wrapped) -> B) -> B {
        map(onSome) ?? onNone
    }

    /// Curried fold for point-free use.
    static func fold<B: Sendable>(
        onNone: B,
        onSome: @escaping @Sendable (Wrapped) -> B
    ) -> @Sendable (Wrapped?) -> B {
        { $0.fold(onNone: onNone, onSome: onSome) }
    }

    /// Map to a Monoid, returning identity for nil.
    /// foldMap :: Monoid m => (a -> m) -> Maybe a -> m
    func foldMap<M: Monoid>(_ f: (Wrapped) -> M) -> M {
        map(f) ?? M.identity
    }

    /// Curried foldMap for point-free use.
    static func foldMap<M: Monoid>(
        _ f: @escaping @Sendable (Wrapped) -> M
    ) -> @Sendable (Wrapped?) -> M {
        { $0.foldMap(f) }
    }

    /// Extract value as a single-element list, or empty list for nil.
    /// toList :: Maybe a -> [a]
    var toList: [Wrapped] {
        map { [$0] } ?? []
    }
}
