import CoreFP

/// bifoldMap :: (a -> c) -> (b -> c) -> Either a b -> c
/// Eliminate an Either by folding both sides to a common type.
/// Delegates to SumType2.bifoldMap(leftBy:rightBy:).
public func bifoldMap<A, B, C>(
    _ lf: @escaping (A) -> C,
    _ rf: @escaping (B) -> C
) -> (Either<A, B>) -> C {
    { $0.bifoldMap(leftBy: lf, rightBy: rf) }
}
