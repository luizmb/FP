@testable import CoreFP
import Testing

@Suite struct ArrayFunctorTests {
    @Test func fmap() {
        let array = [1, 2, 3]
        let result = Array.fmap({ $0 * 2 })(array)
        #expect(result == [2, 4, 6])
    }

    @Test func mapIsConsistent() {
        let array = [1, 2, 3]
        let transform: @Sendable (Int) -> Int = { $0 * 2 }

        #expect(array.map(transform) == Array.fmap(transform)(array))
    }

    @Test func functorIdentityLaw() {
        // fmap id = id
        let array = [1, 2, 3]

        #expect(Array.fmap(id)(array) == array)
    }

    @Test func functorCompositionLaw() {
        // fmap (f . g) = fmap f . fmap g
        let array = [1, 2, 3]
        let f: @Sendable (Int) -> Int = { $0 * 2 }
        let g: @Sendable (Int) -> Int = { $0 + 1 }

        let left = Array.fmap({ x in f(g(x)) })(array)
        let right = Array.fmap(f)(Array.fmap(g)(array))

        #expect(left == right)
    }
}
