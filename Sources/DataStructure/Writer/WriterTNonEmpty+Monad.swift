import CoreFP

// WriterTNonEmpty: outer = Writer, inner = NonEmpty
// Type: Writer<W, NonEmpty<A>>

public extension Writer {
    /// flatMapT for Writer<W, NonEmpty<A>>.
    /// Each element maps to a Writer<W, NonEmpty<B>?>; logs are combined, NonEmpties concatenated.
    func flatMapT<Inner, B>(
        _ fn: (Inner) -> Writer<W, NonEmpty<B>?>
    ) -> Writer<W, NonEmpty<B>?> where A == NonEmpty<Inner> {
        let results = value.toArray.map(fn)
        let nonEmpties = results.compactMap(\.value)
        let combinedLog = results.reduce(log) { acc, wb in W.combine(acc, wb.log) }
        let combined: NonEmpty<B>? = nonEmpties.first.map { first in
            nonEmpties.dropFirst().reduce(first, NonEmpty.combine)
        }
        return Writer<W, NonEmpty<B>?>(combined, combinedLog)
    }

    static func bindT<Inner, B>(
        _ fn: @escaping (Inner) -> Writer<W, NonEmpty<B>?>
    ) -> (Writer<W, NonEmpty<Inner>>) -> Writer<W, NonEmpty<B>?>
    where A == NonEmpty<Inner> {
        { $0.flatMapT(fn) }
    }
}
