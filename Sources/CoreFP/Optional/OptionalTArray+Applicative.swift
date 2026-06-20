// SPDX-License-Identifier: Apache-2.0
// swiftlint:disable discouraged_optional_collection
import Foundation

// OptionalTArray: outer = Optional, inner = Array
// Type: [A]? = Optional<[A]>

/// apply for OptionalTArray: [(A->B)]? -> [A]? -> [B]?
/// If outer is nil → nil; otherwise use Array.apply
public func applyOptionalArray<A, B>(_ fns: [@Sendable (A) -> B]?, _ values: [A]?) -> [B]? {
    fns.flatMap { fs in values.map { arr in Array.apply(fs, arr) } }
}

/// liftA2 for OptionalTArray: (A,B)->C -> [A]? -> [B]? -> [C]?
/// Double-lift through Optional then Array
public func liftA2OptionalArray<A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> ([A]?, [B]?) -> [C]? {
    { optA, optB in
        guard let a = optA, let b = optB else { return nil }
        return Array.liftA2(fn)(a, b)
    }
}

/// seqRight for OptionalTArray: [A]? -> [B]? -> [B]?
public func seqRightOptionalArray<A, B>(_ lhs: [A]?, _ rhs: [B]?) -> [B]? {
    lhs.seqRight(rhs)
}

/// seqLeft for OptionalTArray: [A]? -> [B]? -> [A]?
public func seqLeftOptionalArray<A, B>(_ lhs: [A]?, _ rhs: [B]?) -> [A]? {
    lhs.seqLeft(rhs)
}

// swiftlint:enable discouraged_optional_collection
