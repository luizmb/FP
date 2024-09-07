import FP
import Foundation

public extension Either {
    var left: A? { a }
    var right: B? { b } 
    var isLeft: Bool { isA }
    var isRight: Bool { isB }
}
