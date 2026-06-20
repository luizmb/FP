// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

public extension Writer {
    /// pure :: a -> Writer w a — lift a value with an empty log
    static func pure(_ value: A) -> Writer<W, A> {
        Writer<W, A>(value, .identity)
    }

    /// tell :: w -> Writer w () — append to the log, produce no value
    static func tell(_ w: W) -> Writer<W, Void> {
        Writer<W, Void>((), w)
    }

    /// listen :: Writer w a -> Writer w (a, w) — expose the log alongside the value
    func listen() -> Writer<W, (A, W)> {
        Writer<W, (A, W)>((value, log), log)
    }

    /// censor :: (w -> w) -> Writer w a -> Writer w a — transform the log
    func censor(_ fn: (W) -> W) -> Writer<W, A> {
        Writer<W, A>(value, fn(log))
    }
}

/// pass :: Writer w (a, w -> w) -> Writer w a — apply a log transformation from within the computation
public func writerPass<W: Monoid, A>(_ writer: Writer<W, (A, (W) -> W)>) -> Writer<W, A> {
    let (a, f) = writer.value
    return Writer<W, A>(a, f(writer.log))
}
