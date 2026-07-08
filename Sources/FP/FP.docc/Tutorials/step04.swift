// SPDX-License-Identifier: Apache-2.0

enum UsernameError: Error {
    case empty
    case tooShort
}

func parseUsername(_ input: String) -> Result<String, UsernameError> {
    input.isEmpty ? .failure(.empty) : .success(input)
}

parseUsername("alice") // .success("alice")
parseUsername("") // .failure(.empty)
