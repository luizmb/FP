# Contributing to FP

Thank you for your interest in contributing to FP!

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/FP.git`
3. Install tools: `brew install mint && mint bootstrap`
4. Build: `swift build 2>&1 | xcsift`
5. Test: `swift test 2>&1 | xcsift`

## Branch Naming

| Pattern | Purpose |
|---------|---------|
| `feature/name` | New feature |
| `bugfix/name` | Bug fix |

Never push directly to `main`.

## Before Submitting

- [ ] `mint run swiftformat --lint .` passes (run `--write` to auto-fix)
- [ ] `mint run swiftlint lint --strict` passes
- [ ] `swift test` passes on macOS
- [ ] `mint run periphery scan` passes
- [ ] New public APIs have DocC documentation
- [ ] CHANGELOG.md updated under `## [Unreleased]`

## Code Style

This library follows strict functional programming principles. See the README and CLAUDE.md for detailed guidance on:

- Pure functions (no side effects, inject all ambient state)
- `Result<Success, SpecificFailure>` over `throws`
- Tacit/point-free programming using FP operators
- No force unwraps, no crash functions

## Pull Request Process

1. Open a PR against `main`
2. Fill in the PR template
3. All CI checks must pass
4. At least one maintainer review required

## Licensing

By contributing, you agree your contributions will be licensed under Apache 2.0.
