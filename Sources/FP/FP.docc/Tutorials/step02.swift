// SPDX-License-Identifier: Apache-2.0

func parseUsername(_ input: String) -> String? {
    input.isEmpty ? nil : input
}

let uppercased: @Sendable (String) -> String = { $0.uppercased() }
uppercased <£> parseUsername("alice") // Optional("ALICE")
uppercased <£> parseUsername("") // nil

// Named function, equivalent
parseUsername("alice").map { $0.uppercased() } // Optional("ALICE")
