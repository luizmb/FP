import FP

public extension Either {
    func inverted() -> Either<B, A> {
        match(
            caseLeft: Either<B, A>.right,
            caseRight: Either<B, A>.left
        )
    }
}
