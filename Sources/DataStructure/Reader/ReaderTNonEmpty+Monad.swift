import CoreFP

// ReaderTNonEmpty: outer = Reader, inner = NonEmpty
// Type: Reader<Environment, NonEmpty<A>>

public extension Reader {

    func flatMapT<Inner, B>(
        _ fn: @escaping (Inner) -> Reader<Environment, NonEmpty<B>?>
    ) -> Reader<Environment, NonEmpty<B>?> where Output == NonEmpty<Inner> {
        Reader<Environment, NonEmpty<B>?> { env in
            let results = self.runReader(env).toArray.map { fn($0).runReader(env) }
            let nonEmpties = results.compactMap { $0 }
            return nonEmpties.first.map { first in
                nonEmpties.dropFirst().reduce(first, NonEmpty.combine)
            }
        }
    }

    static func bindT<Inner, B>(
        _ fn: @escaping (Inner) -> Reader<Environment, NonEmpty<B>?>
    ) -> (Reader<Environment, NonEmpty<Inner>>) -> Reader<Environment, NonEmpty<B>?>
    where Output == NonEmpty<Inner> {
        { $0.flatMapT(fn) }
    }
}
