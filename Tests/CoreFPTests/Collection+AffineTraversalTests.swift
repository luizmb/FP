@testable import CoreFP
import Testing

// MARK: - Fixtures

private struct Item: Identifiable, Equatable {
    let id: Int
    var name: String
}

// MARK: - ix by Index

@Suite("ix by Index")
struct IxIndexTests {
    private let xs = [10, 20, 30]

    @Test func preview_hit() {
        #expect([Int].ix(1).preview(xs) == 20)
    }

    @Test func preview_miss() {
        #expect([Int].ix(5).preview(xs) == nil)
    }

    @Test func set_hit() {
        #expect([Int].ix(1).set(xs, 99) == [10, 99, 30])
    }

    @Test func set_miss() {
        #expect([Int].ix(5).set(xs, 99) == xs)
    }

    @Test func over_hit() {
        #expect([Int].ix(0).over({ $0 * 2 })(xs) == [20, 20, 30])
    }

    @Test func over_miss() {
        #expect([Int].ix(9).over({ $0 * 2 })(xs) == xs)
    }

    @Test("preview-set: setting at an in-bounds index returns the new value on preview")
    func law_previewSet() {
        let optic = [Int].ix(1)
        #expect(optic.preview(optic.set(xs, 99)) == 99)
    }

    @Test("set-preview: setting the current value is identity")
    func law_setPreview() {
        let optic = [Int].ix(1)
        let result = optic.preview(xs).map { optic.set(xs, $0) } ?? xs
        #expect(result == xs)
    }

    @Test("set-set: last set wins")
    func law_setSet() {
        let optic = [Int].ix(2)
        #expect(optic.set(optic.set(xs, 42), 99) == optic.set(xs, 99))
    }

    // MARK: lift

    @Test func lift_inBounds_mutatesElementInPlace() {
        var arr = [10, 20, 30]
        [Int].ix(1).lift(EndoMut { $0 += 5 })(&arr)
        #expect(arr == [10, 25, 30])
    }

    @Test func lift_outOfBounds_isNoOp() {
        var arr = [10, 20, 30]
        [Int].ix(9).lift(EndoMut { $0 += 5 })(&arr)
        #expect(arr == [10, 20, 30])
    }
}

// MARK: - ix by Identifiable ID

@Suite("ix by Identifiable ID")
struct IxIDTests {
    private let items = [Item(id: 1, name: "A"), Item(id: 2, name: "B"), Item(id: 3, name: "C")]

    @Test func preview_hit() {
        #expect([Item].ix(id: 2).preview(items)?.name == "B")
    }

    @Test func preview_miss() {
        #expect([Item].ix(id: 99).preview(items) == nil)
    }

    @Test func set_hit() {
        #expect([Item].ix(id: 2).set(items, Item(id: 2, name: "Z")).map(\.name) == ["A", "Z", "C"])
    }

    @Test func set_miss() {
        #expect([Item].ix(id: 99).set(items, Item(id: 99, name: "X")) == items)
    }

    @Test func over_hit() {
        let updated = [Item].ix(id: 3).over({ Item(id: $0.id, name: $0.name.lowercased()) })(items)
        #expect(updated.map(\.name) == ["A", "B", "c"])
    }

    @Test func over_miss() {
        let updated = [Item].ix(id: 99).over({ Item(id: $0.id, name: $0.name.lowercased()) })(items)
        #expect(updated == items)
    }

    @Test("preview-set: setting a known id returns the new element on preview")
    func law_previewSet() {
        let optic = [Item].ix(id: 1)
        let new = Item(id: 1, name: "Z")
        #expect(optic.preview(optic.set(items, new)) == new)
    }

    @Test("set-set: last set wins")
    func law_setSet() {
        let optic = [Item].ix(id: 2)
        #expect(optic.set(optic.set(items, Item(id: 2, name: "X")), Item(id: 2, name: "Y"))
            == optic.set(items, Item(id: 2, name: "Y")))
    }

    // MARK: lift

    @Test func lift_knownId_mutatesElementInPlace() {
        var items = [Item(id: 1, name: "A"), Item(id: 2, name: "B"), Item(id: 3, name: "C")]
        [Item].ix(id: 2).lift(EndoMut { $0 = Item(id: $0.id, name: $0.name.lowercased()) })(&items)
        #expect(items.map(\.name) == ["A", "b", "C"])
    }

    @Test func lift_unknownId_isNoOp() {
        var items = [Item(id: 1, name: "A"), Item(id: 2, name: "B")]
        [Item].ix(id: 99).lift(EndoMut { $0 = Item(id: $0.id, name: "Z") })(&items)
        #expect(items.map(\.name) == ["A", "B"])
    }
}

// MARK: - ix by Dictionary key

@Suite("ix by Dictionary key")
struct IxDictionaryTests {
    private let dict = ["a": 1, "b": 2, "c": 3]

    @Test func preview_hit() {
        #expect([String: Int].ix(key: "b").preview(dict) == 2)
    }

