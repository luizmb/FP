import Foundation

public extension Result {
    var success: A? { a }
    var failure: B? { b } 
    var isSuccess: Bool { isA }
    var isFailure: Bool { isB }
}
