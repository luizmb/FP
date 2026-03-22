import Testing
@testable import CoreFP
@testable import CoreFPOperators

@Suite struct FunctionMonadTests {

    // MARK: - Basic Monad Tests

    @Test func basicFlatMap() {
        let f: (Int) -> String = { "\($0)" }
        let transform: (String) -> (Int) -> Int = { str in
            { r in (Int(str) ?? 0) + r }
        }

        let result = flatMap(f, transform)

        // For input 5: f(5) = "5", transform("5")(5) = 5 + 5 = 10
        #expect(result(5) == 10)
        // For input 3: f(3) = "3", transform("3")(3) = 3 + 3 = 6
        #expect(result(3) == 6)
    }

    @Test func curriedFlatMap() {
        let f: (Int) -> Int = { $0 * 2 }
        let transform: (Int) -> (Int) -> String = { x in
            { r in "\(x + r)" }
        }

        let flatMapped = flatMap(transform)
        let result = flatMapped(f)

        // For input 5: f(5) = 10, transform(10)(5) = "10 + 5" = "15"
        #expect(result(5) == "15")
    }

    @Test func basicJoin() {
        let nested: (Int) -> (Int) -> String = { x in
            { r in "\(x + r)" }
        }

        let flattened = join(nested)

        // For input 5: nested(5) = { r in "5 + r" }, nested(5)(5) = "10"
        #expect(flattened(5) == "10")
        #expect(flattened(3) == "6")
    }

    @Test func kleisliComposition() {
        let f: (Int) -> (String) -> Int = { x in
            { r in x + (Int(r) ?? 0) }
        }
        let g: (Int) -> (String) -> String = { y in
            { r in "\(y + (Int(r) ?? 0))" }
        }

        let composed = kleisli(f, g)

        // For input 5 and "10":
        // f(5)("10") = 5 + 10 = 15
        // g(15)("10") = "15 + 10" = "25"
        #expect(composed(5)("10") == "25")
    }

    @Test func basicKleisliReverse() {
        let f: (Int) -> (String) -> Int = { x in
            { r in x + (Int(r) ?? 0) }
        }
        let g: (Int) -> (String) -> String = { y in
            { r in "\(y + (Int(r) ?? 0))" }
        }

        let composed = kleisliReverse(g, f)

        // Should be the same as kleisli(f, g)
        #expect(composed(5)("10") == "25")
    }

    // MARK: - Monad Laws

    @Test func monadLeftIdentityLaw() {
        // return a >>- f == f a
        // For functions: pure a >>- f == f a
        let a = 5
        let f: (Int) -> (String) -> String = { x in
            { r in "\(x + Int(r)!)" }
        }

        let left = pure(a) >>- f
        let right = f(a)

        #expect(left("10") == right("10"))
        #expect(left("3") == right("3"))
    }

    @Test func monadRightIdentityLaw() {
        // m >>- return == m
        // For functions: f >>- pure == f
        let m: (Int) -> String = { "\($0)" }

        let left = m >>- pure
        let right = m

        #expect(left(5) == right(5))
        #expect(left(10) == right(10))
    }

    @Test func monadAssociativityLaw() {
        // (m >>- f) >>- g == m >>- (\x -> f x >>- g)
        let m: (Int) -> Int = { $0 * 2 }
        let f: (Int) -> (Int) -> String = { x in
            { r in "\(x + r)" }
        }
        let g: (String) -> (Int) -> Int = { s in
            { r in (Int(s) ?? 0) + r }
        }

        // Left side: (m >>- f) >>- g
        let left = (m >>- f) >>- g

        // Right side: m >>- (\x -> f x >>- g)
        let right = m >>- { x in f(x) >>- g }

        #expect(left(5) == right(5))
        #expect(left(3) == right(3))
    }

    @Test func kleisliLeftIdentityLaw() {
        // pure >=> f == f
        let f: (Int) -> (String) -> String = { x in
            { r in "\(x + Int(r)!)" }
        }

        let left = pure >=> f
        let right = f

        #expect(left(5)("10") == right(5)("10"))
    }

    @Test func kleisliRightIdentityLaw() {
        // f >=> pure == f
        let f: (Int) -> (String) -> String = { x in
            { r in "\(x + Int(r)!)" }
        }

        let left = f >=> pure
        let right = f

        #expect(left(5)("10") == right(5)("10"))
    }

    @Test func kleisliAssociativityLaw() {
        // (f >=> g) >=> h == f >=> (g >=> h)
        let f: (Int) -> (String) -> Int = { x in
            { r in x + (Int(r) ?? 0) }
        }
        let g: (Int) -> (String) -> String = { y in
            { r in "\(y + (Int(r) ?? 0))" }
        }
        let h: (String) -> (String) -> Int = { s in
            { r in (Int(s) ?? 0) + (Int(r) ?? 0) }
        }

        let left = (f >=> g) >=> h
        let right = f >=> (g >=> h)

        #expect(left(5)("10") == right(5)("10"))
    }

    // MARK: - Monad Operators

