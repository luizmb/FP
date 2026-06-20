// SPDX-License-Identifier: Apache-2.0
import DataStructure
#if canImport(Combine)
    import Combine
    import CoreFPOperators
    import Foundation

    // ReaderT + Publisher

    /// `func`.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func <*> <Env, A, B, E: Error>(
        _ readerF: Reader<Env, any Publisher<(A) -> B, E>>,
        _ readerA: Reader<Env, any Publisher<A, E>>
    ) -> Reader<Env, any Publisher<B, E>> {
        applyReaderPublisher(readerF, readerA)
    }

    /// `*>` overload.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func *> <Env, A, B, E: Error>(
        _ lhs: Reader<Env, any Publisher<A, E>>,
        _ rhs: Reader<Env, any Publisher<B, E>>
    ) -> Reader<Env, any Publisher<B, E>> {
        seqRightReaderPublisher(lhs, rhs)
    }

    /// `func`.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public func <* <Env, A, B, E: Error>(
        _ lhs: Reader<Env, any Publisher<A, E>>,
        _ rhs: Reader<Env, any Publisher<B, E>>
    ) -> Reader<Env, any Publisher<A, E>> {
        seqLeftReaderPublisher(lhs, rhs)
    }

#endif
