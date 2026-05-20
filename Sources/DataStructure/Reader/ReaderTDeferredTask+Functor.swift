import CoreFP

// ReaderTDeferredTask: outer = Reader, inner = DeferredTask
// Type: Reader<Env, DeferredTask<A>>

public extension Reader {
    func mapT<A: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> Reader<Environment, DeferredTask<B>>
    where Output == DeferredTask<A> {
        mapReader { task in task.map(fn) }
    }

    static func fmapT<A: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Reader<Environment, DeferredTask<A>>) -> Reader<Environment, DeferredTask<B>>
    where Output == DeferredTask<A> {
        { $0.mapT(fn) }
    }
}
