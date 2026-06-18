import FP

// ============================================================
// VALIDATION<E: Semigroup, A>
//
// Like Either, but apply/liftA2 ACCUMULATE errors instead of
// short-circuiting on the first. E must be a Semigroup so
// errors can be merged. Use [String] for multiple messages.
//
// Note: No Monad instance that accumulates — flatMap would
// need to run the second step to know if it succeeds, so it
// inherently short-circuits. Only the Applicative accumulates.
// ============================================================

// MARK: - Construction & Pattern Matching

func validationConstruction() {
    let ok: Validation<[String], Int> = .success(42)
    let bad: Validation<[String], Int> = .failure(["value is negative"])

    ok.match(caseFailure: { "errors: \($0)" }, caseSuccess: { "ok: \($0)" }) // "ok: 42"
    bad.match(caseFailure: { "errors: \($0)" }, caseSuccess: { "ok: \($0)" }) // "errors: [...]"
}

// learn(validationConstruction)

// MARK: - Functor

func validationFunctor() {
    let ok: Validation<[String], Int> = .success(5)
    let bad: Validation<[String], Int> = .failure(["bad"])

    Validation<[String], Int>.fmap { $0 * 2 }(ok) // success(10)
    Validation<[String], Int>.fmap { $0 * 2 }(bad) // failure(["bad"])
    _ = { $0 * 2 } <£> ok // success(10)
    _ = { $0 * 2 } <£> bad // failure(["bad"])
    ok <&> { $0 * 2 } // success(10)
    bad <&> { $0 * 2 } // failure(["bad"])
}

// learn(validationFunctor)

// MARK: - Applicative (accumulates ALL errors)

func validationApplicative() {
    let ok1: Validation<[String], Int> = .success(3)
    let ok2: Validation<[String], Int> = .success(4)
    let e1: Validation<[String], Int> = .failure(["name empty"])
    let e2: Validation<[String], Int> = .failure(["age negative"])

    // liftA2 — collects ALL failures
    Validation<[String], Int>.liftA2(+)(ok1, ok2) // success(7)
    Validation<[String], Int>.liftA2(+)(e1, ok2) // failure(["name empty"])
    Validation<[String], Int>.liftA2(+)(e1, e2)
    // failure(["name empty", "age negative"]) ← BOTH

    // Compare: Either short-circuits
    Either<[String], Int>.liftA2(+)(.left(["name empty"]), .left(["age negative"]))
    // left(["name empty"]) ← only first!

    // seqRight — accumulates errors, returns right value
    e1.seqRight(e2)
    // failure(["name empty", "age negative"]) ← BOTH even when discarding values
}

// learn(validationApplicative)

// MARK: - zip variants

func validationZip() {
    let ok1: Validation<[String], Int> = .success(1)
    let ok2: Validation<[String], Int> = .success(2)
    let e1: Validation<[String], Int> = .failure(["field A"])
    let e2: Validation<[String], Int> = .failure(["field B"])
    let e3: Validation<[String], String> = .failure(["field C"])

    // zip
    Validation<[String], (Int, Int)>.zip(ok1, ok2) // success((1, 2))
    Validation<[String], (Int, Int)>.zip(e1, e2) // failure(["field A", "field B"])

    // zip3
    Validation<[String], (Int, Int, String)>.zip3(e1, e2, e3)
    // failure(["field A", "field B", "field C"])
}

// learn(validationZip)

// MARK: - Practical: form validation

func validationForm() {
    func validateName(_ s: String) -> Validation<[String], String> {
        s.isEmpty ? .failure(["Name cannot be empty"]) : .success(s)
    }
    func validateAge(_ n: Int) -> Validation<[String], Int> {
        n >= 18 ? .success(n) : .failure(["Must be 18 or older"])
    }
    func validateEmail(_ s: String) -> Validation<[String], String> {
        s.contains("@") ? .success(s) : .failure(["Invalid email"])
    }

    // All valid
    Validation<[String], (String, Int, String)>.zip3(
        validateName("Alice"), validateAge(25), validateEmail("alice@example.com")
    )
    // success(("Alice", 25, "alice@example.com"))

    // All invalid — all three errors collected at once
    Validation<[String], (String, Int, String)>.zip3(
        validateName(""), validateAge(15), validateEmail("not-an-email")
    )
    // failure(["Name cannot be empty", "Must be 18 or older", "Invalid email"])
}

// learn(validationForm)

//: [Previous](@previous) | [Next](@next)
