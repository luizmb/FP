import Foundation

/// A strategy for copying a ``SumType2`` value in two distinct ways: in-parallel (same cases)
/// or via crossover (swapped cases).
///
/// `SumTypeCopyStrategy` is a helper type for contexts where a sum type value must be
/// duplicated and each copy may need to be "viewed" from a different case perspective.
/// The `parallel` path produces the same ``SumType2`` form; the `crossover` path produces an
/// inverted ``SumType2`` with swapped `A`/`B` type parameters.
///
/// The type constraint enforces that `ParallelSumType.A == InvertedSumType.B` and
/// `ParallelSumType.B == InvertedSumType.A`, ensuring the two directions are structurally
/// consistent inversions of each other.
///
/// - SeeAlso: ``SumType2``
public struct SumTypeCopyStrategy<ParallelSumType: SumType2, InvertedSumType: SumType2>
where ParallelSumType.A == InvertedSumType.B, ParallelSumType.B == InvertedSumType.A {
    public let parallel: () -> ParallelSumType
    public let crossover: () -> InvertedSumType

    public init(
        parallel: @escaping @Sendable () -> ParallelSumType,
        crossover: @escaping @Sendable () -> InvertedSumType
    ) {
        self.parallel = parallel
        self.crossover = crossover
    }

    public func callAsFunction() -> ParallelSumType {
        parallel()
    }
}
