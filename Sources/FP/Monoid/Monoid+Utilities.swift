/// Reduces a non-empty sequence using the Semigroup operation.
/// sconcat :: Semigroup a => a -> [a] -> a
public func sconcat<S: Semigroup>(_ first: S, _ rest: [S]) -> S {
    rest.reduce(first, S.combine)
}

/// Reduces a sequence using the Monoid, returning the identity for empty input.
/// mconcat :: Monoid a => [a] -> a
public func mconcat<M: Monoid>(_ values: [M]) -> M {
    values.reduce(M.identity, M.combine)
}