    @Test func preview_miss() {
        #expect([String: Int].ix(key: "z").preview(dict) == nil)
    }

    @Test func set_hit() {
        #expect([String: Int].ix(key: "b").set(dict, 99) == ["a": 1, "b": 99, "c": 3])
    }

    @Test func set_miss_is_noop() {
        #expect([String: Int].ix(key: "z").set(dict, 99) == dict)
    }

    @Test func over_hit() {
        #expect([String: Int].ix(key: "a").over({ $0 * 10 })(dict) == ["a": 10, "b": 2, "c": 3])
    }

    @Test func over_miss() {
        #expect([String: Int].ix(key: "z").over({ $0 * 10 })(dict) == dict)
    }

    @Test("preview-set: setting a known key returns the new value on preview")
    func law_previewSet() {
        let optic = [String: Int].ix(key: "a")
        #expect(optic.preview(optic.set(dict, 99)) == 99)
    }

    @Test("set-set: last set wins")
    func law_setSet() {
        let optic = [String: Int].ix(key: "b")
        #expect(optic.set(optic.set(dict, 42), 99) == optic.set(dict, 99))
    }

    // MARK: lift

    @Test func lift_presentKey_mutatesValueInPlace() {
        var d = ["a": 1, "b": 2, "c": 3]
        [String: Int].ix(key: "b").lift(EndoMut { $0 *= 10 })(&d)
        #expect(d["b"] == 20)
        #expect(d["a"] == 1)
    }

    @Test func lift_absentKey_isNoOp() {
        var d = ["a": 1, "b": 2]
        [String: Int].ix(key: "z").lift(EndoMut { $0 *= 10 })(&d)
        #expect(d == ["a": 1, "b": 2])
    }
}

// MARK: - [safe:] subscript

@Suite("[safe:] subscript")
struct SafeSubscriptTests {
    private let xs = [10, 20, 30]

    @Test func read_hit() { #expect(xs[safe: 1] == 20) }
    @Test func read_miss() { #expect(xs[safe: 9] == nil) }

    @Test func write_hit() {
        var ys = xs
        ys[safe: 1] = 99
        #expect(ys == [10, 99, 30])
    }

    @Test func write_miss_is_noop() {
        var ys = xs
        ys[safe: 9] = 99
        #expect(ys == xs)
    }

    @Test func write_nil_is_noop() {
        var ys = xs
        ys[safe: 1] = nil
        #expect(ys == xs)
    }
}

// MARK: - affineTraversal(writableKeyPath:)

@Suite("affineTraversal from WritableKeyPath<S, A?>")
struct AffineTraversalKeyPathTests {
    @Test func preview_hit() {
        #expect(affineTraversal(\[Int][safe: 1]).preview([10, 20, 30]) == 20)
    }

    @Test func preview_miss() {
        #expect(affineTraversal(\[Int][safe: 9]).preview([10, 20, 30]) == nil)
    }

    @Test func set_hit() {
        #expect(affineTraversal(\[Int][safe: 1]).set([10, 20, 30], 99) == [10, 99, 30])
    }

    @Test func set_miss_is_noop() {
        #expect(affineTraversal(\[Int][safe: 9]).set([10, 20, 30], 99) == [10, 20, 30])
    }

    @Test("affineTraversal(\\[Int][safe: i]) is equivalent to [Int].ix(i)")
    func equivalenceWithIx() {
        let xs = [10, 20, 30]
        let via = affineTraversal(\[Int][safe: 2])
        let direct = [Int].ix(2)
        #expect(via.preview(xs) == direct.preview(xs))
        #expect(via.set(xs, 99) == direct.set(xs, 99))
    }
}

// MARK: - Identity optics

@Suite("Optic identity (.id)")
struct OpticIdentityTests {
    @Test func lens_id_get() {
        #expect(Lens<Int, Int>.id.get(42) == 42)
    }

    @Test func lens_id_set() {
        #expect(Lens<Int, Int>.id.set(0, 42) == 42)
    }

    @Test func prism_id_preview() {
        #expect(Prism<Int, Int>.id.preview(42) == 42)
    }

    @Test func prism_id_review() {
        #expect(Prism<Int, Int>.id.review(42) == 42)
    }

    @Test func affineTraversal_id_preview() {
        #expect(AffineTraversal<Int, Int>.id.preview(42) == 42)
    }

    @Test func affineTraversal_id_set() {
        #expect(AffineTraversal<Int, Int>.id.set(0, 42) == 42)
    }

    @Test func iso_id_get() {
        #expect(Iso<Int, Int>.id.get(42) == 42)
    }

    @Test func iso_id_reverseGet() {
        #expect(Iso<Int, Int>.id.reverseGet(42) == 42)
    }

    @Test func iso_id_asLens_consistent_with_lens_id() {
        let via = Iso<Int, Int>.id.asLens
        let direct = Lens<Int, Int>.id
        #expect(via.get(7) == direct.get(7))
        #expect(via.set(0, 7) == direct.set(0, 7))
    }
}
