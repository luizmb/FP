import CoreFP
import DataStructure

/// Sequence a Writer of a Result into a Result of Writer.
/// sequence :: Writer w (Result<b, e>) -> Result<Writer w b, e>
public func sequence<W: Monoid, B, E>(_ writer: Writer<W, Result<B, E>>) -> Result<Writer<W, B>, E> {
    writer.traverse(CoreFP.id)
}

/// Map and sequence over the value of a Writer, collecting into Result.
/// traverse :: (a -> Result<b, e>) -> Writer w a -> Result<Writer w b, e>
public func traverse<W: Monoid, A, B, E>(_ fn: @escaping @Sendable (A) -> Result<B, E>) -> (Writer<W, A>) -> Result<Writer<W, B>, E> {
    { writer in writer.traverse(fn) }
}
