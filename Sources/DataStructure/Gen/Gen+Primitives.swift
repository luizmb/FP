import Foundation

// Primitive generators. Each fixed-output factory carries a per-member `where A == <output>`
// clause (SE-0267): the member exists only when the base's value type already equals its output,
// so `Gen.int(in:)` / `Gen.bool` resolve without an explicit type annotation. A plain extension
// would leave the base's `A` free and force `Gen<Int>.int(in:)` or a typed context.

// Every generator is a `static func … where A == Output`: the `where` constrains the base value
// type so `Gen.bool()` / `Gen.int(in:)` resolve without an explicit type annotation. Swift forbids
// `where` on computed properties (and stored statics on generic types), so the no-argument
// generators take `()` rather than being properties.

extension Stateful where S == AnyRandomNumberGenerator {
    /// A uniform random `UInt64` — the raw output of the underlying generator.
    public static func uint64() -> Gen<UInt64> where A == UInt64 {
        Gen<UInt64> { rng in rng.next() }
    }

    /// A uniform random `Bool`.
    public static func bool() -> Gen<Bool> where A == Bool {
        Gen<Bool> { rng in Bool.random(using: &rng) }
    }

    /// A uniform random `Int` in the closed `range`.
    public static func int(in range: ClosedRange<Int>) -> Gen<Int> where A == Int {
        Gen<Int> { rng in Int.random(in: range, using: &rng) }
    }

    /// A uniform random `Double` in the closed `range`.
    public static func double(in range: ClosedRange<Double>) -> Gen<Double> where A == Double {
        Gen<Double> { rng in Double.random(in: range, using: &rng) }
    }

    /// A random version-4 `UUID`.
    ///
    /// Built from 16 generator bytes with the standard version/variant bits set, so the result is
    /// a well-formed v4 UUID that is reproducible from the generator's seed (unlike `UUID()`).
    public static func uuid() -> Gen<UUID> where A == UUID {
        Gen<UUID> { rng in
            let hi = rng.next()
            let lo = rng.next()
            var bytes = [UInt8](repeating: 0, count: 16)
            for index in 0..<8 { bytes[index] = UInt8(truncatingIfNeeded: hi >> (UInt64(index) * 8)) }
            for index in 0..<8 { bytes[8 + index] = UInt8(truncatingIfNeeded: lo >> (UInt64(index) * 8)) }
            bytes[6] = (bytes[6] & 0x0F) | 0x40 // version 4
            bytes[8] = (bytes[8] & 0x3F) | 0x80 // variant 1 (RFC 4122)
            return UUID(uuid: (
                bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
            ))
        }
    }

    /// A uniform random element of `collection`, or `nil` when it is empty.
    public static func element<C: Collection & Sendable>(
        of collection: C
    ) -> Gen<C.Element?> where A == C.Element?, C.Element: Sendable {
        Gen<C.Element?> { rng in collection.randomElement(using: &rng) }
    }
}
