// SPDX-License-Identifier: Apache-2.0

enum UsernameError { // no `: Error` needed for Either
    case empty
    case tooShort
}

func parseUsername(_ input: String) -> Either<UsernameError, String> {
    input.isEmpty ? .left(.empty) : .right(input)
}

func validateLength(_ username: String) -> Either<UsernameError, String> {
    username.count >= 3 ? .right(username) : .left(.tooShort)
}

parseUsername("alice") >>- validateLength // .right("alice")
parseUsername("ab") >>- validateLength // .left(.tooShort)
