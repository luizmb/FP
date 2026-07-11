# Release Process

This document describes the FP library release process using a Release Candidate (RC) branch pattern.

FP is distributed **exclusively via Swift Package Manager** — consumers depend on the git tag. A GitHub release is created for each version as a human-readable changelog anchor; there are no binary artifacts to build or download.

## Quick Reference

**TL;DR — RC + Promotion Process**:

```bash
# 1. Create a release candidate branch
#    Preferred: Actions → Create Release Candidate → Run workflow → enter version
#    Fallback:  git checkout -b release/1.0.0 && git push origin release/1.0.0

# 2. CI automatically tests the branch on every platform
# → Watch Actions tab for RC build completion

# 3. When ready to promote to release, tag from the branch
#    Preferred: Actions → Promote RC to Release → Run workflow → enter version
#    Fallback:  git tag v1.0.0 && git push origin v1.0.0

# 4. CI automatically creates the GitHub release with auto-generated notes
```

**Benefits of this approach:**
- ✅ Iterate and fix issues without manipulating tags
- ✅ Tests run on the release candidate branch across all supported platforms
- ✅ Only promote when you're confident
- ✅ Clear separation: RC branch vs released version (tag)

## Overview

The release process includes two stages:

### Stage 1: Release Candidate (RC)
- Create `release/X.Y.Z` branch
- Automated testing on the branch (macOS, Linux, Android, Windows)
- Iterate and fix issues without tag manipulation

### Stage 2: Release Promotion
- Create a version tag `vX.Y.Z` from the RC branch
- Tag triggers the final release workflow
- Publishes a GitHub release with auto-generated notes from commits

## Release Workflow

### Stage 1: Create Release Candidate Branch

**When you're ready to prepare a release:**

Go to **Actions → Create Release Candidate → Run workflow** and enter the version number (e.g. `1.0.0`). The workflow bumps the SPM install version across the docs on `main`, then creates and pushes the `release/1.0.0` branch automatically.

Alternatively, create the branch manually:

```bash
git checkout -b release/1.0.0
git push origin release/1.0.0
```

**What happens automatically:**
- GitHub Actions detects the `release/*` branch
- Runs the full test suite on macOS, Linux, Android, and Windows
- Posts a status notification in the workflow

**On the RC branch, you can:**
- Fix bugs discovered during testing
- Update version references
- Polish documentation
- Push commits normally: `git push origin release/1.0.0`

Each push to the RC branch triggers a new CI run across all platforms.

### Stage 2: Promote RC to Release

**When the RC branch is ready:**

Preferred — go to **Actions → Promote RC to Release → Run workflow** and enter the version. The workflow verifies the RC branch exists, that its latest `Release` build succeeded, and that the tag is free, then tags and pushes `vX.Y.Z`.

Fallback — tag manually:

```bash
git checkout release/1.0.0
git tag v1.0.0
git push origin v1.0.0
```

**What happens automatically:**
- GitHub Actions detects the tag
- Verifies the tag format (`vX.Y.Z`)
- Creates a GitHub release with auto-generated release notes
- Posts a completion notification

**No more tag manipulation needed.** If the workflow fails, delete the tag and push a fix to the RC branch:

```bash
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
git push origin release/1.0.0  # push fixes to the RC branch
git tag v1.0.0
git push origin v1.0.0
```

## Consuming a Release

FP is used via Swift Package Manager only — depend on the git tag:

```swift
// In Package.swift
.package(url: "https://github.com/luizmb/FP.git", from: "2.1.0")
```

Then import the products you need:

```swift
import FP
// or
import CoreFP
import DataStructure
// etc.
```

This provides latest updates via SPM's dependency resolution, no build artifacts in your repository, and source-level debugging.

## Products

The package ships these products:

| Product | Purpose |
|-----------|---------|
| `FP` | Umbrella product (re-exports all) |
| `CoreFP` | Core functional programming utilities |
| `CoreFPOperators` | Operator syntax for CoreFP |
| `DataStructure` | Advanced data structures (Either, Reader, etc.) |
| `DataStructureOperators` | Operator syntax for DataStructure |

## Workflow Details

### GitHub Actions Workflow (`release.yml`)

Triggered on `release/*` branches and `v*` tags.

**RC stage** (on `release/*` branches):
- `rc-test` (macOS) — SwiftFormat/SwiftLint checks, build, full test suite, Periphery
- `rc-test-linux` (Ubuntu) — build + test
- `rc-test-android` (Ubuntu) — cross-compiled build + test on an emulator
- `rc-test-windows` (Windows) — build + test
- `rc-notify-status` (Ubuntu) — posts success/failure notification

**Promotion stage** (on `v*` tags):
- `promote-test` (Ubuntu) — validates tag format and checks for a matching RC branch
- `create-release` (Ubuntu) — generates release notes from the commit range and runs `gh release create`
- `notify-promotion-status` (Ubuntu) — posts success/failure notification

