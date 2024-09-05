infix operator ++: AppendToList                     // Haskell Concat/Append
infix operator <>: ConcatPrecedence                 // Haskel sconcat

infix operator <*>: FunctorOps                      // Haskell Applicative Functor Apply
infix operator *>: FunctorOps                       // Haskell Applicative Functor Chain Discarding lhs
infix operator <*: FunctorOps                       // Haskell Applicative Functor Chain Discarding rhs
infix operator <|>: AlternativePrecedence           // Haskell Or/Alternative
infix operator >=>: KleisliCompositionLeft
infix operator >>=: KleisliCompositionLeft          // Haskell Bind
infix operator =<<: KleisliCompositionRight

infix operator ≅: ComparisonPrecedence
infix operator ±: RangeFormationPrecedence
infix operator +/-: RangeFormationPrecedence

/// Haskell pipe/dot . - infixr 9
/// `(>>>) :: (a -> b) -> (b -> c) -> a -> c`
///
/// Left to right function composition.
/// ```haskell
/// (f . g) x = g (f x)
/// f . id = f = id . f
/// ```
///
/// Examples:
/// ```haskell
/// >>> map (length >>> (*2)) [[], [0, 1, 2], [0]]
/// [0,6,2]
/// >>> id (>>>) foldr [(+1), (*3), (^3)] 2
/// 25
/// ```
/// https://hackage.haskell.org/package/base-4.20.0.1/docs/Control-Category.html#v:-62--62--62-
infix operator >>>: FunctionCompositionForward

/// Haskell pipe/dot . - infixr 9
/// `(.) :: (b -> c) -> (a -> b) -> a -> c`
///
/// Right to left function composition.
/// ```haskell
/// (f . g) x = f (g x)
/// f . id = f = id . f
/// ```
///
/// Examples:
/// ```haskell
/// >>> map ((*2) . length) [[], [0, 1, 2], [0]]
/// [0,6,2]
/// >>> foldr (.) id [(+1), (*3), (^3)] 2
/// 25
/// >>> let (...) = (.).(.) in ((*2)...(+)) 5 10
/// 30
/// ```
/// https://hackage.haskell.org/package/base-4.20.0.1/docs/Control-Category.html#v:-60--60--60-
infix operator <<<: FunctionCompositionBackwards

/// Haskell pipe/dot . - infixr 9
/// `(.) :: (b -> c) -> (a -> b) -> a -> c`
///
/// Right to left function composition.
/// ```haskell
/// (f . g) x = f (g x)
/// f . id = f = id . f
/// ```
///
/// Examples:
/// ```haskell
/// >>> map ((*2) . length) [[], [0, 1, 2], [0]]
/// [0,6,2]
/// >>> foldr (.) id [(+1), (*3), (^3)] 2
/// 25
/// >>> let (...) = (.).(.) in ((*2)...(+)) 5 10
/// 30
/// ```
/// https://hackage.haskell.org/package/base-4.20.0.1/docs/Prelude.html#v:.
infix operator •: FunctionCompositionBackwards

/// Haskell $ (parentheses replacement) - infixr 0
/// `($) :: (a -> b) -> a -> b`
///
/// ($) is the function application operator.
/// Applying ($) to a function f and an argument x gives the same result as applying f to x directly. The definition is akin to this:
/// ```haskell
/// ($) :: (a -> b) -> a -> b
/// ($) f x = f x
/// ```
/// On the face of it, this may appear pointless! But it's actually one of the most useful and important operators in Haskell.
/// The order of operations is very different between ($) and normal function application. Normal function application has
/// precedence 10 - higher than any operator - and associates to the left. So these two definitions are equivalent:
/// ```haskell
/// expr = min 5 1 + 5
/// expr = ((min 5) 1) + 5
/// ```
/// ($) has precedence 0 (the lowest) and associates to the right, so these are equivalent:
/// ```haskell
/// expr = min 5 $ 1 + 5
/// expr = (min 5) (1 + 5)
/// ```
///
/// Examples:
/// ```haskell
/// -- From:
/// -- | Sum numbers in a string: strSum "100  5 -7" == 98
/// strSum :: String -> Int
/// strSum s = sum (mapMaybe readMaybe (words s))
/// -- To:
/// -- | Sum numbers in a string: strSum "100  5 -7" == 98
/// strSum :: String -> Int
/// strSum s = sum $ mapMaybe readMaybe $ words s
/// ```
/// https://hackage.haskell.org/package/base-4.20.0.1/docs/Prelude.html#v:-36-
infix operator £: LowPrecedenceFunctionCallRight

