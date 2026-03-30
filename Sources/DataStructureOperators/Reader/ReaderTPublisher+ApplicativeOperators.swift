import DataStructure
#if canImport(Combine)
import Combine
import Foundation
import CoreFPOperators

// ReaderT + Publisher

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func <*> <Env, A, B, E: Error>(
    _ readerF: Reader<Env, any Publisher<(A) -> B, E>>,
    _ readerA: Reader<Env, any Publisher<A, E>>
) -> Reader<Env, any Publisher<B, E>> {
    applyReaderPublisher(readerF, readerA)
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func *> <Env, A, B, E: Error>(
    _ lhs: Reader<Env, any Publisher<A, E>>,
    _ rhs: Reader<Env, any Publisher<B, E>>
) -> Reader<Env, any Publisher<B, E>> {
    seqRightReaderPublisher(lhs, rhs)
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func <* <Env, A, B, E: Error>(
    _ lhs: Reader<Env, any Publisher<A, E>>,
    _ rhs: Reader<Env, any Publisher<B, E>>
) -> Reader<Env, any Publisher<A, E>> {
    seqLeftReaderPublisher(lhs, rhs)
}

#endif
