import Foundation

public extension Optional {
    var some: A? { a }
    var none: B? { b } 
    var isSome: Bool { isA }
    var isNone: Bool { isB }
}
