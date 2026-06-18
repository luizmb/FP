// SPDX-License-Identifier: Apache-2.0
// Literal-expressible conformances. Each delegates to RawValue's literal init.

extension Newtype: ExpressibleByNilLiteral where RawValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.init(RawValue(nilLiteral: ()))
    }
}

extension Newtype: ExpressibleByBooleanLiteral where RawValue: ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = RawValue.BooleanLiteralType
    public init(booleanLiteral value: RawValue.BooleanLiteralType) {
        self.init(RawValue(booleanLiteral: value))
    }
}

extension Newtype: ExpressibleByIntegerLiteral where RawValue: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = RawValue.IntegerLiteralType
    public init(integerLiteral value: RawValue.IntegerLiteralType) {
        self.init(RawValue(integerLiteral: value))
    }
}

extension Newtype: ExpressibleByFloatLiteral where RawValue: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = RawValue.FloatLiteralType
    public init(floatLiteral value: RawValue.FloatLiteralType) {
        self.init(RawValue(floatLiteral: value))
    }
}

extension Newtype: ExpressibleByUnicodeScalarLiteral where RawValue: ExpressibleByUnicodeScalarLiteral {
    public typealias UnicodeScalarLiteralType = RawValue.UnicodeScalarLiteralType
    public init(unicodeScalarLiteral value: RawValue.UnicodeScalarLiteralType) {
        self.init(RawValue(unicodeScalarLiteral: value))
    }
}

extension Newtype: ExpressibleByExtendedGraphemeClusterLiteral where RawValue: ExpressibleByExtendedGraphemeClusterLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = RawValue.ExtendedGraphemeClusterLiteralType
    public init(extendedGraphemeClusterLiteral value: RawValue.ExtendedGraphemeClusterLiteralType) {
        self.init(RawValue(extendedGraphemeClusterLiteral: value))
    }
}

extension Newtype: ExpressibleByStringLiteral where RawValue: ExpressibleByStringLiteral {
    public typealias StringLiteralType = RawValue.StringLiteralType
    public init(stringLiteral value: RawValue.StringLiteralType) {
        self.init(RawValue(stringLiteral: value))
    }
}

extension Newtype: ExpressibleByStringInterpolation where RawValue: ExpressibleByStringInterpolation {
    public typealias StringInterpolation = RawValue.StringInterpolation
    public init(stringInterpolation: RawValue.StringInterpolation) {
        self.init(RawValue(stringInterpolation: stringInterpolation))
    }
}
