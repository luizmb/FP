// SPDX-License-Identifier: Apache-2.0
// https://rosettacode.org/wiki/Operator_precedence
// https://developer.apple.com/documentation/swift/operator-declarations

// MARK: - Precedence group hierarchy

//
// This file defines all custom precedence groups used across CoreFPOperators,
// DataStructureOperators, and their dependents.
//
// Precedence (highest to lowest), with Swift stdlib groups for reference:
//
//  9   FunctionCompositionForward  (>>>, right-assoc)
//  9   FunctionCompositionBackwards (<<<, right-assoc)
//  8.5 BitwiseShiftPrecedence       (>> — stdlib)
//  7   MultiplicationPrecedence     (* / — stdlib)
//  6   ConcatPrecedence             (<>, right-assoc)
//  6   AdditionPrecedence           (+ - — stdlib)
//  5   AppendToList                 (++, right-assoc)
//  4.8 RangeFormationPrecedence     (... ..< — stdlib)
//  4.5 CastingPrecedence            (as? — stdlib)
//  4.2 NilCoalescingPrecedence      (?? — stdlib)
//  4   ComparisonPrecedence         (== <= — stdlib) / FunctorOps (<£> £> <£ <*> *> <*)
//  3   AlternativePrecedence        (<|>)
//  3   LogicalConjunctionPrecedence (&& — stdlib)
//  2   LogicalDisjunctionPrecedence (|| — stdlib)
//  1   KleisliCompositionRight      (>=> <=< -<< <<-, right-assoc)
//  1   MonadBindLeft                (>>- <&> ->>, left-assoc)
//  0.5 TernaryPrecedence            (?:)
//  0   LowPrecedenceFunctionCallRight (£ <|, right-assoc)
//  0   LowPrecedenceFunctionCallLeft  (|>, left-assoc)
//  -1  AssignmentPrecedence         (= — stdlib)

// 9: Function composition >>> <<<
// Note: In Haskell, both . and >>> are right-associative (infixr)
precedencegroup FunctionCompositionForward {
    associativity: right
    higherThan: FunctionCompositionBackwards
}

precedencegroup FunctionCompositionBackwards {
    associativity: right
    higherThan: BitwiseShiftPrecedence
}

// 8.5: BitwiseShiftPrecedence >>

// 8: Swift stdlib `^` uses BitwiseXorPrecedence (same level as bitwise XOR).
// We cannot declare a separate PowerPrecedence for `^` because the stdlib already
// declares `infix operator ^: BitwiseXorPrecedence` — having two declarations
// with different precedences causes an "ambiguous operator declarations" error.

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

// 4: Functor/Applicative Ops <£> £> <£ <*> *> <*
// Note: <&> is at precedence 1 (KleisliCompositionLeft), not here

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

// 1: Monadic ops >=> >>- -<<
// In Haskell: >>=, >> are infixl 1 (left-associative)
//             >=>, =<< are infixr 1 (right-associative)

precedencegroup KleisliCompositionRight {
    associativity: right
    lowerThan: LogicalDisjunctionPrecedence
    higherThan: MonadBindLeft
}

precedencegroup MonadBindLeft {
    associativity: left
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
