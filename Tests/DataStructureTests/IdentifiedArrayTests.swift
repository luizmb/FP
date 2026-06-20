// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

// Named-function tests for IdentifiedArray. No custom operator symbols here — the
// operator forms live in DataStructureOperatorsTests.

private struct User: Identifiable, Hashable, Sendable {
    let id: Int
    var name: String
}

private struct Project: Equatable, Sendable {
    let slug: String
    var title: String
}

private func sampleUsers() -> IdentifiedArrayOf<User> {
    IdentifiedArray([User(id: 1, name: "Alice"), User(id: 2, name: "Bob"), User(id: 3, name: "Carol")])
}

@Suite("IdentifiedArray — core")
struct IdentifiedArrayCoreTests {
    @Test func preservesUserDefinedOrder() {
        let users = sampleUsers()
        #expect(users.elements.map(\.name) == ["Alice", "Bob", "Carol"])
        #expect(users.ids == [1, 2, 3])
    }

    @Test func lookupByIDReturnsElement() {
        let users = sampleUsers()
        #expect(users[id: 2] == User(id: 2, name: "Bob"))
        #expect(users[id: 9] == nil)
    }

    @Test func containsAndPosition() {
        let users = sampleUsers()
        #expect(users.contains(id: 3))
        #expect(!users.contains(id: 99))
        #expect(users.position(id: 3) == 2)
        #expect(users.position(id: 99) == nil)
    }

    @Test func subscriptReplaceInPlaceKeepsPosition() {
        var users = sampleUsers()
        users[id: 2] = User(id: 2, name: "Robert")
        #expect(users[id: 2]?.name == "Robert")
        #expect(users.position(id: 2) == 1)
        #expect(users.ids == [1, 2, 3])
    }

    @Test func subscriptAppendsWhenAbsent() {
        var users = sampleUsers()
        users[id: 4] = User(id: 4, name: "Dave")
        #expect(users.elements.last == User(id: 4, name: "Dave"))
        #expect(users.ids == [1, 2, 3, 4])
    }

    @Test func subscriptRemovesOnNil() {
        var users = sampleUsers()
        users[id: 2] = nil
        #expect(users[id: 2] == nil)
        #expect(users.ids == [1, 3])
    }

    @Test func subscriptNoOpOnIDMismatch() {
        var users = sampleUsers()
        users[id: 2] = User(id: 99, name: "X")
        #expect(users[id: 2]?.name == "Bob")
        #expect(users.contains(id: 99) == false)
    }

    @Test func appendLastWinsOnDuplicateID() {
        var users = sampleUsers()
        users.append(User(id: 2, name: "Bobby"))
        #expect(users.count == 3)
        #expect(users[id: 2]?.name == "Bobby")
        #expect(users.position(id: 2) == 1) // kept original position
    }

    @Test func insertAtPositionShiftsAndReindexes() {
        var users = sampleUsers()
        users.insert(User(id: 10, name: "Zoe"), at: 1)
        #expect(users.ids == [1, 10, 2, 3])
        #expect(users.position(id: 3) == 3)
        #expect(users[id: 3]?.name == "Carol")
    }

    @Test func removeAtReindexesTail() {
        var users = sampleUsers()
        let removed = users.remove(at: 0)
        #expect(removed == User(id: 1, name: "Alice"))
        #expect(users.ids == [2, 3])
        #expect(users.position(id: 3) == 1)
    }

    @Test func removeByID() {
        var users = sampleUsers()
        #expect(users.remove(id: 2) == User(id: 2, name: "Bob"))
        #expect(users.remove(id: 99) == nil)
        #expect(users.ids == [1, 3])
    }

    @Test func initDedupsLastWins() {
        let users = IdentifiedArray([User(id: 1, name: "A"), User(id: 1, name: "B"), User(id: 2, name: "C")])
        #expect(users.count == 2)
        #expect(users[id: 1]?.name == "B")
        #expect(users.ids == [1, 2])
    }

    @Test func nonIdentifiableViaIDClosure() {
        var projects = IdentifiedArray(
            [Project(slug: "auth", title: "Auth"), Project(slug: "ui", title: "UI")],
            id: { $0.slug }
        )
        #expect(projects[id: "auth"]?.title == "Auth")
        projects[id: "ui"] = Project(slug: "ui", title: "UI v2")
        #expect(projects[id: "ui"]?.title == "UI v2")
    }
}

