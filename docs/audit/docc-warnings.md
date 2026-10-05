# DocC warnings

Run with `swift package --disable-sandbox generate-documentation --target <T>` (swift-docc-plugin 1.5.0 is available).

Paths shown as DocC prints them (relative to the target's source directory when starting with `../`).

## Totals

- Total warnings: 53
- FP: 0
- CoreFP: 14
- DataStructure: 31
- CoreFPOperators: 7
- DataStructureOperators: 0
- FPMacros: 1

- unresolved symbol link: 46
- ambiguous or bad disambiguation suffix: 7

## By file (most affected first)

| Target | File | Warnings |
|---|---|---|
| DataStructure | IdentifiedArray/IdentifiedArray+Optics.swift | 8 |
| CoreFPOperators | Function/FunctionComposition.swift | 6 |
| DataStructure | Writer/Writer.swift | 5 |
| DataStructure | NonEmpty/NonEmpty.swift | 4 |
| DataStructure | Reader/Reader.swift | 4 |
| DataStructure | Validation/Validation.swift | 3 |
| CoreFP | Function/FunctionWrapper.swift | 2 |
| CoreFP | SumType/SumType.swift | 2 |
| DataStructure | Either/Either.swift | 2 |
| DataStructure | Newtype/Newtype.swift | 2 |
| CoreFP | Monoid/Monoid+Utilities.swift | 1 |
| CoreFP | Monoid/Monoid.swift | 1 |
| CoreFP | Utilities/AffineTraversal.swift | 1 |
| CoreFP | Utilities/Fanout.swift | 1 |
| CoreFP | Utilities/IndexedTraversal.swift | 1 |
| CoreFP | Utilities/Iso.swift | 1 |
| CoreFP | Utilities/JoinVoid.swift | 1 |
| CoreFP | Utilities/Lens.swift | 1 |
| CoreFP | Utilities/Prism.swift | 1 |
| CoreFP | Utilities/Traversal.swift | 1 |
| DataStructure | Either/Either+Result.swift | 1 |
| DataStructure | Stateful/Stateful.swift | 1 |
| DataStructure | These/These.swift | 1 |
| CoreFPOperators | CoreFPOperators.md | 1 |
| FPMacros | Sources/FPMacros/Mock.swift | 1 |

## Details

### CoreFP: Function/FunctionWrapper.swift (2)

- `../Function/FunctionWrapper.swift:9`: 'Reader' doesn't exist at '/CoreFP/FunctionWrapper'
- `../Function/FunctionWrapper.swift:19`: 'Reader' doesn't exist at '/CoreFP/FunctionWrapper'

### CoreFP: Monoid/Monoid+Utilities.swift (1)

- `../Monoid/Monoid+Utilities.swift:10`: 'NonEmpty' doesn't exist at '/CoreFP/sconcat(_:_:)'

### CoreFP: Monoid/Monoid.swift (1)

- `../Monoid/Monoid.swift:19`: 'NonEmpty' doesn't exist at '/CoreFP/Monoid'

### CoreFP: SumType/SumType.swift (2)

- `../SumType/SumType.swift:4`: 'Either' doesn't exist at '/CoreFP/SumType2'
- `../SumType/SumType.swift:34`: 'Either' doesn't exist at '/CoreFP/SumType2'

### CoreFP: Utilities/AffineTraversal.swift (1)

- `../Utilities/AffineTraversal.swift:88`: 'compose(_:)-affinetraversal-lens' doesn't exist at '/CoreFP/AffineTraversal'

### CoreFP: Utilities/Fanout.swift (1)

- `../Utilities/Fanout.swift:32`: 'tuple' isn't a disambiguation for 'fanout(_:)' at '/CoreFP'

### CoreFP: Utilities/IndexedTraversal.swift (1)

- `../Utilities/IndexedTraversal.swift:27`: 'eachIndexed' doesn't exist at '/CoreFP/Swift/Array'

### CoreFP: Utilities/Iso.swift (1)

- `../Utilities/Iso.swift:44`: 'mconcat' doesn't exist at '/CoreFP/Iso'

### CoreFP: Utilities/JoinVoid.swift (1)

- `../Utilities/JoinVoid.swift:20`: 'Array' doesn't exist at '/CoreFP/join(_:)'

### CoreFP: Utilities/Lens.swift (1)

- `../Utilities/Lens.swift:96`: 'lens' isn't a disambiguation for 'compose(_:)' at '/CoreFP/Lens'

### CoreFP: Utilities/Prism.swift (1)

- `../Utilities/Prism.swift:75`: 'prism' isn't a disambiguation for 'compose(_:)' at '/CoreFP/Prism'

### CoreFP: Utilities/Traversal.swift (1)

- `../Utilities/Traversal.swift:44`: 'each' doesn't exist at '/CoreFP/Swift/Array'

### CoreFPOperators: CoreFPOperators.md (1)

- `CoreFPOperators.md:141`: '^(_:_:)' doesn't exist at '/CoreFPOperators'

### CoreFPOperators: Function/FunctionComposition.swift (6)

- `../Function/FunctionComposition.swift:12`: 'compose(_:_:)' doesn't exist at '/CoreFPOperators/>>>(_:_:)'
- `../Function/FunctionComposition.swift:42`: 'compose(_:_:)' doesn't exist at '/CoreFPOperators/<<<(_:_:)'
- `../Function/FunctionComposition.swift:63`: 'fanout(_:)' doesn't exist at '/CoreFPOperators/>>>(_:_:)'
- `../Function/FunctionComposition.swift:84`: 'fanout' isn't a disambiguation for '>>>(_:_:)' at '/CoreFPOperators'
- `../Function/FunctionComposition.swift:99`: 'call(_:_:)' doesn't exist at '/CoreFPOperators/<|(_:_:)'
- `../Function/FunctionComposition.swift:122`: 'apply(_:_:)-value-fn' doesn't exist at '/CoreFPOperators/|>(_:_:)'

### DataStructure: Either/Either+Result.swift (1)

- `../Either/Either+Result.swift:20`: 'SumTypeCopyStrategy' doesn't exist at '/DataStructure/Swift/Result/either'

### DataStructure: Either/Either.swift (2)

- `../Either/Either.swift:20`: 'Semigroup' doesn't exist at '/DataStructure/Either'
- `../Either/Either.swift:67`: 'SumType2' doesn't exist at '/DataStructure/Either'

### DataStructure: IdentifiedArray/IdentifiedArray+Optics.swift (8)

- `../IdentifiedArray/IdentifiedArray+Optics.swift:16`: 'AffineTraversal' doesn't exist at '/DataStructure/IdentifiedArray/ix(id:)'
- `../IdentifiedArray/IdentifiedArray+Optics.swift:48`: 'AffineTraversal' doesn't exist at '/DataStructure/IdentifiedArray/ix(_:)'
- `../IdentifiedArray/IdentifiedArray+Optics.swift:74`: 'Traversal' doesn't exist at '/DataStructure/IdentifiedArray/traversed'
- `../IdentifiedArray/IdentifiedArray+Optics.swift:91`: 'Traversal' doesn't exist at '/DataStructure/IdentifiedArray/traversed(where:)'
- `../IdentifiedArray/IdentifiedArray+Optics.swift:111`: 'Iso' doesn't exist at '/DataStructure/IdentifiedArray/arrayIso(id:)'
- `../IdentifiedArray/IdentifiedArray+Optics.swift:119`: 'Prism' doesn't exist at '/DataStructure/IdentifiedArray/arrayIso(id:)'
- `../IdentifiedArray/IdentifiedArray+Optics.swift:127`: 'Prism' doesn't exist at '/DataStructure/IdentifiedArray/dedupPrism(id:)'
- `../IdentifiedArray/IdentifiedArray+Optics.swift:140`: 'Iso' doesn't exist at '/DataStructure/IdentifiedArray/orderedDictionaryIso(id:)'

### DataStructure: Newtype/Newtype.swift (2)

- `../Newtype/Newtype.swift:53`: 'Semigroup' doesn't exist at '/DataStructure/Newtype'
- `../Newtype/Newtype.swift:53`: 'Monoid' doesn't exist at '/DataStructure/Newtype'

### DataStructure: NonEmpty/NonEmpty.swift (4)

- `../NonEmpty/NonEmpty.swift:16`: 'Semigroup' doesn't exist at '/DataStructure/NonEmpty'
- `../NonEmpty/NonEmpty.swift:17`: 'Monoid' doesn't exist at '/DataStructure/NonEmpty'
- `../NonEmpty/NonEmpty.swift:20`: 'mconcat(_:)' doesn't exist at '/DataStructure/NonEmpty'
- `../NonEmpty/NonEmpty.swift:68`: 'Semigroup' doesn't exist at '/DataStructure/NonEmpty'

### DataStructure: Reader/Reader.swift (4)

- `../Reader/Reader.swift:56`: 'contramapEnvironment(_:)' is ambiguous at '/DataStructure/Reader'
- `../Reader/Reader.swift:66`: 'Monoid' doesn't exist at '/DataStructure/Reader'
- `../Reader/Reader.swift:68`: 'extend(_:)' is ambiguous at '/DataStructure/Reader'
- `../Reader/Reader.swift:81`: 'FunctionWrapper' doesn't exist at '/DataStructure/Reader'

### DataStructure: Stateful/Stateful.swift (1)

- `../Stateful/Stateful.swift:63`: 'EndoMut' doesn't exist at '/DataStructure/Stateful'

### DataStructure: These/These.swift (1)

- `../These/These.swift:66`: 'Semigroup' doesn't exist at '/DataStructure/These'

### DataStructure: Validation/Validation.swift (3)

- `../Validation/Validation.swift:8`: 'Semigroup' doesn't exist at '/DataStructure/Validation'
- `../Validation/Validation.swift:56`: 'Semigroup' doesn't exist at '/DataStructure/Validation'
- `../Validation/Validation.swift:68`: 'Semigroup' doesn't exist at '/DataStructure/Validation'

### DataStructure: Writer/Writer.swift (5)

- `../Writer/Writer.swift:8`: 'Monoid' doesn't exist at '/DataStructure/Writer'
- `../Writer/Writer.swift:9`: 'Semigroup' doesn't exist at '/DataStructure/Writer'
- `../Writer/Writer.swift:19`: 'Monoid' doesn't exist at '/DataStructure/Writer'
- `../Writer/Writer.swift:56`: 'extend(_:)' is ambiguous at '/DataStructure/Writer'
- `../Writer/Writer.swift:69`: 'Monoid' doesn't exist at '/DataStructure/Writer'

### FPMacros: Sources/FPMacros/Mock.swift (1)

- `Sources/FPMacros/Mock.swift:8`: 'fail(_:file:line:)' doesn't exist at '/FPMacros/Mock()'
