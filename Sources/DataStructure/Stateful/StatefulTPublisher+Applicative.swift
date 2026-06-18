// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
import Combine
import Foundation

// StatefulT + Publisher — free functions for Stateful<S, any Publisher<A, E>>

/// apply for Stateful<S, Publisher>
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func applyStatefulPublisher<S, A, B, E: Error>(
    _ sf: Stateful<S, any Publisher<(A) -> B, E>>,
    _ sa: Stateful<S, any Publisher<A, E>>
) -> Stateful<S, any Publisher<B, E>> {
    Stateful<S, any Publisher<B, E>> { s in
        let publisherF = sf.run(&s).eraseToAnyPublisher()
        let publisherA = sa.run(&s).eraseToAnyPublisher()
        return publisherF.zip(publisherA).map { fn, a in fn(a) }.eraseToAnyPublisher()
    }
}

/// liftA2 for Stateful<S, Publisher>
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func liftA2StatefulPublisher<S, A, B, C, E: Error>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Stateful<S, any Publisher<A, E>>, Stateful<S, any Publisher<B, E>>) -> Stateful<S, any Publisher<C, E>> {
    { sa, sb in
        Stateful<S, any Publisher<C, E>> { s in
            let publisherA = sa.run(&s).eraseToAnyPublisher()
            let publisherB = sb.run(&s).eraseToAnyPublisher()
            return publisherA.zip(publisherB).map(fn).eraseToAnyPublisher()
        }
    }
}

/// seqRight for Stateful<S, Publisher>
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func seqRightStatefulPublisher<S, A, B, E: Error>(
    _ lhs: Stateful<S, any Publisher<A, E>>,
    _ rhs: Stateful<S, any Publisher<B, E>>
) -> Stateful<S, any Publisher<B, E>> {
    Stateful<S, any Publisher<B, E>> { s in
        lhs.run(&s)
            .eraseToAnyPublisher()
            .zip(rhs.run(&s).eraseToAnyPublisher())
            .map(\.1)
            .eraseToAnyPublisher()
    }
}

/// seqLeft for Stateful<S, Publisher>
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public func seqLeftStatefulPublisher<S, A, B, E: Error>(
    _ lhs: Stateful<S, any Publisher<A, E>>,
    _ rhs: Stateful<S, any Publisher<B, E>>
) -> Stateful<S, any Publisher<A, E>> {
    Stateful<S, any Publisher<A, E>> { s in
        lhs.run(&s)
            .eraseToAnyPublisher()
            .zip(rhs.run(&s).eraseToAnyPublisher())
            .map(\.0)
            .eraseToAnyPublisher()
    }
}

#endif