@Suite("IdentifiedArray — Collection")
struct IdentifiedArrayCollectionTests {
    @Test func countAndIteration() {
        let users = sampleUsers()
        #expect(users.count == 3)
        #expect(Array(users).map(\.name) == ["Alice", "Bob", "Carol"])
    }

    @Test func randomAccessSubscriptAndFirstLast() {
        let users = sampleUsers()
        #expect(users[0] == User(id: 1, name: "Alice"))
        #expect(users.first?.name == "Alice")
        #expect(users.last?.name == "Carol")
    }

    @Test func mapOverElements() {
        let users = sampleUsers()
        #expect(users.map(\.id) == [1, 2, 3])
    }

    @Test func equatableAndHashable() {
        let a = sampleUsers()
        let b = sampleUsers()
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
        var other = sampleUsers()
        other[id: 1] = User(id: 1, name: "Changed")
        #expect(other != a)
    }
}

@Suite("IdentifiedArray — Semigroup")
struct IdentifiedArraySemigroupTests {
    private func ia(_ pairs: [(Int, String)]) -> IdentifiedArrayOf<User> {
        IdentifiedArray(pairs.map { User(id: $0.0, name: $0.1) })
    }

    @Test func combineConcatenatesDistinctIDs() {
        let result = IdentifiedArrayOf<User>.combine(ia([(1, "A"), (2, "B")]), ia([(3, "C")]))
        #expect(result.ids == [1, 2, 3])
    }

    @Test func combineLastWinsKeepingLeftPosition() {
        let result = IdentifiedArrayOf<User>.combine(ia([(1, "A"), (2, "B")]), ia([(2, "B2"), (5, "C")]))
        #expect(result.ids == [1, 2, 5])
        #expect(result[id: 2]?.name == "B2") // right value wins
        #expect(result.position(id: 2) == 1) // left position kept
    }

    @Test func combineIsAssociativeWithCollisions() {
        let a = ia([(1, "a1"), (2, "a2")])
        let b = ia([(2, "b2"), (3, "b3")])
        let c = ia([(3, "c3"), (1, "c1")])
        let left = IdentifiedArrayOf<User>.combine(IdentifiedArrayOf<User>.combine(a, b), c)
        let right = IdentifiedArrayOf<User>.combine(a, IdentifiedArrayOf<User>.combine(b, c))
        #expect(left == right)
    }

    @Test func combineWithEmptyIsIdentityInPractice() {
        let a = ia([(1, "A"), (2, "B")])
        #expect(IdentifiedArrayOf<User>.combine(a, IdentifiedArrayOf<User>()) == a)
        #expect(IdentifiedArrayOf<User>.combine(IdentifiedArrayOf<User>(), a) == a)
    }
}

@Suite("IdentifiedArray — open-addressing stress")
struct IdentifiedArrayStressTests {
    // Deterministic LCG so failures reproduce.
    private struct LCG {
        var state: UInt64
        mutating func next(_ bound: Int) -> Int {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Int((state >> 33) % UInt64(bound))
        }
    }

    // Applies the same random ops to an IdentifiedArray and a plain-array reference,
    // asserting structural agreement (order + by-id lookup) after every step. This
    // exercises table growth, backward-shift deletion, and position shifting.
    @Test func matchesReferenceUnderChurn() {
        var rng = LCG(state: 0xDEADBEEF)
        var ia = IdentifiedArrayOf<User>()
        var ref: [User] = []
        var nextID = 0

        func check(_ step: Int) {
            #expect(ia.elements == ref, "order mismatch at step \(step)")
            for (i, user) in ref.enumerated() {
                #expect(ia.position(id: user.id) == i, "position mismatch id \(user.id) at step \(step)")
                #expect(ia[id: user.id] == user, "lookup mismatch id \(user.id) at step \(step)")
            }
            #expect(ia.count == ref.count)
        }

        for step in 0..<2_000 {
            let op = rng.next(5)
            switch op {
            case 0: // append new
                let u = User(id: nextID, name: "n\(nextID)")
                nextID += 1
                ia.append(u)
                ref.append(u)

            case 1 where !ref.isEmpty: // update existing in place (same id)
                let i = rng.next(ref.count)
                let u = User(id: ref[i].id, name: "u\(step)")
                ia[id: u.id] = u
                ref[i] = u

            case 2: // insert at random position (new id)
                let pos = rng.next(ref.count + 1)
                let u = User(id: nextID, name: "i\(nextID)")
                nextID += 1
                ia.insert(u, at: pos)
                ref.insert(u, at: pos)

            case 3 where !ref.isEmpty: // remove by id
                let i = rng.next(ref.count)
                let removedID = ref[i].id
                ia.remove(id: removedID)
                ref.remove(at: i)

            case 4 where !ref.isEmpty: // remove at position
                let pos = rng.next(ref.count)
                ia.remove(at: pos)
                ref.remove(at: pos)

            default:
                continue
            }
            if step.isMultiple(of: 50) { check(step) }
        }
        check(2_000)
    }
}

