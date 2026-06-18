// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

// Hand-rolled `Prismatic` conformance + plain structs, so these tests exercise the
// `AffineFocus` / mixed `\.field.case` mechanism independently of the `@Prisms` macro.

private enum Role: Equatable, Sendable {
    case admin(Int) // permission level
    case guest
}

extension Role: Prismatic {
    struct Prisms: Sendable {
        let admin = Prism<Role, Int>(
            preview: { if case let .admin(value) = $0 { value } else { nil } },
            review: Role.admin
        )
        let guest = Prism<Role, Void>(
            preview: { if case .guest = $0 { () } else { nil } },
            review: const(Role.guest)
        )
    }

    static let prism = Prisms()
}

private struct User: Equatable, Sendable {
    var name: String
    var role: Role
}

private struct App: Equatable, Sendable {
    var user: User
}

@Suite(#"AffineFocus / mixed \.field.case key paths"#)
struct AffineFocusTests {
    private let app = App(user: User(name: "Alice", role: .admin(3)))
    private let guestApp = App(user: User(name: "Bob", role: .guest))

    @Test func structOnlyPathReadsAndWrites() {
        // \.user.name threads two struct fields → an always-present focus.
        let at = AffineTraversal(\.user.name as AffineKeyPath<App, String>)
        #expect(at.preview(app) == "Alice")
        #expect(at.set(app, "Carol") == App(user: User(name: "Carol", role: .admin(3))))
        #expect(at.over { $0.uppercased() }(app).user.name == "ALICE")
    }

    @Test func mixedPathPreviewsThroughCase() {
        // \.user.role.admin drills struct → struct → enum case.
        let at = AffineTraversal(\.user.role.admin as AffineKeyPath<App, Int>)
        #expect(at.preview(app) == 3)
        #expect(at.preview(guestApp) == nil)
    }

    @Test func mixedPathOverIsAffine() {
        // `over` (via tryModifyMut) is a no-op when the focused case is absent.
        let at = AffineTraversal(\.user.role.admin as AffineKeyPath<App, Int>)
        #expect(at.over { $0 + 10 }(app) == App(user: User(name: "Alice", role: .admin(13))))
        #expect(at.over { $0 + 10 }(guestApp) == guestApp) // guest → untouched
    }

    @Test func recoveredTraversalMatchesManualComposition() {
        let viaKeyPath = AffineTraversal(\.user.role.admin as AffineKeyPath<App, Int>)
        let manual = lens(\App.user).compose(lens(\User.role)).compose(Role.prism.admin)
        #expect(viaKeyPath.preview(app) == manual.preview(app))
        #expect(viaKeyPath.over { $0 * 2 }(app) == manual.over { $0 * 2 }(app))
    }
}
