# Release Process

This document describes the FP library release process using a Release Candidate (RC) branch pattern.

## Quick Reference

**TL;DR - RC + Promotion Process**:

```bash
# 1. Create a release candidate branch
#    Preferred: Actions → Create Release Candidate → Run workflow → enter version
#    Fallback:  git checkout -b release/1.0.0 && git push origin release/1.0.0

# 2. CI automatically builds and tests on the branch
# → Watch Actions tab for RC build completion

# 3. When ready to promote to release, tag from the branch
git tag v1.0.0
git push origin v1.0.0

# 4. CI automatically creates the GitHub release with XCFrameworks
```

**Benefits of this approach:**
- ✅ Iterate and fix issues without manipulating tags
- ✅ Tests run on release candidate branch
- ✅ Only promote when you're confident
- ✅ Clear separation: RC branch vs released version (tag)

## Overview

The release process includes two stages:

### Stage 1: Release Candidate (RC)
- Create `release/X.Y.Z` branch
- Automated testing on the branch
- Builds XCFrameworks for all platforms
- Iterate and fix issues without tag manipulation
- Artifacts kept for 90 days

### Stage 2: Release Promotion
- Create a version tag `vX.Y.Z` from the RC branch
- Tag triggers final release workflow
- Publishes GitHub release with XCFrameworks
- Auto-generated release notes from commits

## Release Workflow

### Stage 1: Create Release Candidate Branch

**When you're ready to prepare a release:**

Go to **Actions → Create Release Candidate → Run workflow** and enter the version number (e.g. `1.0.0`). The workflow creates and pushes the `release/1.0.0` branch automatically.

Alternatively, create the branch manually:

```bash
git checkout -b release/1.0.0
git push origin release/1.0.0
```

**What happens automatically:**
- GitHub Actions detects the `release/*` branch
- Runs full test suite
- Builds XCFrameworks for all platforms
- Stores artifacts for 90 days
- Posts status notification in workflow

**On the RC branch, you can:**
- Fix bugs discovered during testing
- Update version references
- Polish documentation
- Push commits normally: `git push origin release/1.0.0`

**Each push to the RC branch triggers a new CI build:**
- Run tests
- Build XCFrameworks
- Replace previous artifacts

### Stage 2: Promote RC to Release

**When RC branch is ready:**

```bash
# 1. Checkout the RC branch (or ensure you're on it)
git checkout release/1.0.0

# 2. Create the release tag
git tag v1.0.0

# 3. Push the tag
git push origin v1.0.0
```

**What happens automatically:**
- GitHub Actions detects the tag
- Verifies tag format (vX.Y.Z)
- Downloads artifacts from the RC branch
- Creates GitHub release with all XCFrameworks
- Auto-generates release notes
- Posts completion notification

**No more tag manipulation needed!**
- If workflow fails, simply delete the tag and push a fix to the RC branch:
  ```bash
  git tag -d v1.0.0
  git push origin :refs/tags/v1.0.0
  git push origin release/1.0.0  # Push fixes to RC branch
  git tag v1.0.0
  git push origin v1.0.0
  ```

## Technical Details

### XCFramework Building Process

Since this is a Swift Package Manager (SPM) library, the release workflow builds XCFrameworks using the Swift toolchain:

1. **Build Swift libraries** with `swift build -c release` for each target
2. **Extract Swift modules** (.swiftmodule, .swiftdoc, .abi.json, .swiftsourceinfo) from `.build/release/Modules/`
3. **Package modules into XCFramework structure** with proper Info.plist metadata
4. **Archive as .zip** for GitHub release distribution

This approach provides:
- ✅ Source-based distribution (modules are source/interface metadata, not binaries)
- ✅ Full type safety and IDE support in consuming projects
- ✅ Support for all platforms through Swift's cross-platform support
- ✅ Smaller distribution size than traditional binary frameworks
- ✅ Easier debugging with source information included

### XCFramework Structure

Each XCFramework contains:

```
FrameworkName.xcframework/
├── Info.plist              # Framework metadata (platform/architecture info)
├── FrameworkName.swiftmodule    # Compiled Swift module interface
├── FrameworkName.swiftdoc       # Swift documentation 
├── FrameworkName.abi.json       # ABI stability information
└── FrameworkName.swiftsourceinfo # Source location information
```

