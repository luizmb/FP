// SPDX-License-Identifier: Apache-2.0
import CoreFPOperators
import DataStructure

/// (<*>) :: Loading<(a -> b), e> -> Loading<a, e> -> Loading<b, e>
public func <*> <A, S, F>(_ lhs: Loading<@Sendable (A) -> S, F>, _ rhs: Loading<A, F>) -> Loading<S, F> {
    Loading<S, F>.apply(lhs, rhs)
}

/// (*>) :: Loading<a, e> -> Loading<b, e> -> Loading<b, e>
public func *> <S, Ignore, F>(_ lhs: Loading<Ignore, F>, _ rhs: Loading<S, F>) -> Loading<S, F> {
    lhs.seqRight(rhs)
}

/// (<*) :: Loading<a, e> -> Loading<b, e> -> Loading<a, e>
public func <* <S, F, Ignore>(_ lhs: Loading<S, F>, _ rhs: Loading<Ignore, F>) -> Loading<S, F> {
    lhs.seqLeft(rhs)
}
