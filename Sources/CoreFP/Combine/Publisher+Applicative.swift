// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import Foundation

    // The applicative is derived from the ordered-concat bind (`<*>` = `ap`), like Haskell's list
    // applicative: for each function, in order, map it over the whole argument stream.
    // `[f, g] <*> [1, 2]` emits `[f(1), f(2), g(1), g(2)]`. The argument stream is subscribed once
    // per function. For pairwise combination use `zip`.

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public extension Publisher {
        /// liftA2 f ma mb = ma >>= \a -> fmap (f a) mb
        /// liftA2 :: (a1 -> a2 -> a) -> Publisher<a1, e> -> Publisher<a2, e> -> Publisher<a, e>
        static func liftA2<A1, A2>(_ fn: @escaping @Sendable (A1, A2) -> A) -> @Sendable (
            any Publisher<A1, B>, any Publisher<A2, B>
        ) -> any Publisher<A, B> {
            { publisherA, publisherB in
                publisherA.eraseToAnyPublisher().concatMap { a1 in
                    publisherB.eraseToAnyPublisher().map { a2 in fn(a1, a2) }
                }
            }
        }

        /// mf <*> ma = mf >>= \f -> fmap f ma
        /// apply :: Publisher<(a -> b), e> -> Publisher<a, e> -> Publisher<b, e>
        static func apply<A0>(
            _ functions: any Publisher<@Sendable (A0) -> A, B>,
            _ values: any Publisher<A0, B>
        ) -> any Publisher<A, B> {
            functions.eraseToAnyPublisher().concatMap { fn in
                values.eraseToAnyPublisher().map(fn)
            }
        }

        /// ma *> mb = ma >>= \_ -> mb
        /// seqRight :: Publisher<a, e> -> Publisher<b, e> -> Publisher<b, e>
        static func seqRight<A0>(_ lhs: any Publisher<A0, B>, _ rhs: any Publisher<A, B>) -> any Publisher<A, B> {
            lhs.eraseToAnyPublisher().concatMap { (_: A0) in
                rhs.eraseToAnyPublisher()
            }
        }

        /// ma <* mb = ma >>= \a -> fmap (const a) mb
        /// seqLeft :: Publisher<a, e> -> Publisher<b, e> -> Publisher<a, e>
        static func seqLeft<A0>(_ lhs: any Publisher<A, B>, _ rhs: any Publisher<A0, B>) -> any Publisher<A, B> {
            lhs.eraseToAnyPublisher().concatMap { a in
                rhs.eraseToAnyPublisher().map { (_: A0) in a }
            }
        }

        /// Pairwise combination (like Haskell's `zip` for lists). Not the applicative: `<*>` is the
        /// bind-derived cartesian `ap`.
        /// zip :: Publisher<a1, e> -> Publisher<a2, e> -> Publisher<(a1, a2), e>
        static func zip<A1, A2>(_ lhs: any Publisher<A1, B>, _ rhs: any Publisher<A2, B>) -> any Publisher<A, B>
        where A == (A1, A2) {
            Publishers.Zip(lhs.eraseToAnyPublisher(), rhs.eraseToAnyPublisher())
        }
    }

#endif
