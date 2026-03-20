#if canImport(Combine)
import Combine
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Subscribers.Completion {
    var result: Result<Void, Failure> {
        Result.from(self)
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Result {
    func completion() -> Subscribers.Completion<Failure> where Success == Void {
        Subscribers.Completion.from(self)
    }
}

#endif
