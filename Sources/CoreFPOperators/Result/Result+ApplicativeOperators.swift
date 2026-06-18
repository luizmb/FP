// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

/// (<*>) :: Result<(a -> b), e> -> Result<a, e> -> Result<b, e>
public func <*> <A, A0, B>(_ lhs: Result<@Sendable (A0) -> A, B>, _ rhs: Result<A0, B>) -> Result<A, B> {
    Result<A, B>.apply(lhs, rhs)
}

/// (*>) :: Result<a, e> -> Result<b, e> -> Result<b, e>
public func *> <A, Ignore, B>(_ lhs: Result<Ignore, B>, _ rhs: Result<A, B>) -> Result<A, B> {
    lhs.seqRight(rhs)
}

/// (<*) :: Result<a, e> -> Result<b, e> -> Result<a, e>
public func <* <A, B, Ignore>(_ lhs: Result<A, B>, _ rhs: Result<Ignore, B>) -> Result<A, B> {
    lhs.seqLeft(rhs)
}