/// Haskell $ (parentheses replacement) - infixr 0
/// `($) :: (a -> b) -> a -> b`
///
/// ($) is the function application operator.
/// Applying ($) to a function f and an argument x gives the same result as applying f to x directly. The definition is akin to this:
/// ```haskell
/// ($) :: (a -> b) -> a -> b
/// ($) f x = f x
/// ```
/// On the face of it, this may appear pointless! But it's actually one of the most useful and important operators in Haskell.
/// The order of operations is very different between ($) and normal function application. Normal function application has
/// precedence 10 - higher than any operator - and associates to the left. So these two definitions are equivalent:
/// ```haskell
/// expr = min 5 1 + 5
/// expr = ((min 5) 1) + 5
/// ```
/// ($) has precedence 0 (the lowest) and associates to the right, so these are equivalent:
/// ```haskell
/// expr = min 5 $ 1 + 5
/// expr = (min 5) (1 + 5)
/// ```
///
/// Examples:
/// ```haskell
/// -- From:
/// -- | Sum numbers in a string: strSum "100  5 -7" == 98
/// strSum :: String -> Int
/// strSum s = sum (mapMaybe readMaybe (words s))
/// -- To:
/// -- | Sum numbers in a string: strSum "100  5 -7" == 98
/// strSum :: String -> Int
/// strSum s = sum $ mapMaybe readMaybe $ words s
/// ```
/// https://hackage.haskell.org/package/base-4.20.0.1/docs/Prelude.html#v:-36-
infix operator <|: LowPrecedenceFunctionCallRight

/// Flipped version of Haskell $, or <| - infixl 0
/// `($) :: a -> (a -> b) -> b`
///
/// Low precedence, all the other operations will run first, contrary to regular function application
/// https://hackage.haskell.org/package/base-4.20.0.1/docs/Prelude.html#v:-36-
infix operator |>: LowPrecedenceFunctionCallLeft

/// Haskell <$> (fmap) - infixl 4
/// `(<$>) :: Functor f => (a -> b) -> f a -> f b`
///
/// An infix synonym for fmap.
/// The name of this operator is an allusion to $. Note the similarities between their types:
/// ```haskell
/// ($)   ::              (a -> b) ->   a ->   b
/// (<$>) :: Functor f => (a -> b) -> f a -> f b
/// ```
///
/// Examples:
/// ```haskell
/// >>> show <$> Nothing
/// Nothing
/// >>> show <$> Just 3
/// Just "3"
/// >>> show <$> Left 17
/// Left 17
/// >>> show <$> Right 17
/// Right "17"
/// >>> (*2) <$> [1,2,3]
/// [2,4,6]
/// >>> even <$> (2,2)
/// (2,True)
/// ```
/// https://hackage.haskell.org/package/base-4.20.0.1/docs/Data-Functor.html#v:-60--36--62-
infix operator <£>: FunctorOps

/// Haskell flipped version of <$ - infixl 4
/// `($>) :: Functor f => f a -> b -> f b`
///
/// Examples:
/// ```haskell
/// >>> Nothing $> "foo"
/// Nothing
/// >>> Just 90210 $> "foo"
/// Just "foo"
/// >>> Left 8675309 $> "foo"
/// Left 8675309
/// >>> Right 8675309 $> "foo"
/// Right "foo"
/// >>> [1,2,3] $> "foo"
/// ["foo","foo","foo"]
/// >>> (1,2) $> "foo"
/// (1,"foo")
/// ```
/// https://hackage.haskell.org/package/base-4.20.0.1/docs/Data-Functor.html#v:-36--62-
infix operator £>: FunctorOps

/// Haskell <$ (map-replace-by) - infixl 4
/// `(<$) :: a -> f b -> f a`
///
/// Replace all locations in the input with the same value. The default definition is fmap . const, but this may be overridden with a
/// more efficient version.
///
/// Examples:
/// ```haskell
/// >>> 'a' <$ Just 2
/// Just 'a'
/// >>> 'a' <$ Nothing
/// Nothing
/// ```
/// https://hackage.haskell.org/package/base-4.20.0.1/docs/Data-Functor.html#v:-60--36-
infix operator <£: FunctorOps

/// Haskell flipped version of <$> - infixl 1
/// `(<&>) = flip fmap`
///
/// Examples:
/// ```haskell
/// >>> Just 2 <&> (+1)
/// Just 3
/// >>> [1,2,3] <&> (+1)
/// [2,3,4]
/// >>> Right 3 <&> (+1)
/// Right 4
/// ```
/// https://hackage.haskell.org/package/base-4.20.0.1/docs/Data-Functor.html#v:-60--38--62-
infix operator <&>: KleisliCompositionLeft

/// Raised to the power of ^^ - infixr 8
/// ```swift
/// 2 ^ 3
/// 8
///
/// 3 ^ 2
/// 9
///
/// 5 ^ 3
/// 125
/// ```
infix operator ^: PowerPrecedence

/// Lift operator
/// - keypaths to functions
/// - closure to Func structs
prefix operator ^
