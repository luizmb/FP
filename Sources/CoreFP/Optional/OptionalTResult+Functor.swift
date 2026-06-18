// SPDX-License-Identifier: Apache-2.0
import Foundation

// OptionalTResult: outer = Optional, inner = Result
// Type: Result<A,E>? = Optional<Result<A,E>>

public extension Optional {
    /// mapT for Optional<Result<A,E>> — maps over the inner Result's Success
    /// fmap :: (a -> b) -> Result<a,e>? -> Result<b,e>?
    func mapT<A, B, E: Error>(_ fn: @escaping @Sendable (A) -> B) -> Result<B, E>? where Wrapped == Result<A, E> {
        map { result in result.map(fn) }
    }

    /// Curried fmapT for Optional<Result<A,E>>
    static func fmapT<A, B, E: Error>(_ fn: @escaping @Sendable (A) -> B) -> @Sendable (Result<A, E>?) -> Result<B, E>? {
        { opt in opt.mapT(fn) }
    }
}
