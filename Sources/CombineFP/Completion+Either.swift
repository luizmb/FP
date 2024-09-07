#if canImport(Combine) && canImport(Either)
import Combine
import Either
import Foundation
import FP

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Either {
    func completion() -> Subscribers.Completion<A> where A: Error, B == Void {
        Subscribers.Completion.from(self.inverted())
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Subscribers.Completion {
    var either: SumTypeCopyStrategy<Either<A, B>, Either<B, A>> {
        .init(
            parallel: { Either.from(self) },
            crossover: { Either.from(self).inverted() }
        )
    }
}

#endif
