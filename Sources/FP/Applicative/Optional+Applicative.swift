import Foundation

public extension Optional {
    fileprivate struct UnwrapError: Error {}
    /// Similar to zip(array1, array2) and Publishers.Zip(p1, p2), it will
    /// try to unwrap both sides, if any is nil, return nil. If both are
    /// present, the return will be a tuple with the unwrapped values.
    /// Typically used together with map:
    /// ```
    /// Optional.zip(possibleInteger1, possibleInteger2).map(+) ?? fallback
    /// Optional.zip(possibleInteger1, possibleInteger2, possibleInteger3, possibleInteger4).map(+) ?? fallback
    /// ```
    static func zip<SecondWrapped, each AdditionalWrapped>(
        _ firstOptional: Wrapped?,
        _ secondOptional: SecondWrapped?,
        _ additionalOptional: repeat (each AdditionalWrapped)?
    ) -> (Wrapped, SecondWrapped, repeat each AdditionalWrapped)? {
        func unwrap<T>(_ t: T?) throws -> T {
            guard let t else { throw UnwrapError() }
            return t
        }

        do {
            return try (
                unwrap(firstOptional),
                unwrap(secondOptional),
                repeat unwrap(each additionalOptional)
            )
        } catch {
            return nil
        }
    }
}
