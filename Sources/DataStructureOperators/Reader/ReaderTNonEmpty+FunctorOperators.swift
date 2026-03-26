import DataStructure
import Foundation
import CoreFP
import CoreFPOperators

// ReaderTNonEmpty: outer = Reader, inner = NonEmpty
// Type: Reader<Environment, NonEmpty<A>>

// (<£^>) :: (A -> B) -> Reader<Env, NonEmpty<A>> -> Reader<Env, NonEmpty<B>>
public func <£^> <A, B, Env>(_ fn: @escaping (A) -> B, _ reader: Reader<Env, NonEmpty<A>>) -> Reader<Env, NonEmpty<B>> {
    reader.mapT(fn)
}

// (<&^>) :: Reader<Env, NonEmpty<A>> -> (A -> B) -> Reader<Env, NonEmpty<B>>
public func <&^> <A, B, Env>(_ reader: Reader<Env, NonEmpty<A>>, _ fn: @escaping (A) -> B) -> Reader<Env, NonEmpty<B>> {
    reader.mapT(fn)
}
