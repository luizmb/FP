import Testing
import DataStructure
import CoreFP

@Suite struct BifoldableTests {

    // MARK: - Either (via SumType2.bifoldMap)

    @Test func eitherBifoldMapLeft() {
        let e: Either<String, Int> = .left("error")
        #expect(e.bifoldMap(leftBy: { $0.count }, rightBy: { $0 * 2 }) == 5)
    }

    @Test func eitherBifoldMapRight() {
        let e: Either<String, Int> = .right(7)
        #expect(e.bifoldMap(leftBy: { $0.count }, rightBy: { $0 * 2 }) == 14)
    }

    @Test func eitherBifoldMapFreeCurried() {
        let fold: (Either<String, Int>) -> Int = bifoldMap({ $0.count }, { $0 * 2 })
        #expect(fold(.left("hi")) == 2)
        #expect(fold(.right(3)) == 6)
    }

    @Test func eitherBifoldMapToSameType() {
        let values: [Either<String, String>] = [.left("foo"), .right("bar")]
        let fold: (Either<String, String>) -> String = bifoldMap({ $0.uppercased() }, { $0.lowercased() })
        let result = values.map(fold)
        #expect(result == ["FOO", "bar"])
    }

    // MARK: - Validation (instance, static, free curried)

    @Test func validationBifoldMapFailure() {
        let v: Validation<String, Int> = .failure("err")
        #expect(v.bifoldMap({ $0.count }, { $0 * 10 }) == 3)
    }

    @Test func validationBifoldMapSuccess() {
        let v: Validation<String, Int> = .success(4)
        #expect(v.bifoldMap({ $0.count }, { $0 * 10 }) == 40)
    }

    @Test func validationBifoldMapStatic() {
        let fold = Validation<String, Int>.bifoldMap({ $0.count }, { $0 * 10 })
        #expect(fold(.failure("ab")) == 2)
        #expect(fold(.success(5)) == 50)
    }

    @Test func validationBifoldMapFreeCurried() {
        let fold = bifoldMap({ (s: String) in s.count }, { (n: Int) in n * 10 })
        #expect(fold(Validation<String, Int>.failure("xyz")) == 3)
        #expect(fold(Validation<String, Int>.success(2)) == 20)
    }

    @Test func validationBifoldMapCollapsesBothSidesToBool() {
        let isOk = bifoldMap({ (_: String) in false }, { (_: Int) in true })
        #expect(isOk(Validation<String, Int>.failure("e")) == false)
        #expect(isOk(Validation<String, Int>.success(0)) == true)
    }
}
