import Foundation
import FP

@main
struct CLI {
    static func main() {
        learnFunctorOptional().forEach { dump($0) }
    }
}

@SomeBuilder
func learnFunctorOptional() -> [String] {
    let x: Int? = 5
    let none: Int? = nil

    // Named function (curried static)
    Optional<Int>.fmap { $0 * 2 }(x)        // Optional(10)
    Optional<Int>.fmap { $0 * 2 }(none)     // nil

    // Instance method
    x.map { $0 * 2 }                         // Optional(10)
    none.map { $0 * 2 }                      // nil

    // Operators
    { $0 * 2 } <£> x                        ;// Optional(10) — fn left
    { $0 * 2 } <£> none                      // nil
    x <&> { $0 * 2 }                         // Optional(10) — value left
    none <&> { $0 * 2 }                      // nil
    x £> "hello"                             // Optional("hello") — replace
    none £> "hello"                          // nil
    "hello" <£ x                             // Optional("hello") — flipped
    "hello" <£ none                          // nil
}

@resultBuilder
struct SomeBuilder {
    static func buildBlock(_ components: Optional<Any>...) -> [String] {
        components.map {
            "\(String(describing: $0))"
        }
    }
}
