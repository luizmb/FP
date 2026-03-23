import DataStructure
import CoreFP
import CoreFPOperators

// ReaderTDeferredTask: outer = Reader, inner = DeferredTask
// Type: Reader<Env, DeferredTask<A>>

// (<£^>) :: (a -> b) -> Reader<env, DeferredTask<a>> -> Reader<env, DeferredTask<b>>
public func <£^> <Env, A: Sendable, B: Sendable>(_ fn: @escaping @Sendable (A) -> B, _ reader: Reader<Env, DeferredTask<A>>) -> Reader<Env, DeferredTask<B>> {
    reader.mapT(fn)
}

// (<&^>) :: Reader<env, DeferredTask<a>> -> (a -> b) -> Reader<env, DeferredTask<b>>
public func <&^> <Env, A: Sendable, B: Sendable>(_ reader: Reader<Env, DeferredTask<A>>, _ fn: @escaping @Sendable (A) -> B) -> Reader<Env, DeferredTask<B>> {
    reader.mapT(fn)
}
