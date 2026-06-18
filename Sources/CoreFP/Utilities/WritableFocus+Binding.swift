// SPDX-License-Identifier: Apache-2.0
#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI bridge for ``WritableFocus``.
///
/// A ``WritableFocus`` carries `@Sendable` `get`/`set` closures, so it converts **into** a
/// SwiftUI `Binding` cleanly — `Binding`'s `init(get:set:)` imposes no `Sendable` requirement.
///
/// The reverse direction (`Binding` → `WritableFocus`) is intentionally **not** provided here:
/// SwiftUI's `Binding` is not `Sendable`, so wrapping its accessors in the `@Sendable` closures
/// `WritableFocus` requires would discard the very guarantee `WritableFocus` exists to uphold.
/// Construct a `WritableFocus` directly from your storage instead.
public extension Binding {
    /// Bridges a ``WritableFocus`` into a SwiftUI `Binding`, reading and writing through the
    /// focus's `get`/`set`.
    ///
    /// ```swift
    /// let focus = WritableFocus(get: { box.value }, set: { box.value = $0 })
    /// TextField("Name", text: Binding(focus[optic: nameLens]))
    /// ```
    init(_ focus: WritableFocus<Value>) {
        self.init(get: focus.get, set: focus.set)
    }
}
#endif
