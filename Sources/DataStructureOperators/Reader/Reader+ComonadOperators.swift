import CoreFP
import CoreFPOperators
import DataStructure

// r ->> f  =  extend f r  (infixl 1, requires Env: Monoid)
public func ->> <Env: Monoid, A, B>(
    _ r: Reader<Env, A>,
    _ f: @escaping (Reader<Env, A>) -> B
) -> Reader<Env, B> {
    r.extend(f)
}

// f <<- r  =  extend f r  (infixr 1, requires Env: Monoid)
public func <<- <Env: Monoid, A, B>(
    _ f: @escaping (Reader<Env, A>) -> B,
    _ r: Reader<Env, A>
) -> Reader<Env, B> {
    r.extend(f)
}

// f <<= r  =  extend f r  (infixr 1, requires Env: Monoid)
public func <<= <Env: Monoid, A, B>(
    _ f: @escaping (Reader<Env, A>) -> B,
    _ r: Reader<Env, A>
) -> Reader<Env, B> {
    r.extend(f)
}
