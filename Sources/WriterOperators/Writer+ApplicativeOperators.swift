import Foundation
import FP
import Writer
import Operators

// (<*>) :: Writer<w, (a -> b)> -> Writer<w, a> -> Writer<w, b>
public func <*> <W: Monoid, A, B>(
    _ wf: Writer<W, (A) -> B>,
    _ wa: Writer<W, A>
) -> Writer<W, B> {
    Writer<W, B>.apply(wf, wa)
}

// (*>) :: Writer<w, a> -> Writer<w, b> -> Writer<w, b>
public func *> <W: Monoid, A, B>(
    _ lhs: Writer<W, A>,
    _ rhs: Writer<W, B>
) -> Writer<W, B> {
    lhs.seqRight(rhs)
}

// (<*) :: Writer<w, a> -> Writer<w, b> -> Writer<w, a>
public func <* <W: Monoid, A, B>(
    _ lhs: Writer<W, A>,
    _ rhs: Writer<W, B>
) -> Writer<W, A> {
    lhs.seqLeft(rhs)
}
