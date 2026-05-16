import CoreFP
import DataStructure
import Foundation
import Testing

// MARK: - Fixtures

private enum UserTag {}
private enum OrderTag {}
private typealias UserID  = Newtype<UserTag,  Int>
private typealias OrderID = Newtype<OrderTag, Int>

private enum NameTag {}
private typealias Name = Newtype<NameTag, String>

private enum ListTag {}
private typealias Numbers = Newtype<ListTag, [Int]>

private enum MoneyTag {}
private typealias Cents = Newtype<MoneyTag, Int>

private struct BoxedError: Error, Equatable { let message: String }
private enum WrappedErrorTag {}
private typealias WrappedError = Newtype<WrappedErrorTag, BoxedError>

@Suite struct NewtypeTests {
    // MARK: - Construction

    @Test func shortInit() {
        let id = UserID(42)
        #expect(id.rawValue == 42)
    }

    @Test func labelledRawValueInit() {
        let id = UserID(rawValue: 42)
        #expect(id.rawValue == 42)
    }

    @Test func wrappedValueInit() {
        let id = UserID(wrappedValue: 42)
        #expect(id.rawValue == 42)
    }

    // MARK: - Phantom Tag distinguishes types

    @Test func differentTagsProduceDifferentTypes() {
        let u: UserID = UserID(1)
        let o: OrderID = OrderID(1)
        // The compiler treats UserID and OrderID as unrelated.
        // We compare rawValues to verify they carry the same payload.
        #expect(u.rawValue == o.rawValue)
    }

    // MARK: - Property wrapper

    @Test func propertyWrapperExposesWrappedAndProjected() {
        struct User {
            @Newtype<UserTag, Int> var id: Int = 42
        }
        let user = User()
        #expect(user.id == 42)
        #expect(user.$id.rawValue == 42)
    }

    // MARK: - Equatable / Hashable / Comparable

    @Test func equatable() {
        #expect(UserID(1) == UserID(1))
        #expect(UserID(1) != UserID(2))
    }

    @Test func hashable() {
        var set: Set<UserID> = []
        set.insert(UserID(1))
        set.insert(UserID(1))
        set.insert(UserID(2))
        #expect(set.count == 2)
    }

    @Test func comparable() {
        #expect(UserID(1) < UserID(2))
        #expect(UserID(2) > UserID(1))
    }

    // MARK: - Always-on description

    @Test func descriptionDelegatesToRawValue() {
        let id = UserID(42)
        #expect(id.description == "42")
    }

    @Test func debugDescriptionDelegatesToRawValue() {
        let name = Name("alice")
        #expect(name.debugDescription == String(reflecting: "alice"))
    }

    // MARK: - Codable

    @Test func codableRoundTrip() throws {
        let id = UserID(42)
        let data = try JSONEncoder().encode(id)
        let decoded = try JSONDecoder().decode(UserID.self, from: data)
        #expect(decoded == id)
    }

    @Test func encodesAsSingleValue() throws {
        let id = UserID(42)
        let data = try JSONEncoder().encode(id)
        let string = String(data: data, encoding: .utf8)
        #expect(string == "42")
    }

    // MARK: - RawRepresentable

    @Test func rawRepresentable() {
        let id = UserID(rawValue: 42)
        #expect(id.rawValue == 42)
    }

    // MARK: - Error

    @Test func errorConformance() {
        let err = WrappedError(BoxedError(message: "boom"))
        do {
            throw err
        } catch let caught as WrappedError {
            #expect(caught.rawValue == BoxedError(message: "boom"))
        } catch {
            Issue.record("Expected Newtype to be caught as WrappedError")
        }
    }

    // MARK: - Identifiable

    @Test func identifiable() {
        let id = UserID(42)
        #expect(id.id == id)
    }

    // MARK: - Literal conformances

    @Test func integerLiteral() {
        let id: UserID = 42
        #expect(id.rawValue == 42)
    }

    @Test func stringLiteral() {
        let name: Name = "alice"
        #expect(name.rawValue == "alice")
    }

    @Test func stringInterpolation() {
        let name: Name = "user \(7)"
        #expect(name.rawValue == "user 7")
    }

    @Test func arrayLiteralViaCollection() {
        // [Int] is ExpressibleByArrayLiteral via its own conformance — Newtype inherits it
        // through ExpressibleByArrayLiteral only if added explicitly. We didn't add it,
        // but going through the rawValue constructor still works:
        let ns = Numbers([1, 2, 3])
        #expect(ns.rawValue == [1, 2, 3])
    }

    // MARK: - Numeric stack (AdditiveArithmetic / Numeric / SignedNumeric)

