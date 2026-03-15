import Foundation
import FP
import Reader

public extension Reader {
    // ReaderT + AsyncSequence
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func mapT<A, B>(_ fn: @escaping @Sendable (A) -> B) -> Reader<Environment, AsyncMapSequence<AsyncStream<A>, B>>
    where Output == AsyncStream<A> {
        mapReader { stream in
            stream.fmap(fn)
        }
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    static func fmap<A, B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> (Reader<Environment, AsyncStream<A>>) -> Reader<Environment, AsyncMapSequence<AsyncStream<A>, B>>
    where Output == AsyncStream<A> {
        { $0.mapT(fn) }
    }
}
