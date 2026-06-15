import CoreFP
import Testing

// A reference cell stands in for "external storage" the focus reads/writes through.
private final class Box<A>: @unchecked Sendable {
    var value: A
    init(_ value: A) { self.value = value }
}

private enum Sheet: Equatable, Sendable {
    case settings(Int)
    case profile(String)
}

extension Sheet: Prismatic {
    struct Prisms: Sendable {
        let settings = Prism<Sheet, Int>(
            preview: { if case .settings(let value) = $0 { value } else { nil } },
            review: Sheet.settings
        )
        let profile = Prism<Sheet, String>(
            preview: { if case .profile(let value) = $0 { value } else { nil } },
            review: Sheet.profile
        )
    }
    static let prism = Prisms()
}

private struct Form: Equatable, Sendable {
    var title: String
    var sheet: Sheet
}

@Suite("WritableFocus")
struct WritableFocusTests {
    private func focus<A>(_ box: Box<A>) -> WritableFocus<A> {
        WritableFocus(get: { box.value }, set: { box.value = $0 })
    }

    @Test func wrappedValueReadsAndWrites() {
        let box = Box(42)
        let f = focus(box)
        #expect(f.wrappedValue == 42)
        f.wrappedValue = 99
        #expect(box.value == 99)
    }

    @Test func structFieldNavigationWritesLive() {
        let box = Box(Form(title: "Hi", sheet: .settings(1)))
        let f = focus(box)
        f.title.wrappedValue = "Bye"
        #expect(box.value.title == "Bye")
        #expect(box.value.sheet == .settings(1)) // siblings untouched
    }

    @Test func lensProjection() {
        let box = Box(Form(title: "Hi", sheet: .settings(1)))
        let titleFocus = focus(box)[optic: lens(\Form.title)]
        titleFocus.wrappedValue = "Edited"
        #expect(box.value.title == "Edited")
    }

    @Test func prismProjectionPresent() {
        let box = Box(Sheet.settings(1))
        let inner = focus(box)[optic: Sheet.prism.settings]
        #expect(inner != nil)
        inner?.wrappedValue = 5
        #expect(box.value == .settings(5))
    }

    @Test func prismProjectionAbsentIsNil() {
        let box = Box(Sheet.profile("p"))
        let inner = focus(box)[optic: Sheet.prism.settings]
        #expect(inner == nil)
    }

    @Test func affineTraversalProjection() {
        let box = Box(Form(title: "Hi", sheet: .settings(7)))
        let at = AffineTraversal(\.sheet.settings as AffineKeyPath<Form, Int>)
        let inner = focus(box)[optic: at]
        #expect(inner?.wrappedValue == 7)
        inner?.wrappedValue = 8
        #expect(box.value.sheet == .settings(8))
    }
}
