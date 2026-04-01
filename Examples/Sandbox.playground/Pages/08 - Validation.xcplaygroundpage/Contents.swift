import FP

// ============================================================
// VALIDATION<E: Semigroup, A>
//
// Validation is like Either but with one crucial difference:
// its Applicative instance ACCUMULATES errors rather than
// short-circuiting on the first. This makes it ideal for
// form validation, config parsing, and any scenario where
// you want to collect all problems at once.
//
// Note: Validation has no Monad instance that accumulates —
// flatMap would need to run the second computation to know
// if it succeeds, which short-circuits. Only the Applicative
// (<*>, liftA2, zip) accumulates.
//
// E must be a Semigroup so that errors can be combined.
// [String] is the simplest choice for multiple error messages.
// ============================================================

// MARK: - Construction & Pattern Matching

// let ok: Validation<[String], Int>  = .success(42)
// let bad: Validation<[String], Int> = .failure(["value is negative"])

// ok.match(caseFailure: { "errors: \($0)" }, caseSuccess: { "ok: \($0)" })  // "ok: 42"
// bad.match(caseFailure: { "errors: \($0)" }, caseSuccess: { "ok: \($0)" }) // "errors: [\"value is negative\"]"


// MARK: - Functor (maps over success, ignores failure)

// let ok: Validation<[String], Int> = .success(5)
// let bad: Validation<[String], Int> = .failure(["bad"])

// --- Named function ---
// Validation<[String], Int>.fmap { $0 * 2 }(ok)    // .success(10)
// Validation<[String], Int>.fmap { $0 * 2 }(bad)   // .failure(["bad"])

// --- Operators ---
// { $0 * 2 } <£> ok                        // .success(10)
// ok <&> { $0 * 2 }                        // .success(10)


// MARK: - Applicative (accumulates ALL errors)
// This is the defining feature of Validation.

// let e1: Validation<[String], Int>    = .failure(["name is empty"])
// let e2: Validation<[String], Int>    = .failure(["age is negative"])
// let e3: Validation<[String], String> = .failure(["email is invalid"])
// let ok1: Validation<[String], Int>   = .success(1)
// let ok2: Validation<[String], Int>   = .success(2)

// --- liftA2: BOTH must succeed; if either fails, ALL errors collected ---
// Validation<[String], Int>.liftA2(+)(ok1, ok2)  // .success(3)
// Validation<[String], Int>.liftA2(+)(e1, ok2)   // .failure(["name is empty"])
// Validation<[String], Int>.liftA2(+)(e1, e2)    // .failure(["name is empty", "age is negative"]) ← ALL errors!

// --- Compare with Either (short-circuits) ---
// Either<[String], Int>.liftA2(+)(Either.left(["name is empty"]), Either.left(["age is negative"]))
// // .left(["name is empty"]) ← only first error!

// --- apply ---
// let fn: Validation<[String], (Int) -> Int> = .success { $0 + 10 }
// Validation<[String], Int>.apply(fn, ok1)  // .success(11)
// Validation<[String], Int>.apply(fn, e1)   // .failure(["name is empty"])

// --- seqRight / seqLeft (still accumulates) ---
// ok1.seqRight(ok2)                         // .success(2)
// e1.seqRight(e2)                           // .failure(["name is empty", "age is negative"])

// --- zip: pair up two validated values ---
// Validation<[String], (Int, Int)>.zip(ok1, ok2)   // .success((1, 2))
// Validation<[String], (Int, Int)>.zip(e1, e2)     // .failure(["name is empty", "age is negative"])

// --- zip3: three fields ---
// Validation<[String], (Int, Int, String)>.zip3(e1, e2, e3)
// // .failure(["name is empty", "age is negative", "email is invalid"])

// --- zip4: four fields ---
// let e4: Validation<[String], Bool> = .failure(["terms not accepted"])
// Validation<[String], (Int, Int, String, Bool)>.zip4(e1, e2, e3, e4)
// // .failure(["name is empty", "age is negative", "email is invalid", "terms not accepted"])


// MARK: - Practical: Form Validation

// struct RegistrationForm {
//     let name: String
//     let age: Int
//     let email: String
// }

// func validateName(_ name: String) -> Validation<[String], String> {
//     name.isEmpty ? .failure(["Name cannot be empty"]) : .success(name)
// }

// func validateAge(_ age: Int) -> Validation<[String], Int> {
//     age >= 18 ? .success(age) : .failure(["Must be 18 or older"])
// }

// func validateEmail(_ email: String) -> Validation<[String], String> {
//     email.contains("@") ? .success(email) : .failure(["Invalid email address"])
// }

// --- Combine all validations, collecting ALL errors ---
// let nameV   = validateName("")
// let ageV    = validateAge(15)
// let emailV  = validateEmail("not-an-email")

// let result = Validation<[String], RegistrationForm>.liftA2(
//     { name in { age in { email in RegistrationForm(name: name, age: age, email: email) } } }
// )
// // More idiomatically with zip3:
// // Validation<[String], (String, Int, String)>.zip3(nameV, ageV, emailV)
// // .failure(["Name cannot be empty", "Must be 18 or older", "Invalid email address"])

// --- All valid ---
// Validation<[String], (String, Int, String)>.zip3(
//     validateName("Alice"),
//     validateAge(25),
//     validateEmail("alice@example.com")
// )
// // .success(("Alice", 25, "alice@example.com"))

//: [Previous](@previous) | [Next](@next)
