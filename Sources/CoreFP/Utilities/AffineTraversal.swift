/// An optic that focuses on zero or one value inside `S`. It is the result of composing a
/// `Lens` with a `Prism` (in either order), and combines the "always-present whole" guarantee
/// of a lens with the "maybe-present focus" of a prism.
public struct AffineTraversal<S, A>: @unchecked Sendable {
    public let preview: (S) -> A?
    public let set: (S, A) -> S

    public init(preview: @escaping (S) -> A?, set: @escaping (S, A) -> S) {
        self.preview = preview
        self.set = set
    }

    public func over(_ transform: @escaping (A) -> A) -> (S) -> S {
        { s in preview(s).map { set(s, transform($0)) } ?? s }
    }
}
