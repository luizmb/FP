import CoreFP
import CoreFPOperators
import DataStructure
import Testing

// Operator-form tests for IdentifiedArray optics: these exercise the `>>>`
// composition operator directly. The semantics themselves are covered by the
// named-function tests in DataStructureTests.

private struct User: Identifiable, Equatable, Sendable {
    let id: Int
    var name: String
}

private func sampleUsers() -> IdentifiedArrayOf<User> {
    IdentifiedArray([User(id: 1, name: "Alice"), User(id: 2, name: "Bob"), User(id: 3, name: "Carol")])
}

@Suite("IdentifiedArray — optic composition operators")
struct IdentifiedArrayOperatorTests {
    @Test func affineComposedWithLensPreviews() {
        let optic: AffineTraversal<IdentifiedArrayOf<User>, String> =
            IdentifiedArrayOf<User>.ix(id: 2) >>> ^\User.name
        #expect(optic.preview(sampleUsers()) == "Bob")
        #expect((IdentifiedArrayOf<User>.ix(id: 9) >>> ^\User.name).preview(sampleUsers()) == nil)
    }

    @Test func affineComposedWithLensSetsDeeply() {
        let optic: AffineTraversal<IdentifiedArrayOf<User>, String> =
            IdentifiedArrayOf<User>.ix(id: 2) >>> ^\User.name
        let users = optic.set(sampleUsers(), "Robert")
        #expect(users[id: 2]?.name == "Robert")
        #expect(users[id: 1]?.name == "Alice")
    }

    @Test func traversedComposedWithLensGetsAll() {
        let optic: Traversal<IdentifiedArrayOf<User>, String> =
            IdentifiedArrayOf<User>.traversed >>> ^\User.name
        #expect(optic.getAll(sampleUsers()) == ["Alice", "Bob", "Carol"])
    }

    @Test func traversedComposedWithLensOversAll() {
        let optic: Traversal<IdentifiedArrayOf<User>, String> =
            IdentifiedArrayOf<User>.traversed >>> ^\User.name
        let users = optic.over { $0.uppercased() }(sampleUsers())
        #expect(users.elements.map(\.name) == ["ALICE", "BOB", "CAROL"])
    }

    @Test func arrayIsoComposedWithEachIsTraversal() {
        let optic: Traversal<IdentifiedArrayOf<User>, User> =
            IdentifiedArrayOf<User>.arrayIso >>> [User].each
        #expect(optic.getAll(sampleUsers()).map(\.name) == ["Alice", "Bob", "Carol"])
    }

    @Test func semigroupCombineOperator() {
        let lhs = sampleUsers() // ids 1,2,3
        let rhs = IdentifiedArray([User(id: 3, name: "Carol2"), User(id: 4, name: "Dave")])
        let combined = lhs <> rhs
        #expect(combined.ids == [1, 2, 3, 4])
        #expect(combined[id: 3]?.name == "Carol2") // right wins
    }
}
