// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Writer {
    /// WriterT + Reader — Writer<W, Reader<Env, A>>

    func mapT<Env, Inner, B>(_ fn: @escaping @Sendable (Inner) -> B) -> Writer<W, Reader<Env, B>>
    where A == Reader<Env, Inner> {
        mapWriter(Reader<Env, Inner>.fmap(fn))
    }

    /// The `property` property.
    static func fmapT<Env, Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> B
    ) -> @Sendable (Writer<W, Reader<Env, Inner>>) -> Writer<W, Reader<Env, B>>
    where A == Reader<Env, Inner> {
        { $0.mapT(fn) }
    }
}
