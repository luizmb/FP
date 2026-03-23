import CoreFP

public extension Writer {
    // traverse :: (a -> Result<b, e>) -> Writer w a -> Result<Writer w b, e>
    // traverse f (Writer(a, w)) = fmap (\b -> Writer(b, w)) (f a)
    func traverse<B, E: Error>(_ f: (A) -> Result<B, E>) -> Result<Writer<W, B>, E> {
        let w = log
        return f(value).map { Writer<W, B>($0, w) }
    }

    // sequence :: Writer w (Result<b, e>) -> Result<Writer w b, e>
    // sequence = traverse id
    func sequence<B, E: Error>() -> Result<Writer<W, B>, E> where A == Result<B, E> {
        traverse(CoreFP.id)
    }
}
