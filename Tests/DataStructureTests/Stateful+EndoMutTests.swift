import CoreFP
import DataStructure
import Testing

@Suite("Stateful <-> EndoMut bridges")
struct StatefulEndoMutBridgeTests {
    @Test func toEndoMut_preservesBehavior() {
        let s = Stateful<[Int], Void> { xs in xs.sort() }
        var arr = [3, 1, 2]
        s.toEndoMut()(&arr)
        #expect(arr == [1, 2, 3])
    }

    @Test func toStateful_preservesBehavior() {
        let e = EndoMut<[Int]> { xs in xs.sort() }
        let (_, finalState) = e.toStateful().runStateful([3, 1, 2])
        #expect(finalState == [1, 2, 3])
    }

    @Test func roundTrip_statefulToEndoMutToStateful() {
        let original = Stateful<Int, Void> { s in s += 10 }
        let (_, state) = original.toEndoMut().toStateful().runStateful(5)
        #expect(state == 15)
    }

    @Test func roundTrip_endoMutToStatefulToEndoMut() {
        let original = EndoMut<Int> { $0 *= 3 }
        var value = 4
        original.toStateful().toEndoMut()(&value)
        #expect(value == 12)
    }
}
