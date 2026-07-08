// SPDX-License-Identifier: Apache-2.0

enum UsernameError: Error {
    case empty
    case tooShort
}

func parseUsername(_ input: String) -> Result<String, UsernameError> {
    input.isEmpty ? .failure(.empty) : .success(input)
}

func validateLength(_ username: String) -> Result<String, UsernameError> {
    username.count >= 3 ? .success(username) : .failure(.tooShort)
}

parseUsername("alice") >>- validateLength // .success("alice")
parseUsername("ab") >>- validateLength // .failure(.tooShort)
parseUsername("") >>- validateLength // .failure(.empty)

// Named function, equivalent
parseUsername("ab").flatMap(validateLength) // .failure(.tooShort)
