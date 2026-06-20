// SPDX-License-Identifier: Apache-2.0
import CoreFP
import FPMacros
import Testing

// MARK: - @DeriveMonoid

@DeriveMonoid
fileprivate struct Stats {
    var clicks: Int.Monoids.Sum
    var ok: Bool.Monoids.And
}

@Suite("@DeriveMonoid")
struct DeriveMonoidTests {
    @Test func identityIsFieldwise() {
        #expect(Stats.identity.clicks.rawValue == 0)
        #expect(Stats.identity.ok.rawValue == true)
    }

    @Test func combineIsFieldwise() {
        let combined = Stats.combine(
            Stats(clicks: .init(2), ok: .init(true)),
            Stats(clicks: .init(3), ok: .init(false))
        )
        #expect(combined.clicks.rawValue == 5) // summed
        #expect(combined.ok.rawValue == false) // AND-ed
    }

    @Test func foldsViaMconcat() {
        let folded = mconcat([
            Stats(clicks: .init(1), ok: .init(true)),
            Stats(clicks: .init(4), ok: .init(true))
        ])
        #expect(folded.clicks.rawValue == 5)
        #expect(folded.ok.rawValue == true)
    }
}

// MARK: - @Iso

@Iso
fileprivate struct Point { var x: Int; var y: Int }

@Iso
fileprivate struct Celsius { var value: Double }

fileprivate struct PointDTO { var x: Int; var y: Int }

@Iso(PointDTO.self)
fileprivate struct LabeledPoint { var x: Int; var y: Int }

@Suite("@Iso")
struct IsoMacroTests {
    @Test func tupleRepresentation() {
        let tuple = Point.iso.get(Point(x: 1, y: 2))
        #expect(tuple.0 == 1)
        #expect(tuple.1 == 2)
        let point = Point.iso.reverseGet((3, 4))
        #expect(point.x == 3 && point.y == 4)
    }

    @Test func singleFieldCollapses() {
        #expect(Celsius.iso.get(Celsius(value: 36.6)) == 36.6)
        #expect(Celsius.iso.reverseGet(40.0).value == 40.0)
    }

    @Test func namedTypeIso() {
        let dto = LabeledPoint.iso.get(LabeledPoint(x: 5, y: 6)) // PointDTO
        #expect(dto.x == 5 && dto.y == 6)
        let back = LabeledPoint.iso.reverseGet(PointDTO(x: 7, y: 8))
        #expect(back.x == 7 && back.y == 8)
    }
}
