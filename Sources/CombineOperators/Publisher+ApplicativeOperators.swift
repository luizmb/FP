#if canImport(Combine)
import CombineFP
import Combine
import FP
import Foundation
import Operators

// (<*>) :: Either a (b0 -> b) -> Either a b0 -> Either a b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <*> <A0, A, B: Error>(_ lhs: any Publisher<(A0) -> A, B>, _ rhs: any Publisher<A0, B>)
-> any Publisher<A, B> {
    lhs
        .eraseToAnyPublisher()
        .zip(rhs.eraseToAnyPublisher())
        .map(call)
}

// (*>) :: Either a ignore -> Either a b -> Either a b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func *> <A, Ignore, B: Error>(_ lhs: any Publisher<Ignore, B>, _ rhs: any Publisher<A, B>)
-> any Publisher<A, B> {
    lhs
        .eraseToAnyPublisher()
        .zip(rhs.eraseToAnyPublisher())
        .map(\.1)
}

// (<*) :: Either a b -> Either a ignore -> Either a b
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func <* <A, B: Error, Ignore>(_ lhs: any Publisher<A, B>, _ rhs: any Publisher<Ignore, B>)
-> any Publisher<A, B> {
    rhs *> lhs
}


#endif
