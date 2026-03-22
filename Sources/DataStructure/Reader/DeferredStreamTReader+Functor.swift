// DeferredStreamTReader: outer = DeferredStream, inner = Reader
// Type: DeferredStream<Reader<Env, A>>
//
// Reader<Env, Output> does not conform to Sendable, so this stack cannot be used
// as a DeferredStream element type. Use ReaderTDeferredStream instead:
// Reader<Env, DeferredStream<A>> defers the stream and is fully implementable.
