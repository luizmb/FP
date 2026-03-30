import CoreFP
import DataStructure
import CoreFPOperators

// ReaderTWriter: outer = Reader, inner = Writer
// Type: Reader<Env, Writer<W, A>>

// (<£^>) :: (a -> b) -> Reader<env, Writer<w, a>> -> Reader<env, Writer<w, b>>
public func <£^> <Env, W: Monoid, A, B>(_ fn: @escaping (A) -> B, _ reader: Reader<Env, Writer<W, A>>) -> Reader<Env, Writer<W, B>> {
    reader.mapT(fn)
}

// (<&^>) :: Reader<env, Writer<w, a>> -> (a -> b) -> Reader<env, Writer<w, b>>
public func <&^> <Env, W: Monoid, A, B>(_ reader: Reader<Env, Writer<W, A>>, _ fn: @escaping (A) -> B) -> Reader<Env, Writer<W, B>> {
    reader.mapT(fn)
}
