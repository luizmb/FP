// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// z ->> f  =  extend f z  (infixl 1)
public func ->> <A, B>(
    _ z: Zipper<A>,
    _ f: @escaping @Sendable (Zipper<A>) -> B
) -> Zipper<B> {
    z.extend(f)
}

/// f <<- z  =  extend f z  (infixr 1)
public func <<- <A, B>(
    _ f: @escaping @Sendable (Zipper<A>) -> B,
    _ z: Zipper<A>
) -> Zipper<B> {
    z.extend(f)
}
