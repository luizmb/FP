extension Comparable {
    /// Constrains `self` to fall inside `range`, clamping to the nearest endpoint when it falls outside.
    ///
    /// Returns `self` if it already lies within `range`; otherwise returns the closest bound.
    ///
    /// ```swift
    /// 5.clamped(to: 0...10)    // 5    (already in range)
    /// (-3).clamped(to: 0...10) // 0    (clamped to lower bound)
    /// 42.clamped(to: 0...10)   // 10   (clamped to upper bound)
    /// 3.5.clamped(to: 0.0...1.0) // 1.0
    /// ```
    public func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }

    /// Returns `true` when `self` falls inside `range` (closed interval).
    ///
    /// Equivalent to `range.contains(self)` and to `range ~= self`, but reads naturally
    /// when the value is the primary subject:
    ///
    /// ```swift
    /// 42.within(40...50)   // true
    /// 42.within(40...42)   // true   (upper bound inclusive)
    /// 42.within(30...41)   // false
    /// ```
    ///
    /// When combined with the symmetric-range operator from `CoreFPOperators`
    /// (requires `Self: Strideable`), this composes nicely:
    ///
    /// ```swift
    /// 41.within(42 ± 2)    // true — 41 falls inside 40...44
    /// ```
    public func within(_ range: ClosedRange<Self>) -> Bool {
        range.contains(self)
    }
}
