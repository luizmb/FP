import Foundation

public extension SumType2 where B == Never {
    var value: A {
        match(caseLeft: id, caseRight: absurd)
    }

    init(lifting value: A) {
        self = .left(value)
     }
}

public extension SumType2 where A == Never {
    var value: B {
        match(caseLeft: absurd, caseRight: id)
    }

    init(lifting value: B) {
        self = .right(value)
     }
}
