import CoreFP
import CoreFPOperators
import DataStructure

// w ->> f  =  extend f w  (infixl 1)
public func ->> <W: Monoid, A, B>(
    _ w: Writer<W, A>,
    _ f: @escaping (Writer<W, A>) -> B
) -> Writer<W, B> {
    w.extend(f)
}

// f <<- w  =  extend f w  (infixr 1)
public func <<- <W: Monoid, A, B>(
    _ f: @escaping (Writer<W, A>) -> B,
    _ w: Writer<W, A>
) -> Writer<W, B> {
    w.extend(f)
}
