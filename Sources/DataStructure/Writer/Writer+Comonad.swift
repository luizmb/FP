// SPDX-License-Identifier: Apache-2.0
import CoreFP

public extension Writer {
    /// extract :: Writer w a -> a
    /// Returns the current value, discarding the log.
    var extract: A { value }

    /// extend :: (Writer w a -> b) -> Writer w a -> Writer w b
    /// Apply f to the whole writer context, preserving the original log.
    func extend<B>(_ f: (Writer<W, A>) -> B) -> Writer<W, B> {
        Writer<W, B>(f(self), log)
    }

    /// coflatMap is extend with flipped arguments (clearer name for Swift users).
    func coflatMap<B>(_ f: (Writer<W, A>) -> B) -> Writer<W, B> {
        extend(f)
    }

    /// duplicate :: Writer w a -> Writer w (Writer w a)
    /// Wraps the whole writer in an outer writer with the same log.
    /// Laws: extract . duplicate = id
    ///       fmap extract . duplicate = id
    var duplicate: Writer<W, Writer<W, A>> {
        Writer<W, Writer<W, A>>(self, log)
    }

    /// Curried static forms for point-free use.
    static func extend<B>(
        _ f: @escaping @Sendable (Writer<W, A>) -> B
    ) -> (Writer<W, A>) -> Writer<W, B> {
        { $0.extend(f) }
    }
}

/// extract :: Writer w a -> a
public func extract<W: Monoid, A>(_ writer: Writer<W, A>) -> A {
    writer.extract
}

/// extend :: (Writer w a -> b) -> Writer w a -> Writer w b
public func extend<W: Monoid, A, B>(
    _ f: @escaping @Sendable (Writer<W, A>) -> B
) -> (Writer<W, A>) -> Writer<W, B> {
    { $0.extend(f) }
}

/// duplicate :: Writer w a -> Writer w (Writer w a)
public func duplicate<W: Monoid, A>(_ writer: Writer<W, A>) -> Writer<W, Writer<W, A>> {
    writer.duplicate
}