These files enable Xcode and Swift tooling to:
- Provide IDE code completion and navigation
- Enable linking against the library
- Preserve source-based debugging information
- Validate ABI compatibility

### Why This Approach vs. Binary Frameworks?

For an open-source Swift library, module-based XCFrameworks are preferred because:

1. **Source-based distribution** maintains compatibility across Swift versions
2. **No architecture limitations** - users on new Apple Silicon variants aren't blocked
3. **Smaller distribution** - modules are ~500KB vs. multi-MB binary frameworks
4. **Better debugging** - source information is included without a separate dSYM download
5. **Simpler build process** - no need for cross-compilation tooling

### Recommended Usage

While XCFrameworks are provided, **the recommended way to use FP is still via Swift Package Manager**:

```swift
// In Package.swift
.package(url: "https://github.com/luizmb/FP.git", from: "1.0.0")
```

This provides:
- Latest updates automatically
- No build artifacts in your repository
- Better dependency resolution
- Source-level debugging

Use XCFrameworks only if you have specific requirements for binary distribution.

### Why `build-for-xcframework` Doesn't Exist

Earlier versions of this process attempted to use `xcodebuild build-for-xcframework`, but this command doesn't exist in modern Xcode. The correct approach for SPM packages is to build libraries and package their modules, which this workflow now does.

### Artifact Storage and Retention

- **RC Build Artifacts**: Retained for 90 days in GitHub Actions
- **Release Artifacts**: Permanently attached to GitHub Releases
- **Local Build**: Generated in `release-artifacts/` directory

## Workflow Details

### GitHub Actions Workflow (`release.yml`)

#### Job 1: Test & Validate
- Checks out code
- Runs SwiftLint (strict mode)
- Builds all targets
- Runs complete test suite
- Only proceeds to build if all tests pass

#### Job 2: Build XCFramework (Matrix)
- Runs for each framework target in parallel
- Uses `swift build -c release` to build the library
- Extracts Swift modules from `.build/release/Modules/`
- Packages modules into XCFramework structure with Info.plist metadata
- Zips XCFrameworks for distribution
## Supported Frameworks

The following frameworks are built and released:

| Framework | Purpose |
|-----------|---------|
| `FP` | Umbrella framework (re-exports all) |
| `CoreFP` | Core functional programming utilities |
| `CoreFPOperators` | Operator syntax for CoreFP |
| `DataStructure` | Advanced data structures (Either, Reader, etc.) |
| `DataStructureOperators` | Operator syntax for DataStructure |

## Using Released XCFrameworks

### From GitHub Release

1. Go to [Releases](../../releases)
2. Download the `.xcframework.zip` for your framework
3. Unzip: `unzip Framework.xcframework.zip`
4. Add to Xcode project:
   - Select target → Build Phases
   - Link Binary With Libraries → +
   - Select the `.xcframework` folder

### Integration

Once added to your project, import normally:

```swift
import FP
// or
import CoreFP
import DataStructure
// etc.
```

## Troubleshooting

### RC Build Fails

**Scenario**: You pushed the RC branch but the CI workflow failed.

**Solution**:
1. Check Actions tab to see which job failed
2. Review the logs to understand the issue
3. Fix the issue locally
4. Push the fix to the RC branch: `git push origin release/X.Y.Z`
5. CI will automatically run again on the new commit
6. Verify the new build succeeds

