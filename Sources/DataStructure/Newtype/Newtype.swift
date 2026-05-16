/// A zero-cost wrapper that gives `RawValue` a distinct nominal identity, distinguished by a phantom `Tag`.
///
/// `Newtype` is this library's equivalent of Haskell's `newtype` keyword: a struct that wraps a single
/// `RawValue` while carrying a phantom `Tag` parameter that exists only at compile time. Two `Newtype`s
/// with different `Tag`s are entirely distinct types — even when their `RawValue` is identical — so the
/// compiler will reject mixing them.
///
/// ## Why
///
/// Using bare `Int` for `UserID`, `OrderID`, `ProductID` is unsafe — the compiler will happily let you
/// pass a `UserID` where an `OrderID` is expected. `Newtype` fixes this with zero runtime cost:
///
/// ```swift
/// enum UserTag {}
/// enum OrderTag {}
/// typealias UserID  = Newtype<UserTag,  Int>
/// typealias OrderID = Newtype<OrderTag, Int>
///
/// func fetch(_ id: UserID) { … }
/// fetch(UserID(42))             // ✅
/// fetch(OrderID(42))            // ❌ compile error — different type
/// ```
///
/// Common convention is to use the value's "owning" nominal type itself as the tag, with no need for
/// a separate empty enum:
///
/// ```swift
/// struct User { let id: Newtype<User, Int> }
/// ```
///
/// ## Property wrapper form
///
/// `Newtype` is also a `@propertyWrapper`, so you can declare branded fields and still expose the
/// raw value through normal property access:
///
/// ```swift
/// struct User {
///     @Newtype<UserTag, Int> var id: Int = 42
/// }
///
/// let user = User()
/// user.id    // Int        — the unwrapped raw value
/// user.$id   // Newtype<UserTag, Int> — the branded wrapper
/// ```
///
/// ## Conformances
///
/// `Newtype` inherits behaviour from `RawValue` through conditional conformances: `Equatable`,
/// `Hashable`, `Comparable`, `Encodable`, `Decodable`, `Sendable`, `Error`, `Identifiable`, the full
/// numeric stack (`AdditiveArithmetic`, `Numeric`, `SignedNumeric`, `Strideable`, `BinaryInteger`,
/// `FixedWidthInteger`, `UnsignedInteger`, `SignedInteger`, `FloatingPoint`, `BinaryFloatingPoint`),
/// every `ExpressibleBy*Literal` protocol, the collection hierarchy, and ``Semigroup`` / ``Monoid``.
///
/// `CustomStringConvertible` and `CustomDebugStringConvertible` are conformed **unconditionally** via
/// `String(describing:)` and `String(reflecting:)` — this is intentional to dodge a Swift overload-
/// resolution edge case where conditional `CustomStringConvertible` on a type used inside monad
/// transformer expressions makes operator inference ambiguous.
///
/// All operators are native (`+`, `-`, `*`, `<`, `==`, …) inherited from those protocols, so they live
/// alongside the type in `DataStructure` — no `DataStructureOperators` module is required to use them.
@propertyWrapper
public struct Newtype<Tag, RawValue> {
    public var rawValue: RawValue

    public init(_ rawValue: RawValue) {
        self.rawValue = rawValue
    }

    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    public init(wrappedValue: RawValue) {
        self.rawValue = wrappedValue
    }

    public var wrappedValue: RawValue {
        get { rawValue }
        set { rawValue = newValue }
    }

    public var projectedValue: Self {
        get { self }
        set { self = newValue }
    }
}

// MARK: - Always-on conformances

extension Newtype: CustomStringConvertible {
    public var description: String { String(describing: rawValue) }
}

extension Newtype: CustomDebugStringConvertible {
    public var debugDescription: String { String(reflecting: rawValue) }
}

// MARK: - RawRepresentable

extension Newtype: RawRepresentable {}

// MARK: - Conditional conformances (value-level)

extension Newtype: Equatable where RawValue: Equatable {}
extension Newtype: Hashable where RawValue: Hashable {}
extension Newtype: Sendable where RawValue: Sendable {}
extension Newtype: Error where RawValue: Error {}

extension Newtype: Comparable where RawValue: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Newtype: Encodable where RawValue: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension Newtype: Decodable where RawValue: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(try container.decode(RawValue.self))
    }
}

extension Newtype: Identifiable where RawValue: Hashable {
    public var id: Self { self }
}
