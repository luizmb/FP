/// Reduces a non-empty sequence using the ``Semigroup`` operation.
///
/// ```swift
/// sconcat(1, [2, 3, 4])           // 10 (if Int were a Semigroup under +)
/// sconcat(Endo { $0 + 1 }, [Endo { $0 * 2 }])  // +1 then *2
/// ```
///
/// Unlike ``mconcat(_:)``, `sconcat` does not require a ``Monoid`` identity — it is
/// safe to use with ``Semigroup`` types that have no identity (such as ``NonEmpty``).
///
/// - Parameters:
///   - first: The initial element (ensures the result type is non-empty).
///   - rest: Additional elements to fold from left to right.
/// - Returns: The result of combining all elements left-to-right.
/// - SeeAlso: ``mconcat(_:)``, ``Semigroup``
public func sconcat<S: Semigroup>(_ first: S, _ rest: [S]) -> S {
    S.sconcat(first, rest)
}

/// Reduces a sequence using the ``Monoid``, returning ``Monoid/identity`` for empty input.
///
/// This is the standard `foldMap` / `fold` operation for monoids. It is safe to call
/// on an empty array — the result is ``Monoid/identity``.
///
/// ```swift
/// mconcat([1, 2, 3] as [NumericMonoid<Int>.Sum])      // Sum(6)
/// mconcat([] as [NumericMonoid<Int>.Sum])               // Sum(0)
/// mconcat([trim, lower, exclaim] as [Endo<String>])    // composed transform
/// ```
///
/// - Parameter values: The sequence of values to combine.
/// - Returns: The result of combining all values, or ``Monoid/identity`` if empty.
/// - SeeAlso: ``sconcat(_:_:)``, ``Monoid``
public func mconcat<M: Monoid>(_ values: [M]) -> M {
    M.mconcat(values)
}
