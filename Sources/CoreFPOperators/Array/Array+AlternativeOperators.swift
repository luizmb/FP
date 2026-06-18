// SPDX-License-Identifier: Apache-2.0
import CoreFP

// MARK: - Alternative

/// (<|>) :: [a] -> [a] -> [a]
public func <|> <A>(_ lhs: [A], _ rhs: @autoclosure () -> [A]) -> [A] {
    Array.alt(lhs, rhs())
}

/// (++) :: [a] -> [a] -> [a]
public func ++ <A>(_ lhs: [A], _ rhs: [A]) -> [A] {
    lhs + rhs
}
