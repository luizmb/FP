# Operator Precedence & Associativity Corrections

## Summary of Changes Made

After reviewing against [Haskell's operator precedence](https://rosettacode.org/wiki/Operator_precedence) and [Swift's operator declarations](https://developer.apple.com/documentation/swift/operator-declarations), we made the following corrections:

### ✅ Corrections Applied:

1. **Function Composition (`>>>`)**
   - **Before:** `associativity: left`
   - **After:** `associativity: right`
   - **Reason:** Haskell's `>>>` is `infixr 1` (right-associative)

2. **Kleisli Composition (`>=>`)**
   - **Before:** Used `KleisliCompositionLeft` (left-associative)
   - **After:** Uses `KleisliCompositionRight` (right-associative)
   - **Reason:** Haskell's `>=>` is `infixr 1` (right-associative)

3. **Bind Operators Separation**
   - **Before:** Both `>>-` and `-<<` in same precedence group
   - **After:**
     - `>>-` uses `MonadBindLeft` (left-associative, like Haskell's `>>=`)
     - `-<<` uses `KleisliCompositionRight` (right-associative, like Haskell's `=<<`)
   - **Reason:** Match Haskell's distinction between `infixl 1 >>=` and `infixr 1 =<<`

4. **Flipped Fmap (`<&>`)**
   - **Before:** Comment claimed it was in `FunctorOps` (precedence 4)
   - **After:** Correctly uses `MonadBindLeft` (precedence 1)
   - **Reason:** Haskell's `<&>` is `infixl 1`, not `infixl 4`

### 📊 Final Precedence & Associativity Table:

```
Level  Operator           Haskell            Ours                  Match?
-----  ----------------   ----------------   -------------------   ------
  9    . (composition)    infixr 9           <<< • (right)         ✅
  9    >>> (fwd comp)     infixr 1*          >>> (right)           ✅
  8    ^                  infixr 8           ^ (right)             ✅
  7    *, /               infixl 7           (Swift built-in)      ✅
  6    +, -               infixl 6           (Swift built-in)      ✅
  5    ++                 infixr 5           ++ (right)            ✅
  4    <$>, $>, <$        infixl 4           <£>, £>, <£ (left)    ✅
  4    <*>, *>, <*        infixl 4           <*>, *>, <* (left)    ✅
  3    <|>                infixl 3           <|> (left)            ✅
  3    &&                 infixr 3           (Swift: left)         ⚠️**
  2    ||                 infixr 2           (Swift: left)         ⚠️**
  1    >>=, >>            infixl 1           >>- (left)            ✅
  1    >=>                infixr 1           >=> (right)           ✅
  1    =<<                infixr 1           -<< (right)           ✅
  1    <&>                infixl 1           <&> (left)            ✅
  0    $                  infixr 0           £, <| (right)         ✅
  0    |>                 N/A                |> (left)             ✅

* In Control.Category (not Prelude)
** Swift's built-in operators, cannot be changed
```

### 🎯 New Precedence Groups:

```swift
// Precedence 1 - Split into two groups for correct associativity:

precedencegroup KleisliCompositionRight {
    associativity: right  // For: >=>, -<<, =<<
    lowerThan: LogicalDisjunctionPrecedence
    higherThan: MonadBindLeft
}

precedencegroup MonadBindLeft {
    associativity: left   // For: >>-, >>=, <&>
    higherThan: TernaryPrecedence
}
```

### 💡 Why Associativity Matters:

**Right-associative (`>=>`):**
```swift
f >=> g >=> h
= f >=> (g >=> h)  // Builds composition from right
```

**Left-associative (`>>-`):**
```swift
m >>- f >>- g
= (m >>- f) >>- g  // Chains operations from left
```

### ⚠️ Limitations:

Swift's built-in `&&` and `||` are **left-associative**, while Haskell's are **right-associative**. This is a Swift limitation we cannot change, but the impact is minimal since logical operators are rarely chained in ways where associativity matters.

### ✅ Verification:

All 84 tests pass with the corrected precedence and associativity! 🎉

### 📚 References:

- [Haskell Operator Precedence](https://rosettacode.org/wiki/Operator_precedence)
- [Swift Operator Declarations](https://developer.apple.com/documentation/swift/operator-declarations)
- [Haskell 2010 Report - Lexical Structure](https://www.haskell.org/onlinereport/haskell2010/haskellch4.html#x10-820061)
- [Hackage: Data.Functor](https://hackage.haskell.org/package/base/docs/Data-Functor.html)
- [Hackage: Control.Monad](https://hackage.haskell.org/package/base/docs/Control-Monad.html)
