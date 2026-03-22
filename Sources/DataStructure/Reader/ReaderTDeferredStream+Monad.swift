import CoreFP

// ReaderTDeferredStream: outer = Reader, inner = DeferredStream
// Type: Reader<Env, DeferredStream<A>>

public extension Reader {
    func flatMapT<A: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (A) -> Reader<Environment, DeferredStream<B>>
    ) -> Reader<Environment, DeferredStream<B>>
    where Output == DeferredStream<A>, Environment: Sendable {
        Reader<Environment, DeferredStream<B>> { env in
            self.runReader(env).flatMap { a in fn(a).runReader(env) }
        }
    }
}

public func bindTReaderDeferredStream<Env: Sendable, A: Sendable, B: Sendable>(
    _ reader: Reader<Env, DeferredStream<A>>,
    _ fn: @escaping @Sendable (A) -> Reader<Env, DeferredStream<B>>
) -> Reader<Env, DeferredStream<B>> {
    reader.flatMapT(fn)
}
