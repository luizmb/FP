import CoreFP
import CoreFPOperators
import DataStructure

// (<*>) :: ZIO<env, (a -> b), e> -> ZIO<env, a, e> -> ZIO<env, b, e>
public func <*> <Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ fns: ZIO<Env, @Sendable (A) -> B, E>,
    _ values: ZIO<Env, A, E>
) -> ZIO<Env, B, E> {
    applyZIO(fns, values)
}

// (*>) :: ZIO<env, a, e> -> ZIO<env, b, e> -> ZIO<env, b, e>
public func *> <Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ lhs: ZIO<Env, A, E>,
    _ rhs: ZIO<Env, B, E>
) -> ZIO<Env, B, E> {
    lhs.seqRight(rhs)
}

// (<*) :: ZIO<env, a, e> -> ZIO<env, b, e> -> ZIO<env, a, e>
public func <* <Env: Sendable, A: Sendable, B: Sendable, E: Error & Sendable>(
    _ lhs: ZIO<Env, A, E>,
    _ rhs: ZIO<Env, B, E>
) -> ZIO<Env, A, E> {
    lhs.seqLeft(rhs)
}
