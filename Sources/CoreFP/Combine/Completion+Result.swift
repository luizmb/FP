// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
import Combine
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Subscribers.Completion {
    /// Declaration.
    var result: Result<Void, Failure> {
        Result.from(self)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Result {
    /// Declaration.
    func completion() -> Subscribers.Completion<Failure> where Success == Void {
        Subscribers.Completion.from(self)
    }
}

#endif
