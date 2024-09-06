@testable import Either
import FP
import Operators
import Testing
import Combine

@Test func bimapLeft() async throws {
    let sut = Either<String, Int>.left("subject under test")
    let result = sut.bimap(\.localizedUppercase, curry(*)(2))
    #expect(result == Either<String, Int>.left("SUBJECT UNDER TEST"))
}

@Test func bimapRight() async throws {
    let sut = Either<String, Int>.right(21)
    let result = sut.bimap(\.capitalized, curry(*)(2))

    #expect(result == Either<String, Int>.right(42))
}
