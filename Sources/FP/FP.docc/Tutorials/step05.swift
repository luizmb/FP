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

validateLength("alice") // .success("alice")
validateLength("ab") // .failure(.tooShort)