    @Test func bindOperator() {
        let f: (Int) -> String = { "\($0)" }
        let transform: (String) -> (Int) -> Int = { str in
            { r in (Int(str) ?? 0) + r }
        }

        let result = f >>- transform

        #expect(result(5) == 10)
        #expect(result(3) == 6)
    }

    @Test func reverseBindOperator() {
        let f: (Int) -> String = { "\($0)" }
        let transform: (String) -> (Int) -> Int = { str in
            { r in (Int(str) ?? 0) + r }
        }

        let result = transform -<< f

        // Should be the same as f >>- transform
        #expect(result(5) == 10)
        #expect(result(3) == 6)
    }

    @Test func kleisliOperator() {
        let f: (Int) -> (String) -> Int = { x in
            { r in x + (Int(r) ?? 0) }
        }
        let g: (Int) -> (String) -> String = { y in
            { r in "\(y + (Int(r) ?? 0))" }
        }

        let composed = f >=> g

        #expect(composed(5)("10") == "25")
    }

    @Test func reverseKleisliOperator() {
        let f: (Int) -> (String) -> Int = { x in
            { r in x + (Int(r) ?? 0) }
        }
        let g: (Int) -> (String) -> String = { y in
            { r in "\(y + (Int(r) ?? 0))" }
        }

        let composed = g <=< f

        #expect(composed(5)("10") == "25")
    }

    @Test func multipleKleisliComposition() {
        let f: (Int) -> (Int) -> Int = { x in { r in x + r } }
        let g: (Int) -> (Int) -> Int = { y in { r in y * r } }
        let h: (Int) -> (Int) -> Int = { z in { r in z - r } }

        let composed = f >=> g >=> h

        // For input 5 with environment 2:
        // f(5)(2) = 5 + 2 = 7
        // g(7)(2) = 7 * 2 = 14
        // h(14)(2) = 14 - 2 = 12
        #expect(composed(5)(2) == 12)
    }

    // MARK: - Practical Examples

    @Test func readerMonadPattern() {
        // Simulate reading from environment and chaining computations
        struct Config {
            let multiplier: Int
            let offset: Int
        }

        let getMultiplier: (Config) -> Int = { $0.multiplier }

        let compute: (Int) -> (Config) -> Int = { mult in
            { config in mult * config.offset }
        }

        let result = getMultiplier >>- compute

        let config = Config(multiplier: 5, offset: 10)
        #expect(result(config) == 50)  // 5 * 10
    }

    @Test func chainedReaderComputations() {
        struct Environment {
            let x: Int
            let y: Int
        }

        let getX: (Environment) -> Int = { $0.x }

        let addY: (Int) -> (Environment) -> Int = { x in
            { env in x + env.y }
        }

        let multiplyByX: (Int) -> (Environment) -> Int = { sum in
            { env in sum * env.x }
        }

        let pipeline = getX >>- addY >>- multiplyByX

        let env = Environment(x: 3, y: 7)
        // getX(env) = 3
        // addY(3)(env) = 3 + 7 = 10
        // multiplyByX(10)(env) = 10 * 3 = 30
        #expect(pipeline(env) == 30)
    }

    @Test func joinPractical() {
        // Flatten a nested computation
        let nestedComputation: (Int) -> (Int) -> Int = { x in
            { r in x * r }
        }

        let flattened = join(nestedComputation)

        // For input 5: flattened(5) = 5 * 5 = 25
        #expect(flattened(5) == 25)
        #expect(flattened(4) == 16)
    }

    @Test func equivalenceWithManualBind() {
        let f: (Int) -> String = { "\($0)" }
        let transform: (String) -> (Int) -> Int = { str in
            { r in (Int(str) ?? 0) + r }
        }

        let viaBind = f >>- transform
        let manual: (Int) -> Int = { r in transform(f(r))(r) }

        #expect(viaBind(5) == manual(5))
        #expect(viaBind(10) == manual(10))
    }

    @Test func flatMapEquivalentToJoinCompose() {
        // flatMap f g == join (fmap f g)
        let f: (Int) -> (Int) -> String = { x in
            { r in "\(x + r)" }
        }
        let g: (Int) -> Int = { $0 * 2 }

        let viaFlatMap = flatMap(g, f)
        let viaJoinFmap = join(fmap(f, g))

        #expect(viaFlatMap(5) == viaJoinFmap(5))
        #expect(viaFlatMap(3) == viaJoinFmap(3))
    }

    @Test func kleisliVsDirectComposition() {
        // Compare Kleisli composition with manual composition
        let f: (Int) -> (String) -> Int = { x in
            { r in x + (Int(r) ?? 0) }
        }
        let g: (Int) -> (String) -> String = { y in
            { r in "\(y + (Int(r) ?? 0))" }
        }

        let viaKleisli = f >=> g
        let manual: (Int) -> (String) -> String = { a in
            { r in g(f(a)(r))(r) }
        }

        #expect(viaKleisli(5)("10") == manual(5)("10"))
    }
}
