// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

// WriterTNonEmpty: outer = Writer, inner = NonEmpty
// Type: Writer<W, NonEmpty<A>>

/// (<*>) :: Writer<W, NonEmpty<(A -> B)>> -> Writer<W, NonEmpty<A>> -> Writer<W, NonEmpty<B>>
public func <*> <W: Monoid, A, B>(
    _ wf: Writer<W, NonEmpty<@Sendable (A) -> B>>,
    _ wa: Writer<W, NonEmpty<A>>
) -> Writer<W, NonEmpty<B>> {
    applyWriterNonEmpty(wf, wa)
}

/// (*>) :: Writer<W, NonEmpty<A>> -> Writer<W, NonEmpty<B>> -> Writer<W, NonEmpty<B>>
public func *> <W: Monoid, A, B>(_ lhs: Writer<W, NonEmpty<A>>, _ rhs: Writer<W, NonEmpty<B>>) -> Writer<W, NonEmpty<B>> {
    seqRightWriterNonEmpty(lhs, rhs)
}

/// (<*) :: Writer<W, NonEmpty<A>> -> Writer<W, NonEmpty<B>> -> Writer<W, NonEmpty<A>>
public func <* <W: Monoid, A, B>(_ lhs: Writer<W, NonEmpty<A>>, _ rhs: Writer<W, NonEmpty<B>>) -> Writer<W, NonEmpty<A>> {
    seqLeftWriterNonEmpty(lhs, rhs)
}
