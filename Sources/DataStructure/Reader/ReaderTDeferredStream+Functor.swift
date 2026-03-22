import CoreFP

public extension Reader {
    // ReaderTDeferredStream: outer = Reader, inner = DeferredStream
    // Type: Reader<Env, DeferredStream<A>>

    func mapT<A: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> Reader<Environment, DeferredStream<B>>
    where Output == DeferredStream<A> {
        mapReader { stream in stream.fmap(fn) }
    }

    static func fmapT<A: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> (Reader<Environment, DeferredStream<A>>) -> Reader<Environment, DeferredStream<B>>
    where Output == DeferredStream<A> {
        { $0.mapT(fn) }
    }
}
