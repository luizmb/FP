// SPDX-License-Identifier: Apache-2.0

func validateLength(_ input: String) -> Validation<[String], String> {
    input.count >= 3 ? .success(input) : .failure(["Must be at least 3 characters"])
}

func validateNoSpaces(_ input: String) -> Validation<[String], String> {
    input.contains(" ") ? .failure(["Cannot contain spaces"]) : .success(input)
}

Validation.zip(validateLength(" a"), validateNoSpaces(" a"))
// .failure(["Must be at least 3 characters", "Cannot contain spaces"])
