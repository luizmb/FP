# Release Process

This document describes the FP library release process using a Release Candidate (RC) branch pattern.

## Quick Reference

**TL;DR - RC + Promotion Process**:

```bash
# 1. Create a release candidate branch
git checkout -b release/1.0.0
git push origin release/1.0.0

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

```bash
# 1. Create the RC branch locally
git checkout -b release/1.0.0

# 2. Push the branch to GitHub
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

### Local Testing (Optional)

For testing the build process locally:

```bash
# Make script executable (one time)
chmod +x scripts/release.sh

# Run the release build
./scripts/release.sh
```

This generates:
- `release-artifacts/` directory with all XCFramework zips
- `RELEASE_INFO.txt` with build metadata

## Technical Details

### XCFramework Building Process

The release workflow uses `xcodebuild build-for-xcframework` to create XCFrameworks for SPM packages. This is the modern, recommended approach that:

1. **Builds for multiple platforms simultaneously** with a single command
2. **Handles architecture selection** (arm64, x86_64, etc.) correctly
3. **Packages frameworks properly** for XCFramework format
4. **Supports all Apple platforms**: macOS, iOS, tvOS, watchOS (device + simulator)

Each framework build includes:
- **macOS**: arm64 + x86_64
- **iOS**: arm64e (device)
- **iOS Simulator**: arm64 + x86_64
- **tvOS**: arm64e (device)
- **tvOS Simulator**: arm64 + x86_64
- **watchOS**: arm64e (device)
- **watchOS Simulator**: arm64 + x86_64

### Why `build-for-xcframework` Instead of `xcodebuild build`?

The older approach using `xcodebuild build` with `-derivedDataPath` doesn't work reliably for SPM packages because:

1. SPM library targets don't automatically produce `.framework` bundles
2. The framework output location is not guaranteed
3. Collecting frameworks from multiple separate builds is error-prone

`build-for-xcframework` is specifically designed to:
- Create proper frameworks from SPM targets
- Handle all destination variations in one command
- Output a complete, ready-to-use XCFramework

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
- Uses `xcodebuild build-for-xcframework` command
- Builds for all supported platforms in one pass:
  - macOS (arm64, x86_64)
  - iOS device (arm64e)
  - iOS Simulator (arm64, x86_64)
  - tvOS device (arm64e)
  - tvOS Simulator (arm64, x86_64)
  - watchOS device (arm64e)
  - watchOS Simulator (arm64, x86_64)
- Creates single XCFramework with all platform variants
- Compresses as `.xcframework.zip`
- Stores artifacts for 90 days

#### Job 3: RC Notification
- Notifies workflow result (success or failure)
- On success: displays next steps for promotion
- On failure: links to failed jobs for debugging

#### Job 4: Promote - Verify Tag
- Validates tag format (vX.Y.Z)
- Checks for corresponding RC branch
- Ensures tag is valid before proceeding

#### Job 5: Promote - Create Release
- Downloads RC artifacts from 90-day storage
- Generates release notes from git commit history
- Creates GitHub release
- Attaches all XCFramework zips
- Makes release public

#### Job 6: Promote Notification
- Confirms release was published successfully
- Provides link to GitHub Releases page
- On failure: provides recovery instructions

## Supported Frameworks

The following frameworks are built and released:

| Framework | Purpose |
|-----------|---------|
| `FP` | Umbrella framework (re-exports all) |
| `CoreFP` | Core functional programming utilities |
| `CoreFPOperators` | Operator syntax for CoreFP |
| `DataStructure` | Advanced data structures (Either, Reader, etc.) |
| `DataStructureOperators` | Operator syntax for DataStructure |

## Platform Support

Each XCFramework includes builds for:

| Platform | Architecture | Status |
|----------|--------------|--------|
| macOS | arm64, x86_64 | ✅ |
| iOS | arm64 | ✅ |
| iOS Simulator | arm64, x86_64 | ✅ |
| tvOS | arm64 | ✅ |
| tvOS Simulator | arm64, x86_64 | ✅ |
| watchOS | arm64 | ✅ |
| watchOS Simulator | arm64, x86_64 | ✅ |

## Technical Details

### XCFramework Building Process

The release workflow uses `xcodebuild build-for-xcframework` to create XCFrameworks for SPM packages. This is the modern, recommended approach that:

1. **Builds for multiple platforms simultaneously** with a single command
2. **Handles architecture selection** (arm64, x86_64, etc.) correctly
3. **Packages frameworks properly** for XCFramework format
4. **Supports all Apple platforms**: macOS, iOS, tvOS, watchOS (device + simulator)

Each framework build includes:
- **macOS**: arm64 + x86_64
- **iOS**: arm64e (device)
- **iOS Simulator**: arm64 + x86_64
- **tvOS**: arm64e (device)
- **tvOS Simulator**: arm64 + x86_64
- **watchOS**: arm64e (device)
- **watchOS Simulator**: arm64 + x86_64

### Why `build-for-xcframework` Instead of `build`?

The older approach of using `xcodebuild build` with `-derivedDataPath` doesn't work reliably for SPM packages because:

1. SPM library targets don't automatically produce `.framework` bundles
2. The framework output location is not guaranteed
3. Collecting frameworks from multiple separate builds is error-prone

`build-for-xcframework` is specifically designed to:
- Create proper frameworks from SPM targets
- Handle all destination variations in one command
- Output a complete, ready-to-use XCFramework

### Artifact Storage

- **RC Build Artifacts**: Retained for 90 days in GitHub Actions
- **Release Artifacts**: Permanently attached to GitHub Releases
- **Local Build**: Generated in `release-artifacts/` directory

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

**Symptoms**: XCFramework build fails for one or more platforms

- Verify Xcode version matches `.swift-version`: `cat .swift-version`
- Check platform-specific build logs in Actions
- Some platforms may be skipped if build environment is unavailable
- This is OK—the XCFramework will include available platforms

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
git checkout -b release/1.0.0
git push origin release/1.0.0

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

- **Release Workflow**: [`.github/workflows/release.yml`](../../.github/workflows/release.yml)
  - Runs on version tags
  - Builds XCFrameworks
  - Creates releases

- **Local Script**: [`scripts/release.sh`](../../scripts/release.sh)
  - For local testing and builds
  - No GitHub dependency
  - Same process as CI

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
