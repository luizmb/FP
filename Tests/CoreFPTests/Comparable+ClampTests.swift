import CoreFP
import Testing

@Suite struct ComparableClampTests {
    // MARK: - clamped(to:)

    @Test func clampedInside_returnsValueItself() {
        #expect(5.clamped(to: 0...10) == 5)
    }

    @Test func clampedBelow_returnsLowerBound() {
        #expect((-3).clamped(to: 0...10) == 0)
    }

    @Test func clampedAbove_returnsUpperBound() {
        #expect(42.clamped(to: 0...10) == 10)
    }

    @Test func clampedAtLowerBound_returnsLowerBound() {
        #expect(0.clamped(to: 0...10) == 0)
    }

    @Test func clampedAtUpperBound_returnsUpperBound() {
        #expect(10.clamped(to: 0...10) == 10)
    }

    @Test func clampedFloat() {
        #expect(3.5.clamped(to: 0.0...1.0) == 1.0)
        #expect((-0.5).clamped(to: 0.0...1.0) == 0.0)
        #expect(0.42.clamped(to: 0.0...1.0) == 0.42)
    }

    @Test func clampedSingletonRange() {
        // When the range collapses to a single value, every input clamps to it.
        #expect(0.clamped(to: 5...5) == 5)
        #expect(5.clamped(to: 5...5) == 5)
        #expect(99.clamped(to: 5...5) == 5)
    }

    @Test func clampedString() {
        // Comparable doesn't require Numeric — String works.
        #expect("c".clamped(to: "a"..."b") == "b")
        #expect("a".clamped(to: "a"..."z") == "a")
        #expect("m".clamped(to: "a"..."z") == "m")
    }

    // MARK: - within(_:)

    @Test func withinInside_returnsTrue() {
        #expect(42.within(40...50) == true)
    }

    @Test func withinAtLowerBound_returnsTrue() {
        #expect(40.within(40...50) == true)
    }

    @Test func withinAtUpperBound_returnsTrue() {
        #expect(50.within(40...50) == true)
    }

    @Test func withinBelow_returnsFalse() {
        #expect(39.within(40...50) == false)
    }

    @Test func withinAbove_returnsFalse() {
        #expect(51.within(40...50) == false)
    }

    @Test func withinFloat() {
        #expect((0.42).within(0.0...1.0) == true)
        #expect((1.001).within(0.0...1.0) == false)
    }

    @Test func withinString() {
        #expect("m".within("a"..."z") == true)
        #expect("A".within("a"..."z") == false)
    }
}
