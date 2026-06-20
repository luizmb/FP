// SPDX-License-Identifier: Apache-2.0
public extension Either {
    /// Declaration.
    func inverted() -> Either<B, A> {
        match(
            caseLeft: Either<B, A>.right,
            caseRight: Either<B, A>.left
        )
    }
}
