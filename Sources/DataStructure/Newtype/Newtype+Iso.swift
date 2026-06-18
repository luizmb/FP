// SPDX-License-Identifier: Apache-2.0
import CoreFP

public extension Newtype {
    /// The `Iso` between this newtype and its raw value — `get` unwraps, `reverseGet` wraps.
    ///
    /// Total and verified (the wrapping initialiser never fails), unlike a generic
    /// `RawRepresentable` iso whose `init?(rawValue:)` may be failable for enums.
    ///
    /// ```swift
    /// typealias UserID = Newtype<User, Int>
    /// UserID.iso.get(UserID(42))        // 42
    /// UserID.iso.reverseGet(42)         // UserID(42)
    /// ```
    static var iso: CoreFP.Iso<Self, RawValue> {
        CoreFP.iso(get: { $0.rawValue }, reverseGet: { Self(rawValue: $0) })
    }
}
