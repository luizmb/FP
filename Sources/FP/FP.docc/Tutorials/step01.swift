// SPDX-License-Identifier: Apache-2.0

func parseUsername(_ input: String) -> String? {
    input.isEmpty ? nil : input
}

parseUsername("alice") // Optional("alice")
parseUsername("") // nil
