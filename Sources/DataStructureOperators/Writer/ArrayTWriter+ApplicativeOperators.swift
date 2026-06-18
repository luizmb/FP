// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// (<*>) :: [Writer<w, (a -> b)>] -> [Writer<w, a>] -> [Writer<w, b>]
public func <*> <W: Monoid, A, B>(_ fns: [Writer<W, @Sendable (A) -> B>], _ vals: [Writer<W, A>]) -> [Writer<W, B>] {
    applyArrayWriter(fns, vals)
}

/// (*>) :: [Writer<w, a>] -> [Writer<w, b>] -> [Writer<w, b>]
public func *> <W: Monoid, A, B>(_ lhs: [Writer<W, A>], _ rhs: [Writer<W, B>]) -> [Writer<W, B>] {
    seqRightArrayWriter(lhs, rhs)
}

/// (<*) :: [Writer<w, a>] -> [Writer<w, b>] -> [Writer<w, a>]
public func <* <W: Monoid, A, B>(_ lhs: [Writer<W, A>], _ rhs: [Writer<W, B>]) -> [Writer<W, A>] {
    seqLeftArrayWriter(lhs, rhs)
}
