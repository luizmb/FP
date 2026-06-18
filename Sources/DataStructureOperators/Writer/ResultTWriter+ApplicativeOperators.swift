// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<*>) :: Result<Writer<w, (a -> b)>, e> -> Result<Writer<w, a>, e> -> Result<Writer<w, b>, e>
public func <*> <W: Monoid, A, B, E: Error>(
    _ rf: Result<Writer<W, @Sendable (A) -> B>, E>,
    _ ra: Result<Writer<W, A>, E>
) -> Result<Writer<W, B>, E> {
    applyResultWriter(rf, ra)
}

/// (*>) :: Result<Writer<w, a>, e> -> Result<Writer<w, b>, e> -> Result<Writer<w, b>, e>
public func *> <W: Monoid, A, B, E: Error>(_ lhs: Result<Writer<W, A>, E>, _ rhs: Result<Writer<W, B>, E>) -> Result<Writer<W, B>, E> {
    seqRightResultWriter(lhs, rhs)
}

/// (<*) :: Result<Writer<w, a>, e> -> Result<Writer<w, b>, e> -> Result<Writer<w, a>, e>
public func <* <W: Monoid, A, B, E: Error>(_ lhs: Result<Writer<W, A>, E>, _ rhs: Result<Writer<W, B>, E>) -> Result<Writer<W, A>, E> {
    seqLeftResultWriter(lhs, rhs)
}
