// DeferredStreamTReader: outer = DeferredStream, inner = Reader
// Type: DeferredStream<Reader<Env, A>>
//
// Not implementable — Reader<Env, Output> does not conform to Sendable.
// See DeferredStreamTReader+Functor.swift for explanation.