@Suite("IdentifiedArray — optics")
struct IdentifiedArrayOpticsTests {
    @Test func ixByIDPreviewAndSet() {
        let optic = IdentifiedArrayOf<User>.ix(id: 2)
        let users = sampleUsers()
        #expect(optic.preview(users)?.name == "Bob")
        #expect(IdentifiedArrayOf<User>.ix(id: 9).preview(users) == nil)
        let updated = optic.set(users, User(id: 2, name: "Robert"))
        #expect(updated[id: 2]?.name == "Robert")
    }

    @Test func ixByIDOverMutates() {
        let optic = IdentifiedArrayOf<User>.ix(id: 3)
        let users = optic.over { User(id: $0.id, name: $0.name + "!") }(sampleUsers())
        #expect(users[id: 3]?.name == "Carol!")
        #expect(users[id: 1]?.name == "Alice")
    }

    @Test func ixByIDSetAbsentIsNoOp() {
        let users = sampleUsers()
        let result = IdentifiedArrayOf<User>.ix(id: 99).set(users, User(id: 99, name: "Ghost"))
        #expect(result == users)
    }

    @Test func ixByPositionMutates() {
        let optic = IdentifiedArrayOf<User>.ix(0)
        let users = optic.over { User(id: $0.id, name: "First") }(sampleUsers())
        #expect(users[0].name == "First")
    }

    @Test func traversedGetAllAndOver() {
        let users = IdentifiedArrayOf<User>.traversed.over { User(id: $0.id, name: $0.name.uppercased()) }(sampleUsers())
        #expect(users.elements.map(\.name) == ["ALICE", "BOB", "CAROL"])
        #expect(IdentifiedArrayOf<User>.traversed.getAll(sampleUsers()).count == 3)
    }

    @Test func traversedWhereFiltersFoci() {
        let optic = IdentifiedArrayOf<User>.traversed { !$0.id.isMultiple(of: 2) }
        let users = optic.over { User(id: $0.id, name: $0.name + "*") }(sampleUsers())
        #expect(users[id: 1]?.name == "Alice*")
        #expect(users[id: 2]?.name == "Bob")
        #expect(users[id: 3]?.name == "Carol*")
    }

    @Test func arrayIsoRoundTripsFromIdentifiedArray() {
        let iso = IdentifiedArrayOf<User>.arrayIso
        let users = sampleUsers()
        #expect(iso.reverseGet(iso.get(users)) == users)
    }

    @Test func arrayIsoRoundTripsFromUniqueArray() {
        let iso = IdentifiedArrayOf<User>.arrayIso
        let array = [User(id: 5, name: "E"), User(id: 6, name: "F")]
        #expect(iso.get(iso.reverseGet(array)) == array)
    }

    @Test func dedupPrismSucceedsOnUniqueFailsOnDuplicate() {
        let prism = IdentifiedArrayOf<User>.dedupPrism
        let unique = [User(id: 1, name: "A"), User(id: 2, name: "B")]
        let dups = [User(id: 1, name: "A"), User(id: 1, name: "B")]
        #expect(prism.preview(unique) != nil)
        #expect(prism.preview(dups) == nil)
        // review ∘ preview round-trips on unique input
        #expect(prism.preview(unique).map(prism.review) == unique)
    }

    @Test func dedupPrismReviewThenPreviewIsIdentity() {
        let prism = IdentifiedArrayOf<User>.dedupPrism
        let users = sampleUsers()
        #expect(prism.preview(prism.review(users)) == users)
    }

    @Test func orderedDictionaryIsoRoundTrips() {
        let iso = IdentifiedArrayOf<User>.orderedDictionaryIso
        let users = sampleUsers()
        #expect(iso.reverseGet(iso.get(users)) == users)
    }

    @Test func dictionaryProjectionIsLossyButComplete() {
        let users = sampleUsers()
        let dict = users.dictionary
        #expect(dict.count == 3)
        #expect(dict[2]?.name == "Bob")
    }
}
