import CoreFP
import CoreFPOperators
import DataStructure

// ReaderTWriter: outer = Reader, inner = Writer
// Type: Reader<Env, Writer<W, A>>

// (<£^>) :: (a -> b) -> Reader<env, Writer<w, a>> -> Reader<env, Writer<w, b>>
public func <£^> <Env, W: Monoid, A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ reader: Reader<Env, Writer<W, A>>
) -> Reader<Env, Writer<W, B>> {
    reader.mapT(fn)
}

// (<&^>) :: Reader<env, Writer<w, a>> -> (a -> b) -> Reader<env, Writer<w, b>>
public func <&^> <Env, W: Monoid, A, B>(
    _ reader: Reader<Env, Writer<W, A>>,
    _ fn: @escaping @Sendable (A) -> B
) -> Reader<Env, Writer<W, B>> {
    reader.mapT(fn)
}
