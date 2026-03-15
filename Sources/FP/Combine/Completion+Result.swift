#if canImport(Combine)
import Combine
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Subscribers.Completion {
    func result() -> Result<A, B> {
        Result.from(self)
    }
}

public extension Result {
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func result() -> Subscribers.Completion<Failure> where A == Void {
        Subscribers.Completion.from(self)
    }
}

#endif
