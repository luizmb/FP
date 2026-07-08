// SPDX-License-Identifier: Apache-2.0

func parseUsername(_ input: String) -> String? {
    input.isEmpty ? nil : input
}

parseUsername("alice").fold(onNone: "Guest", onSome: { $0 }) // "alice"
parseUsername("").fold(onNone: "Guest", onSome: { $0 }) // "Guest"
