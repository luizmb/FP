// https://rosettacode.org/wiki/Operator_precedence
// https://developer.apple.com/documentation/swift/operator-declarations

// 9: Function composition >>> <<<
precedencegroup FunctionCompositionForward {
    associativity: left
    higherThan: FunctionCompositionBackwards
}

precedencegroup FunctionCompositionBackwards {
    associativity: right
    higherThan: BitwiseShiftPrecedence
}

// 8.5: BitwiseShiftPrecedence >>

// 8: Power ^

precedencegroup PowerPrecedence {
    associativity: right
    lowerThan: BitwiseShiftPrecedence
    higherThan: MultiplicationPrecedence
}

// 7: MultiplicationPrecedence * /

// 6: ConcatPrecedence <>
precedencegroup ConcatPrecedence {
    associativity: right
    lowerThan: MultiplicationPrecedence
    higherThan: AdditionPrecedence
}

// 6: AdditionPrecedence + -

// 5: Append to list ++

precedencegroup AppendToList {
    associativity: right
    lowerThan: AdditionPrecedence
    higherThan: RangeFormationPrecedence
}

// 4.8: RangeFormationPrecedence ... ..<

// 4.5: CastingPrecedence as?

// 4.2: NilCoalescingPrecedence ??

// 4: ComparisonPrecedence == <=

// 4: Functor Ops <£> £> <£ <&>

precedencegroup FunctorOps {
    associativity: left
    lowerThan: NilCoalescingPrecedence
    higherThan: AlternativePrecedence
}

// 3: Alternative
precedencegroup AlternativePrecedence {
    associativity: left
    higherThan: LogicalConjunctionPrecedence
}

// 3: LogicalConjunctionPrecedence &&

// 2: LogicalDisjunctionPrecedence ||

// 1: Monadic ops >=> >>= =<<

precedencegroup KleisliCompositionLeft {
    associativity: left
    lowerThan: LogicalDisjunctionPrecedence
    higherThan: KleisliCompositionRight
}

precedencegroup KleisliCompositionRight {
    associativity: right
    higherThan: TernaryPrecedence
}

// 0.5: TernaryPrecedence ?:

// 0: Function Application $ <|

precedencegroup LowPrecedenceFunctionCallRight {
    associativity: right
    lowerThan: TernaryPrecedence
    higherThan: LowPrecedenceFunctionCallLeft
}

// 0: Function application |>
precedencegroup LowPrecedenceFunctionCallLeft {
    associativity: left
    higherThan: AssignmentPrecedence
}


// -1: AssignmentPrecedence =
