// SPDX-License-Identifier: Apache-2.0

enum UsernameError: Error {
    case tooShort
    case hasSpaces
}

func validateLength(_ input: String) -> Result<String, UsernameError> {
    input.count >= 3 ? .success(input) : .failure(.tooShort)
}

func validateNoSpaces(_ input: String) -> Result<String, UsernameError> {
    input.contains(" ") ? .failure(.hasSpaces) : .success(input)
}

Result.success(" a") >>- validateLength >>- validateNoSpaces
// .failure(.tooShort)
