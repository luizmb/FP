// SPDX-License-Identifier: Apache-2.0
import CoreFP
import CoreFPOperators
import DataStructure

/// ne ->> f  =  extend f ne  (infixl 1)
public func ->> <A, B>(
    _ ne: NonEmpty<A>,
    _ f: @escaping @Sendable (NonEmpty<A>) -> B
) -> NonEmpty<B> {
    ne.extend(f)
}

/// f <<- ne  =  extend f ne  (infixr 1)
public func <<- <A, B>(
    _ f: @escaping @Sendable (NonEmpty<A>) -> B,
    _ ne: NonEmpty<A>
) -> NonEmpty<B> {
    ne.extend(f)
}
