// SPDX-License-Identifier: Apache-2.0
import CoreFP
import FPMacros
import Testing

// Dynamic conformance check the compiler can't fold to a constant (avoids always-true/false warnings).
private func conformsToPrismatic(_ type: Any.Type) -> Bool { type is any Prismatic.Type }

// MARK: - Recursive: structs + enums at depths 1–3, plus a caseless namespace enum

@ApplyOptics(recursively: true)
fileprivate struct Tree {
    var name: String
    var count: Int

    struct Leaf { var value: Int } // depth 1 struct
    enum Branch { case left(Int); case right(String) } // depth 1 enum

    enum Namespace { // caseless → skipped, but recursed into
        struct Held { var x: Int } // depth 2
    }

    struct Mid { // depth 1
        var flag: Bool
        enum Deep { case on; case off(Int) } // depth 2 enum
        struct Inner { // depth 2
            var a: Int
            enum Bottom { case z(Int) } // depth 3 enum
        }
    }
}

@Suite("@ApplyOptics — recursive to any depth")
struct ApplyOpticsRecursiveTests {
    @Test func root() {
        #expect(Tree.lens.name.get(Tree(name: "a", count: 1)) == "a")
        #expect(Tree.lens.count.set(Tree(name: "a", count: 1), 9).count == 9)
    }

    @Test func depth1() {
        #expect(Tree.Leaf.lens.value.set(.init(value: 1), 7).value == 7)
        #expect(Tree.Branch.prism.left.preview(.left(3)) == 3)
        #expect(conformsToPrismatic(Tree.Branch.self))
    }

    @Test func caseless_namespace_skipped_but_recursed() {
        #expect(!conformsToPrismatic(Tree.Namespace.self))
        #expect(Tree.Namespace.Held.lens.x.set(.init(x: 1), 4).x == 4)
    }

    @Test func depth2() {
        #expect(Tree.Mid.lens.flag.set(.init(flag: false), true).flag == true)
        #expect(Tree.Mid.Deep.prism.off.preview(.off(5)) == 5)
        #expect(conformsToPrismatic(Tree.Mid.Deep.self))
        #expect(Tree.Mid.Inner.lens.a.set(.init(a: 1), 8).a == 8)
    }

    @Test func depth3_unbounded() {
        #expect(Tree.Mid.Inner.Bottom.prism.z.preview(.z(2)) == 2)
        #expect(conformsToPrismatic(Tree.Mid.Inner.Bottom.self))
        // composable case key path — proves the conformance is real at depth 3
        let kp: PrismKeyPath<Tree.Mid.Inner.Bottom, Int> = \.z
        #expect(Prism(kp).preview(.z(2)) == 2)
    }
}

// MARK: - @NoOptics cuts a subtree

@ApplyOptics(recursively: true)
fileprivate struct WithCut {
    var a: Int
    @NoOptics enum Skipped { case x(Int) }
    enum Kept { case y(Int) }
}

@Suite("@ApplyOptics — @NoOptics")
struct ApplyOpticsNoOpticsTests {
    @Test func sibling_of_cut_still_gets_optics() {
        #expect(WithCut.lens.a.set(.init(a: 1), 2).a == 2)
        #expect(WithCut.Kept.prism.y.preview(.y(1)) == 1)
        #expect(conformsToPrismatic(WithCut.Kept.self))
    }

    @Test func cut_node_gets_no_optics() {
        #expect(!conformsToPrismatic(WithCut.Skipped.self))
    }
}

// MARK: - Single-node override: manual @Lenses; recursion still reaches the grandchild

@ApplyOptics(recursively: true)
fileprivate struct OverrideHost {
    var a: Int

    @Lenses(init: .public)
    struct Manual {
        var b: Int
        struct Grandchild { var c: Int } // still gets optics — cycle relays past the manual node
    }
}

@Suite("@ApplyOptics — single-node override")
struct ApplyOpticsOverrideTests {
    @Test func root_manual_and_grandchild_all_have_lenses() {
        #expect(OverrideHost.lens.a.set(.init(a: 1), 3).a == 3)
        #expect(OverrideHost.Manual.lens.b.set(.init(b: 1), 5).b == 5)
        #expect(OverrideHost.Manual.Grandchild.lens.c.set(.init(c: 1), 8).c == 8)
    }
}

// MARK: - Non-recursive drop-in (nested NOT touched)

@ApplyOptics
fileprivate struct NonRec {
    var a: Int
    enum Untouched { case x(Int) }
}

@ApplyOptics
fileprivate enum NonRecEnum { case x(Int) }

@Suite("@ApplyOptics — non-recursive drop-in")
struct ApplyOpticsNonRecursiveTests {
    @Test func struct_gets_lenses_enum_gets_prisms() {
        #expect(NonRec.lens.a.set(.init(a: 1), 4).a == 4)
        #expect(NonRecEnum.prism.x.preview(.x(2)) == 2)
        #expect(conformsToPrismatic(NonRecEnum.self))
    }

    @Test func nested_not_touched_without_recursively() {
        #expect(!conformsToPrismatic(NonRec.Untouched.self))
    }
}
