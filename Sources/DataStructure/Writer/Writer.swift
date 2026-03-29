import CoreFP
import Foundation

public struct Writer<W: Monoid, A> {
    public let value: A
    public let log: W

    public init(_ value: A, _ log: W) {
        self.value = value
        self.log = log
    }

    public func runWriter() -> (A, W) { (value, log) }
    public func evalWriter() -> A { value }
    public func execWriter() -> W { log }
}

extension Writer: Equatable where W: Equatable, A: Equatable {}
extension Writer: Hashable where W: Hashable, A: Hashable {}
extension Writer: Sendable where W: Sendable, A: Sendable {}