Only `rc-test` and the platform-specific legs run on their target OS; everything else (validation, release creation, notifications) runs on Ubuntu.

## Troubleshooting

### RC Build Fails

**Scenario**: You pushed the RC branch but a CI job failed.

**Solution**:
1. Check the Actions tab to see which job failed
2. Review the logs to understand the issue
3. Fix the issue locally
4. Push the fix to the RC branch: `git push origin release/X.Y.Z`
5. CI runs again automatically on the new commit

No tags are involved yet, so iteration is safe and simple.

### Release Promotion Fails After Tag Push

**Scenario**: You created a tag but the promotion workflow failed.

**Solution**:
1. Delete the tag locally and remotely:
   ```bash
   git tag -d vX.Y.Z
   git push origin :refs/tags/vX.Y.Z
   ```
2. Fix the issue on the RC branch:
   ```bash
   git checkout release/X.Y.Z
   # ... make fixes ...
   git push origin release/X.Y.Z
   ```
3. Verify the RC branch builds successfully.
4. Re-create and push the tag:
   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

### Release Not Appearing After Tag Push

**Scenario**: The tag was pushed but the release doesn't appear.

**Debug steps**:
- Go to the Actions tab and check the workflow status
- Verify the tag format is correct: `vX.Y.Z` (semver)
- Check the "Promote - Notify Status" job for error details
- Verify GitHub permissions include release creation (`contents: write`)

## Git Workflow Examples

### Example 1: Create and Publish v1.0.0

```bash
# Create RC branch
# Preferred: Actions → Create Release Candidate → Run workflow → enter "1.0.0"
# Fallback:  git checkout -b release/1.0.0 && git push origin release/1.0.0

# Wait for Actions to run all platform legs...
# Test integration...

# When satisfied, promote to release
# Preferred: Actions → Promote RC to Release → Run workflow → enter "1.0.0"
# Fallback:  git tag v1.0.0 && git push origin v1.0.0

# Monitor Actions for release creation

# Optional: merge back to main
git checkout main
git merge release/1.0.0
git push origin main
```

### Example 2: Fix Issues on RC Before Release

```bash
# You're on release/1.0.0
git commit -am "Fix build issue"
git push origin release/1.0.0

# Wait for the new CI run...
# Once stable, promote as above.
```

### Example 3: Recover from a Failed Tag

```bash
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0

git checkout release/1.0.0
# ... make fixes ...
git push origin release/1.0.0

# Verify CI passes, then retry the tag
git tag v1.0.0
git push origin v1.0.0
```

## Release Checklist

### Before Creating the Release Candidate Branch

- [ ] All tests pass locally: `swift test 2>&1 | xcsift`
- [ ] Code builds without warnings: `swift build 2>&1 | xcsift`
- [ ] SwiftLint passes: `mint run swiftlint lint --strict`
- [ ] Periphery passes: `periphery scan`
- [ ] No uncommitted changes: `git status`
- [ ] Main branch is up to date: `git pull origin main`

### After Creating the RC Branch (`release/X.Y.Z`)

- [ ] Branch created and pushed
- [ ] GitHub Actions workflow started automatically
- [ ] All platform legs (macOS, Linux, Android, Windows) pass
- [ ] Test integration in your projects (optional but recommended)

### Before Promoting to Release (Creating the Tag)

- [ ] RC branch builds are stable
- [ ] No more fixes needed on the RC branch
- [ ] Ready to publish to GitHub Releases
- [ ] Checked that the generated release notes will be accurate

### After Promoting to Release (After Tag Push)

- [ ] Tag is properly formatted: `vX.Y.Z`
- [ ] Release workflow completes successfully
- [ ] GitHub release appears on the Releases page
- [ ] Release notes are accurate
- [ ] (Optional) Merge the RC branch back to main

## CI/CD Files

- **Continuous Integration**: [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)
  - Runs on pull requests and pushes to `main`
  - Build, test, and linting across all platforms

- **Create Release Candidate**: [`.github/workflows/create-rc.yml`](../../.github/workflows/create-rc.yml)
  - Manual workflow dispatch
  - Bumps the install version in docs and creates/pushes the `release/X.Y.Z` branch

- **Promote RC to Release**: [`.github/workflows/promote-rc.yml`](../../.github/workflows/promote-rc.yml)
  - Manual workflow dispatch
  - Verifies the RC and tags `vX.Y.Z`

- **Release Workflow**: [`.github/workflows/release.yml`](../../.github/workflows/release.yml)
  - Runs on `release/*` branches and version tags
  - Tests the RC and creates the GitHub release

## Notes

- Release notes are auto-generated from commit history
- Each release is independent and versioned with a git tag
- Distribution is via SPM only — there are no binary artifacts

## References

- [Swift Package Manager](https://swift.org/package-manager/)
- [Semantic Versioning](https://semver.org/)
