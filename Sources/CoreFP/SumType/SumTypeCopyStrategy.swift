import Foundation

public struct SumTypeCopyStrategy<ParallelSumType: SumType2, InvertedSumType: SumType2>
where ParallelSumType.A == InvertedSumType.B, ParallelSumType.B == InvertedSumType.A {
    public let parallel: () -> ParallelSumType
    public let crossover: () -> InvertedSumType

    public init(
        parallel: @escaping () -> ParallelSumType,
        crossover: @escaping () -> InvertedSumType
    ) {
        self.parallel = parallel
        self.crossover = crossover
    }

    public func callAsFunction() -> ParallelSumType {
        parallel()
    }
}
