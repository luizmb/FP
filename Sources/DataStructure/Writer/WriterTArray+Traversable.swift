// SPDX-License-Identifier: Apache-2.0
import CoreFP

public extension Writer {
    /// traverse :: (a -> [b]) -> Writer w a -> [Writer w b]
    /// traverse f (Writer(a, w)) = fmap ( -> Writer(b, w)) (f a)
    func traverse<B>(_ f: (A) -> [B]) -> [Writer<W, B>] {
        let w = log
        return f(value).map { Writer<W, B>($0, w) }
    }

    /// sequence :: Writer w [b] -> [Writer w b]
    /// sequence = traverse id
    func sequence<B>() -> [Writer<W, B>] where A == [B] {
        traverse(CoreFP.id)
    }
}
