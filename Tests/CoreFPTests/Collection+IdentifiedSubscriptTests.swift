// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

private struct User: Identifiable, Equatable {
    let id: Int
    let name: String
}

@Suite("Collection[id:] — getter")
struct CollectionIdentifiedSubscriptGetterTests {
    private let users = [
        User(id: 1, name: "Alice"),
        User(id: 2, name: "Bob"),
        User(id: 3, name: "Carol")
    ]

    @Test func returns_element_when_id_matches() {
        #expect(users[id: 2] == User(id: 2, name: "Bob"))
    }

    @Test func returns_nil_when_id_missing() {
        #expect(users[id: 99] == nil)
    }

    @Test func returns_first_match_when_duplicated() {
        let dupes = users + [User(id: 2, name: "Bob's twin")]
        #expect(dupes[id: 2]?.name == "Bob")
    }

    @Test func works_on_empty_collection() {
        let empty: [User] = []
        #expect(empty[id: 1] == nil)
    }
}

@Suite("RangeReplaceableCollection[id:] — setter")
struct RangeReplaceableCollectionIdentifiedSubscriptSetterTests {
    @Test func set_existing_id_replaces_in_place() {
        var users = [
            User(id: 1, name: "Alice"),
            User(id: 2, name: "Bob")
        ]
        users[id: 2] = User(id: 2, name: "Robert")
        #expect(users == [
            User(id: 1, name: "Alice"),
            User(id: 2, name: "Robert")
        ])
    }

    @Test func set_missing_id_appends_to_end() {
        var users = [
            User(id: 1, name: "Alice"),
            User(id: 2, name: "Bob")
        ]
        users[id: 3] = User(id: 3, name: "Carol")
        #expect(users == [
            User(id: 1, name: "Alice"),
            User(id: 2, name: "Bob"),
            User(id: 3, name: "Carol")
        ])
    }

    @Test func set_nil_on_existing_id_removes() {
        var users = [
            User(id: 1, name: "Alice"),
            User(id: 2, name: "Bob"),
            User(id: 3, name: "Carol")
        ]
        users[id: 2] = nil
        #expect(users == [
            User(id: 1, name: "Alice"),
            User(id: 3, name: "Carol")
        ])
    }

    @Test func set_nil_on_missing_id_is_noop() {
        var users = [User(id: 1, name: "Alice"), User(id: 2, name: "Bob")]
        let before = users
        users[id: 99] = nil
        #expect(users == before)
    }

    @Test func set_with_mismatched_id_is_noop_when_existing() {
        var users = [User(id: 1, name: "Alice"), User(id: 2, name: "Bob")]
        let before = users
        // Slot 23 doesn't exist; replacement has id 24 — id mismatch wins, no-op.
        users[id: 23] = User(id: 24, name: "Dave")
        #expect(users == before)
    }

    @Test func set_with_mismatched_id_is_noop_when_replacing() {
        var users = [User(id: 1, name: "Alice"), User(id: 2, name: "Bob")]
        let before = users
        // Slot 2 exists, but replacement has id 99 — mismatch protects against the swap.
        users[id: 2] = User(id: 99, name: "Hacker")
        #expect(users == before)
    }

    @Test func set_works_on_empty_collection_by_appending() {
        var users: [User] = []
        users[id: 1] = User(id: 1, name: "Alice")
        #expect(users == [User(id: 1, name: "Alice")])
    }

    @Test func set_then_get_roundtrips() {
        var users = [User(id: 1, name: "Alice")]
        users[id: 5] = User(id: 5, name: "Eve")
        #expect(users[id: 5] == User(id: 5, name: "Eve"))
    }

    @Test func set_then_clear_roundtrips() {
        var users = [User(id: 1, name: "Alice"), User(id: 2, name: "Bob")]
        users[id: 1] = nil
        #expect(users[id: 1] == nil)
        #expect(users[id: 2] == User(id: 2, name: "Bob"))
    }
}
