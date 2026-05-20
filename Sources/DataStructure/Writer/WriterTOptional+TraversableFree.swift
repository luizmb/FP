import CoreFP
import DataStructure

/// Sequence a Writer of an Optional into an Optional of Writer.
/// sequence :: Writer w b? -> Writer w b?
public func sequence<W: Monoid, B>(_ writer: Writer<W, B?>) -> Writer<W, B>? {
    writer.traverse(CoreFP.id)
}

/// Map and sequence over the value of a Writer, collecting into Optional.
/// traverse :: (a -> b?) -> Writer w a -> Writer w b?
public func traverse<W: Monoid, A, B>(_ fn: @escaping @Sendable (A) -> B?) -> (Writer<W, A>) -> Writer<W, B>? {
    { writer in writer.traverse(fn) }
}
