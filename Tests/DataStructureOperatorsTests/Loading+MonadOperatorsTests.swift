import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

private enum TestError: Error, Equatable {
    case network
}

private typealias Sut = Loading<Int, TestError>

@Suite("Loading — Monad operators")
struct LoadingMonadOperatorTests {
    @Test func bind_container_left() {
        // (>>-) :: m a -> (a -> m b) -> m b
        let result = Sut.loaded(5) >>- { .loaded($0 * 2) }
        #expect(result == .loaded(10))
    }

    @Test func bind_function_left() {
        // (-<<) :: (a -> m b) -> m a -> m b
        let double: @Sendable (Int) -> Sut = { .loaded($0 * 2) }
        let result = double -<< Sut.loaded(5)
        #expect(result == .loaded(10))
    }

    @Test func bind_idle_passesThrough() {
        let result = Sut.idle >>- { .loaded($0 * 2) }
        #expect(result == .idle)
    }

    @Test func kleisli_leftToRight() {
        // (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
        let f: @Sendable (Int) -> Sut = { .loaded($0 + 1) }
        let g: @Sendable (Int) -> Sut = { .loaded($0 * 10) }
        let fg: @Sendable (Int) -> Sut = f >=> g
        #expect(fg(2) == .loaded(30))
    }

    @Test func kleisli_rightToLeft() {
        // (<=<) :: (b -> m c) -> (a -> m b) -> a -> m c
        let f: @Sendable (Int) -> Sut = { .loaded($0 + 1) }
        let g: @Sendable (Int) -> Sut = { .loaded($0 * 10) }
        let gf: @Sendable (Int) -> Sut = g <=< f
        #expect(gf(2) == .loaded(30))
    }
}