    @Test func additiveArithmetic_zero() {
        #expect(Cents.zero == Cents(0))
    }

    @Test func additiveArithmetic_addAndSubtract() {
        let total = Cents(199) + Cents(100)
        #expect(total == Cents(299))
        #expect(total - Cents(99) == Cents(200))
    }

    @Test func additiveArithmetic_compoundAssign() {
        var c = Cents(100)
        c += Cents(50)
        #expect(c == Cents(150))
        c -= Cents(10)
        #expect(c == Cents(140))
    }

    @Test func numeric_multiply() {
        let total = Cents(5) * Cents(3)
        #expect(total == Cents(15))
    }

    @Test func numeric_magnitude() {
        #expect(Cents(-5).magnitude == UInt(5).magnitude)
    }

    @Test func numeric_initExactly() {
        let inRange: Cents? = Cents(exactly: 5)
        #expect(inRange == Cents(5))
    }

    @Test func signedNumeric_negate() {
        var c = Cents(5)
        c.negate()
        #expect(c == Cents(-5))
        #expect(-Cents(3) == Cents(-3))
    }

    // MARK: - BinaryInteger / FixedWidthInteger

    @Test func binaryInteger_divAndMod() {
        #expect(Cents(20) / Cents(3) == Cents(6))
        #expect(Cents(20) % Cents(3) == Cents(2))
    }

    @Test func binaryInteger_bitwise() {
        #expect(Cents(0b1100) & Cents(0b1010) == Cents(0b1000))
        #expect(Cents(0b1100) | Cents(0b1010) == Cents(0b1110))
        #expect(Cents(0b1100) ^ Cents(0b1010) == Cents(0b0110))
    }

    @Test func binaryInteger_shifts() {
        #expect(Cents(1) << 4 == Cents(16))
        #expect(Cents(16) >> 4 == Cents(1))
    }

    @Test func fixedWidthInteger_minMax() {
        #expect(Cents.min == Cents(Int.min))
        #expect(Cents.max == Cents(Int.max))
    }

    @Test func fixedWidthInteger_addingReportingOverflow() {
        let (result, overflow) = Cents(Int.max).addingReportingOverflow(Cents(1))
        #expect(overflow == true)
        #expect(result.rawValue == Int.max &+ 1)
    }

    // MARK: - Strideable

    @Test func strideable_distance() {
        #expect(Cents(5).distance(to: Cents(12)) == 7)
    }

    @Test func strideable_advanced() {
        #expect(Cents(5).advanced(by: 7) == Cents(12))
    }

    // MARK: - Sequence / Collection

    @Test func sequenceConformance() {
        let ns = Numbers([1, 2, 3])
        let doubled = ns.map { $0 * 2 }
        #expect(doubled == [2, 4, 6])
    }

    @Test func collectionConformance() {
        let ns = Numbers([10, 20, 30])
        #expect(ns.count == 3)
        #expect(ns.startIndex == 0)
        #expect(ns[1] == 20)
    }

    @Test func bidirectionalCollection() {
        let ns = Numbers([1, 2, 3])
        #expect(Array(ns.reversed()) == [3, 2, 1])
    }

    @Test func rangeReplaceableCollection() {
        var ns = Numbers()
        ns.replaceSubrange(0..<0, with: [1, 2, 3])
        #expect(ns.rawValue == [1, 2, 3])
    }

    // MARK: - Semigroup / Monoid

    @Test func semigroupCombine() {
        let combined = Newtype<NameTag, String>.combine(Name("hello, "), Name("world"))
        #expect(combined.rawValue == "hello, world")
    }

    @Test func monoidIdentity() {
        #expect(Newtype<NameTag, String>.identity.rawValue == "")
    }

    // MARK: - Floating-point operators (non-conformance helpers)

    @Test func floatingPoint_divide() {
        typealias Rate = Newtype<MoneyTag, Double>
        let result = Rate(10.0) / Rate(4.0)
        #expect(result.rawValue == 2.5)
    }

    @Test func floatingPoint_compoundDivide() {
        typealias Rate = Newtype<MoneyTag, Double>
        var r = Rate(10.0)
        r /= Rate(4.0)
        #expect(r.rawValue == 2.5)
    }

    @Test func floatingPoint_squareRoot() {
        typealias Rate = Newtype<MoneyTag, Double>
        #expect(Rate(16.0).squareRoot().rawValue == 4.0)
    }

    @Test func floatingPoint_rounded() {
        typealias Rate = Newtype<MoneyTag, Double>
        #expect(Rate(2.7).rounded(.down).rawValue == 2.0)
        #expect(Rate(2.3).rounded(.up).rawValue == 3.0)
    }
}
