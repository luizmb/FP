import CoreFP

// ReaderTDeferredTask: outer = Reader, inner = DeferredTask
// Type: Reader<Env, DeferredTask<A>>

public extension Reader {
    func flatMapT<A: Sendable, B: Sendable>(
        _ fn: @escaping @Sendable (A) -> Reader<Environment, DeferredTask<B>>
    ) -> Reader<Environment, DeferredTask<B>>
    where Output == DeferredTask<A>, Environment: Sendable {
        Reader<Environment, DeferredTask<B>> { env in
            self.runReader(env).flatMap { a in fn(a).runReader(env) }
        }
    }
}

public func bindTReaderDeferredTask<Env: Sendable, A: Sendable, B: Sendable>(
    _ reader: Reader<Env, DeferredTask<A>>,
    _ fn: @escaping @Sendable (A) -> Reader<Env, DeferredTask<B>>
) -> Reader<Env, DeferredTask<B>> {
    reader.flatMapT(fn)
}
