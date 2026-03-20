import FP

// MARK: - Semigroup (<>)

/// Semigroup concatenation via the Semigroup protocol.
/// (<>) :: Semigroup a => a -> a -> a
public func <> <S: Semigroup>(_ lhs: S, _ rhs: S) -> S {
    S.combine(lhs, rhs)
}
