// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// WriterT + AsyncStream — Writer<W, AsyncStream<A>>
//
// flatMapT keeps the outer log and sequences the streams.
// Inner logs from fn are discarded — async element timing makes eager log
// accumulation across events impractical. Use Writer<W, [A]> when logs matter.

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Writer {
    /// Declaration.
    func flatMapT<Inner, B: AsyncSequence>(
        _ fn: @escaping @Sendable (Inner) async throws -> Writer<W, B>
    ) -> Writer<W, AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<AsyncStream<Inner>, B>, B>>
    where A == AsyncStream<Inner>, Inner: Sendable {
        Writer<W, AsyncThrowingFlatMapSequence<AsyncThrowingMapSequence<AsyncStream<Inner>, B>, B>>(
            value.bind { element in try await fn(element).value },
            log
        )
    }
}
