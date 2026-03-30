
// StatefulTNonEmpty: outer = Stateful, inner = NonEmpty
// Type: Stateful<S, NonEmpty<A>>

public extension Stateful {
    func mapT<Inner, B>(_ fn: @escaping (Inner) -> B) -> Stateful<S, NonEmpty<B>>
    where A == NonEmpty<Inner> {
        mapStateful { ne in ne.map(fn) }
    }

    static func fmapT<Inner, B>(
        _ fn: @escaping (Inner) -> B
    ) -> (Stateful<S, NonEmpty<Inner>>) -> Stateful<S, NonEmpty<B>>
    where A == NonEmpty<Inner> {
        { $0.mapT(fn) }
    }
}
