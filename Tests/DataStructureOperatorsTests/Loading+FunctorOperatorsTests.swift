import CoreFP
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

private enum TestError: Error, Equatable {
    case network
}

private typealias Sut = Loading<Int, TestError>

@Suite("Loading — Functor operators")
struct LoadingFunctorOperatorTests {
    @Test func fmap_function_left() {
        // (<£>) :: (a -> b) -> f a -> f b
        let result: Loading<Int, TestError> = { $0 * 2 } <£> Sut.loaded(5)
        #expect(result == .loaded(10))
    }

    @Test func fmap_function_left_passesIdleThrough() {
        let result: Loading<Int, TestError> = { $0 * 2 } <£> Sut.idle
        #expect(result == .idle)
    }

    @Test func fmap_container_left() {
        // (<&>) :: f a -> (a -> b) -> f b
        let result: Loading<Int, TestError> = Sut.loaded(5) <&> { $0 * 2 }
        #expect(result == .loaded(10))
    }

    @Test func replace_container_left() {
        // ($>) :: f a -> b -> f b
        let result: Loading<String, TestError> = Sut.loaded(5) £> "done"
        #expect(result == .loaded("done"))
    }

    @Test func replace_container_left_passesFailureThrough() {
        let result: Loading<String, TestError> = Sut.failed(error: .network, previous: 3) £> "done"
        // Failure still carries through with previous mapped via the constant function.
        #expect(result == .failed(error: .network, previous: "done"))
    }

    @Test func replace_value_left() {
        // (<$) :: b -> f a -> f b
        let result: Loading<String, TestError> = "done" <£ Sut.loaded(5)
        #expect(result == .loaded("done"))
    }
}
