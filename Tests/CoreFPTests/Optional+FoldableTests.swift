import Testing
import CoreFP

@Suite struct OptionalFoldableTests {

    // MARK: - fold

    @Test func foldSome() {
        let opt: Int? = 5
        #expect(opt.fold(onNone: 0, onSome: { $0 * 2 }) == 10)
    }

    @Test func foldNone() {
        let opt: Int? = nil
        #expect(opt.fold(onNone: 99, onSome: { $0 * 2 }) == 99)
    }

    @Test func foldCurriedSome() {
        let collapse = Optional<Int>.fold(onNone: 0, onSome: { $0 * 2 })
        #expect(collapse(.some(5)) == 10)
        #expect(collapse(nil) == 0)
    }

    @Test func foldPointFree() {
        let values: [Int?] = [.some(1), nil, .some(3)]
        let result = values.map(Optional<Int>.fold(onNone: 0, onSome: id))
        #expect(result == [1, 0, 3])
    }

    // MARK: - foldMap

    @Test func foldMapSome() {
        let opt: Int? = 3
        #expect(opt.foldMap({ "\($0)" }) == "3")
    }

    @Test func foldMapNoneReturnsIdentity() {
        let opt: Int? = nil
        #expect(opt.foldMap({ "\($0)" }) == "")
    }

    @Test func foldMapCurried() {
        let fn = Optional<Int>.foldMap({ "\($0)" })
        #expect(fn(.some(7)) == "7")
        #expect(fn(nil) == "")
    }

    // MARK: - toList

    @Test func toListSome() {
        let opt: Int? = 42
        #expect(opt.toList == [42])
    }

    @Test func toListNone() {
        let opt: Int? = nil
        #expect(opt.toList == [])
    }

    // MARK: - withDefault

    @Test func withDefaultSome() {
        let opt: Int? = 5
        #expect(withDefault(0)(opt) == 5)
    }

    @Test func withDefaultNone() {
        let opt: Int? = nil
        #expect(withDefault(0)(opt) == 0)
    }

    @Test func withDefaultNullableFallback() {
        let opt: Int? = nil
        let result: Int? = withDefault(42 as Int?)(opt)
        #expect(result == 42)
    }

    @Test func withDefaultPointFree() {
        let fill = withDefault(-1)
        #expect([.some(3), nil, .some(7)].map(fill) == [3, -1, 7])
    }

    // MARK: - then

    @Test func thenSomeRunsClosure() {
        nonisolated(unsafe) var ran = false
        let opt: Int? = 42
        opt.then { _ in ran = true }
        #expect(ran)
    }

    @Test func thenNoneSkipsClosure() {
        nonisolated(unsafe) var ran = false
        let opt: Int? = nil
        opt.then { _ in ran = true }
        #expect(!ran)
    }

    @Test func thenNoneRunsOtherwise() {
        nonisolated(unsafe) var otherwise = false
        let opt: Int? = nil
        opt.then({ _ in }, otherwise: { otherwise = true })
        #expect(otherwise)
    }

    @Test func thenReturnsSelf() {
        let opt: Int? = 42
        let result = opt.then(ignore)
        #expect(result == opt)
    }
}
