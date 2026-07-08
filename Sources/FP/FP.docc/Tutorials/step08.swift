// SPDX-License-Identifier: Apache-2.0

enum UsernameError {
    case empty
    case tooShort
}

func parseUsername(_ input: String) -> Either<UsernameError, String> {
    input.isEmpty ? .left(.empty) : .right(input)
}

parseUsername("ab").bimap(
    lf: { "Rejected: \($0)" },
    rf: { $0.uppercased() }
)
// .left("Rejected: tooShort")