**No tags involved yet**, so iteration is safe and simple.

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
   # Make sure you're on the RC branch
   git checkout release/X.Y.Z
   # Fix the issue
   git push origin release/X.Y.Z
   ```

3. Verify the RC branch builds successfully

4. Re-create and push the tag:
   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

### Build Fails on RC Branch

**Symptoms**: XCFramework build fails for one or more frameworks

**Debugging steps**:

1. **Check the "List Available Schemes" step output**
   - This shows what schemes xcodebuild can find
   - Should include: FP, CoreFP, CoreFPOperators, DataStructure, DataStructureOperators
   - If a scheme is missing, the framework can't be built

2. **Check the "Build XCFramework" step output**
   - Shows exact xcodebuild command (with `set -x`)
   - Shows build errors and warnings
   - Shows build directory contents if build fails

3. **Common issues**:
   - **Scheme not found**: Ensure Package.swift defines all framework products
   - **Architecture mismatch**: xcodebuild should auto-select compatible architectures
   - **Xcode version**: Verify Xcode 26.2 is being used (set in workflow)

4. **Local testing**:
   ```bash
   # Test if scheme is available locally
   xcodebuild -list
   ```

### Release Not Appearing After Tag Push

**Scenario**: Tag was pushed but release doesn't appear

**Debug steps**:
- Go to Actions tab and check the workflow status
- Verify tag format is correct: `vX.Y.Z` (semver)
- Check "Promote - Notify Status" job for error details
- Verify GitHub permissions include release creation

### Artifact Storage

- RC artifacts: **90 days** retention
- Promote artifacts: Downloaded from RC branch, attached to release
- Old releases: Stored permanently on GitHub Releases page

## Git Workflow Examples

### Example 1: Create and Publish v1.0.0

```bash
# Create RC branch
# Preferred: Actions → Create Release Candidate → Run workflow → enter "1.0.0"
# Fallback:  git checkout -b release/1.0.0 && git push origin release/1.0.0

# Wait for Actions to build...
# Test integration...

# When satisfied, promote to release
git tag v1.0.0
git push origin v1.0.0

# Monitor Actions for release creation

# Optional: merge back to main
git checkout main
git merge release/1.0.0
git push origin main
```

### Example 2: Fix Issues on RC Before Release

```bash
# You're on release/1.0.0
# Fix the issue
git commit -am "Fix build issue"
git push origin release/1.0.0

# Wait for new CI build...
# Once stable:
git tag v1.0.0
git push origin v1.0.0
```

### Example 3: Recover from Failed Tag

```bash
# Tag build failed, need to recover
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0

# Stay on RC branch and fix
git checkout release/1.0.0
# ... make fixes ...
git push origin release/1.0.0

# Verify CI passes

# Retry the tag
git tag v1.0.0
git push origin v1.0.0
```

## Release Checklist

### Before Creating Release Candidate Branch

- [ ] All tests pass locally: `swift test 2>&1 | xcsift`
- [ ] Code builds without warnings: `swift build 2>&1 | xcsift`
- [ ] SwiftLint passes: `mint run swiftlint lint --strict`
- [ ] Periphery passes: `periphery scan`
- [ ] No uncommitted changes: `git status`
- [ ] Main branch is up to date: `git pull origin main`

### After Creating RC Branch (`release/X.Y.Z`)

- [ ] Branch created and pushed
- [ ] GitHub Actions workflow started automatically
- [ ] RC build job completes successfully
- [ ] Review XCFramework artifacts in workflow
- [ ] Test integration in your projects (optional but recommended)
- [ ] All expected artifacts present in Actions

### Before Promoting to Release (Creating Tag)

- [ ] RC branch builds are stable
- [ ] No more fixes needed on RC branch
- [ ] Ready to publish to GitHub Releases
- [ ] Checked the generated release notes will be accurate

### After Promoting to Release (After Tag Push)

- [ ] Tag is properly formatted: `vX.Y.Z`
- [ ] Release workflow completes successfully
- [ ] GitHub release appears on Releases page
- [ ] All XCFrameworks are attached
- [ ] Release notes are accurate
- [ ] (Optional) Merge RC branch back to main: `git checkout main && git merge release/X.Y.Z`

## CI/CD Files

- **Continuous Integration**: [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)
  - Runs on pull requests
  - Tests and linting

- **Create Release Candidate**: [`.github/workflows/create-rc.yml`](../../.github/workflows/create-rc.yml)
  - Manual workflow dispatch
  - Creates and pushes `release/X.Y.Z` branch

- **Release Workflow**: [`.github/workflows/release.yml`](../../.github/workflows/release.yml)
  - Runs on `release/*` branches and version tags
  - Builds XCFrameworks
  - Creates releases

## Notes

- All builds use Release configuration
- Tests are run before building XCFrameworks
- Build output is piped through `xcsift` for cleaner logs
- XCFrameworks are fat binaries combining all platforms
- Each release is independent and versioned with git tags
- Release notes are auto-generated from commit history

## References

- [XCFramework Documentation](https://help.apple.com/xcode/mac/current/#/dev51a648b07)
- [Swift Package Manager](https://swift.org/package-manager/)
- [Semantic Versioning](https://semver.org/)
