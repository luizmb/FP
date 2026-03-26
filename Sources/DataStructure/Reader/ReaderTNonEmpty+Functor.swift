import CoreFP

// ReaderTNonEmpty: outer = Reader, inner = NonEmpty
// Type: Reader<Environment, NonEmpty<A>>

public extension Reader {

    func mapT<Inner, B>(_ fn: @escaping (Inner) -> B) -> Reader<Environment, NonEmpty<B>>
    where Output == NonEmpty<Inner> {
        mapReader { ne in ne.map(fn) }
    }

    static func fmapT<Inner, B>(
        _ fn: @escaping (Inner) -> B
    ) -> (Reader<Environment, NonEmpty<Inner>>) -> Reader<Environment, NonEmpty<B>>
    where Output == NonEmpty<Inner> {
        { $0.mapT(fn) }
    }
}
