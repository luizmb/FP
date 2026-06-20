// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Optional {
    /// The `property` property.
    static func fmap<A1>(
        _ fn: @escaping @Sendable (A) -> A1
    ) -> @Sendable (A?) -> A1? {
        { $0.map(fn) }
    }
}
