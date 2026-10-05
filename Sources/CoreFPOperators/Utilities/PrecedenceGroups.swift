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
//  4.8 RangeFormationPrecedence     (... ..< — stdlib)
//  4.5 CastingPrecedence            (as? — stdlib)
//  4.2 NilCoalescingPrecedence      (?? — stdlib)
//  4   ComparisonPrecedence         (== <= — stdlib) / FunctorOps (<£> £> <£ <*> *> <*)
//  3   LogicalConjunctionPrecedence (&& — stdlib)
//  2   LogicalDisjunctionPrecedence (|| — stdlib)
//  1.5 AlternativePrecedence        (<|>)
//  1   KleisliCompositionRight      (>=> <=< -<< <<-, right-assoc)
//  1   MonadBindLeft                (>>- <&> ->>, left-assoc)
//  0.5 TernaryPrecedence            (?:)
//  0   LowPrecedenceFunctionCallRight (<|, right-assoc)
//  0   LowPrecedenceFunctionCallLeft  (|>, left-assoc)
//  -1  AssignmentPrecedence         (= — stdlib)

// 9: Function composition >>> <<<
// Note: In Haskell, both . and >>> are right-associative (infixr)
// Swift does not order two groups through relations declared in another module (the stdlib), so
// every custom group below is also chained to the next custom group with a same-module `higherThan`.
// That makes the library's groups one total order:
// >>> / <<<  >  <>  >  <£> <*> …  >  <|>  >  >=>  >  >>-  >  <|  >  |>
// Following Haskell's fixities, the stdlib operators that matter in practice (* + ?? == && ||) bind tighter than
// <|>, >=>, >>-, <| and |>, so each of those groups is also declared `lowerThan` each of those stdlib groups
// (the stdlib's own transitive order is not visible from here). The functor family sits below * + ?? but stays
// unordered against == (Haskell rejects that mix).
precedencegroup FunctionCompositionForward {
    associativity: right
    higherThan: FunctionCompositionBackwards
}

precedencegroup FunctionCompositionBackwards {
    associativity: right
    higherThan: BitwiseShiftPrecedence, ConcatPrecedence
}

// 8.5: BitwiseShiftPrecedence >>

// 7: MultiplicationPrecedence * /

// 6: ConcatPrecedence <>
precedencegroup ConcatPrecedence {
    associativity: right
    lowerThan: MultiplicationPrecedence
    higherThan: AdditionPrecedence, FunctorOps
}

// 6: AdditionPrecedence + -

// 4.8: RangeFormationPrecedence ... ..<

// 4.5: CastingPrecedence as?

// 4.2: NilCoalescingPrecedence ??

// 4: ComparisonPrecedence == <=

// 4: Functor/Applicative Ops <£> £> <£ <*> *> <*  (above && and ||, unordered against ==)
// Note: <&> is at precedence 1 (MonadBindLeft), not here

/// Deliberately NOT ordered against ComparisonPrecedence (== <=): Haskell puts <$> <*> and == at the same level
/// (infix 4) and rejects the mix, so we do too.
precedencegroup FunctorOps {
    associativity: left
    lowerThan: MultiplicationPrecedence, AdditionPrecedence, NilCoalescingPrecedence
    higherThan: LogicalConjunctionPrecedence, LogicalDisjunctionPrecedence, AlternativePrecedence
}

// 1.5: Alternative
precedencegroup AlternativePrecedence {
    associativity: left
    lowerThan: MultiplicationPrecedence, AdditionPrecedence, NilCoalescingPrecedence, ComparisonPrecedence,
        LogicalConjunctionPrecedence, LogicalDisjunctionPrecedence
    higherThan: KleisliCompositionRight
}

// 3: LogicalConjunctionPrecedence &&

// 2: LogicalDisjunctionPrecedence ||

// 1: Monadic ops >=> >>- -<<
// In Haskell: >>=, >> are infixl 1 (left-associative)
//             >=>, =<< are infixr 1 (right-associative)

precedencegroup KleisliCompositionRight {
    associativity: right
    lowerThan: MultiplicationPrecedence, AdditionPrecedence, NilCoalescingPrecedence, ComparisonPrecedence,
        LogicalConjunctionPrecedence, LogicalDisjunctionPrecedence
    higherThan: MonadBindLeft
}

precedencegroup MonadBindLeft {
    associativity: left
    lowerThan: MultiplicationPrecedence, AdditionPrecedence, NilCoalescingPrecedence, ComparisonPrecedence,
        LogicalConjunctionPrecedence, LogicalDisjunctionPrecedence
    higherThan: TernaryPrecedence, LowPrecedenceFunctionCallRight
}

// 0.5: TernaryPrecedence ?:

// 0: Function Application $ <|

precedencegroup LowPrecedenceFunctionCallRight {
    associativity: right
    lowerThan: TernaryPrecedence, MultiplicationPrecedence, AdditionPrecedence, NilCoalescingPrecedence, ComparisonPrecedence,
        LogicalConjunctionPrecedence, LogicalDisjunctionPrecedence
    higherThan: LowPrecedenceFunctionCallLeft
}

// 0: Function application |>
precedencegroup LowPrecedenceFunctionCallLeft {
    associativity: left
    lowerThan: MultiplicationPrecedence, AdditionPrecedence, NilCoalescingPrecedence, ComparisonPrecedence,
        LogicalConjunctionPrecedence, LogicalDisjunctionPrecedence
    higherThan: AssignmentPrecedence
}

// -1: AssignmentPrecedence =
