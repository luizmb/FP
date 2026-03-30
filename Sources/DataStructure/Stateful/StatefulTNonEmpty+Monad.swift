// StatefulTNonEmpty: outer = Stateful, inner = NonEmpty
// Type: Stateful<S, NonEmpty<A>>

public extension Stateful {
    func flatMapT<Inner, B>(
        _ fn: @escaping (Inner) -> Stateful<S, NonEmpty<B>?>
    ) -> Stateful<S, NonEmpty<B>?> where A == NonEmpty<Inner> {
        Stateful<S, NonEmpty<B>?> { s in
            let results = self.run(&s).toArray.map { fn($0).run(&s) }
            let nonEmpties = results.compactMap { $0 }
            let combined: NonEmpty<B>? = nonEmpties.first.map { first in
                nonEmpties.dropFirst().reduce(first, NonEmpty.combine)
            }
            return combined
        }
    }

    static func bindT<Inner, B>(
        _ fn: @escaping (Inner) -> Stateful<S, NonEmpty<B>?>
    ) -> (Stateful<S, NonEmpty<Inner>>) -> Stateful<S, NonEmpty<B>?>
    where A == NonEmpty<Inner> {
        { $0.flatMapT(fn) }
    }
}
