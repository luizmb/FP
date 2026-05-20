import CoreFP
import Foundation

public extension Writer {
    // WriterT + Array — Writer<W, [A]>

    /// flatMapT :: Writer<w, [a]> -> (a -> Writer<w, [b]>) -> Writer<w, [b]>
    /// Maps fn over each element, flatMaps the results, and combines all inner logs with the outer log.
    func flatMapT<Inner, B>(_ fn: (Inner) -> Writer<W, [B]>) -> Writer<W, [B]> where A == [Inner] {
        let results = value.map(fn)
        let values = results.flatMap(\.value)
        let combinedLog = results.reduce(log) { acc, wb in W.combine(acc, wb.log) }
        return Writer<W, [B]>(values, combinedLog)
    }

    static func bindT<Inner, B>(
        _ fn: @escaping @Sendable (Inner) -> Writer<W, [B]>
    ) -> (Writer<W, [Inner]>) -> Writer<W, [B]> where A == [Inner] {
        { $0.flatMapT(fn) }
    }
}
