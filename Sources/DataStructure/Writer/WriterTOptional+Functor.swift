import Foundation

public extension Writer {
    // WriterT + Optional — Writer<W, A?>

    func mapT<Inner, B>(_ fn: (Inner) -> B) -> Writer<W, B?> where A == Inner? {
        mapWriter { $0.map(fn) }
    }

    static func fmapT<Inner, B>(
        _ fn: @escaping (Inner) -> B
    ) -> (Writer<W, Inner?>) -> Writer<W, B?> where A == Inner? {
        { $0.mapT(fn) }
    }
}
