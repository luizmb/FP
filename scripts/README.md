# Release Scripts

This directory contains helper scripts for managing FP library releases using the Release Candidate (RC) branch pattern.

## Scripts

### `release.sh` - Local Build Testing

Tests the complete release build process **locally** without creating branches or tags.

**Usage:**
```bash
./scripts/release.sh
```

**What it does:**
- Runs full test suite
- Builds XCFrameworks for all platforms
- Creates release artifacts in `release-artifacts/`
- Validates everything works before you create an RC branch

**When to use:**
- Testing the build process locally
- Validating before creating an RC branch
- Debugging build issues

**Output:**
- `release-artifacts/` directory with XCFramework zips
- `RELEASE_INFO.txt` with build metadata

### `create-rc.sh` - Create Release Candidate Branch

Creates a `release/X.Y.Z` branch and pushes it to GitHub to trigger CI.

**Usage:**
```bash
./scripts/create-rc.sh 1.0.0
```

**What it does:**
- Validates version format (X.Y.Z)
- Creates local branch `release/1.0.0`
- Pushes to GitHub
- Triggers automatic CI workflow

**Prerequisites:**
- On `main` branch
- No uncommitted changes
- Git remote `origin` configured

**Next steps (printed at end):**
1. Wait for Actions workflow
2. Review XCFramework artifacts
3. Test integration
4. Promote when ready: `git tag v1.0.0 && git push origin v1.0.0`

### `cleanup-failed-release.sh` - Clean Up Failed Tags

Removes a tag (locally and remotely) if release promotion fails.

**Usage:**
```bash
./scripts/cleanup-failed-release.sh v1.0.0
```

**What it does:**
- Validates tag format
- Confirms your intention (interactive)
- Deletes local tag
- Deletes remote tag
- Verifies removal
- Prints next recovery steps

**When to use:**
- Release promotion workflow failed
- Need to delete bad tag and retry
- Iterating on RC branch

## Release Workflow Diagram

```
main branch
    ↓
[Pre-flight validation]
    ↓
./scripts/create-rc.sh 1.0.0
    ↓
Create & push release/1.0.0 branch
    ↓
GitHub Actions CI starts
    ├─ Test & validate
    ├─ Build XCFrameworks (all platforms)
    └─ Store artifacts (90 days)
    ↓
Review & test RC
    ↓
Fix issues (push to release/1.0.0)
    ↓
CI runs again on new commit
    ↓
[When satisfied]
    ↓
git tag v1.0.0
git push origin v1.0.0
    ↓
GitHub Actions promotion workflow
    ├─ Verify tag format
    ├─ Download RC artifacts
    └─ Create GitHub release
    ↓
Release published with XCFrameworks
    ↓
[Optional] Merge back to main
```

## Quick Start Example

```bash
# 1. Test locally
./scripts/release.sh

# 2. Create RC
./scripts/create-rc.sh 1.0.0

# 3. Wait for CI (check Actions tab)

# 4. Review, test, possibly iterate

# 5. Promote when ready
git tag v1.0.0
git push origin v1.0.0

# 6. Monitor Actions for release creation

# 7. Verify on GitHub Releases page
```

## Troubleshooting

### create-rc.sh fails

**Not on main branch:**
```bash
git checkout main
./scripts/create-rc.sh 1.0.0
```

**Uncommitted changes:**
```bash
git status
git commit -am "Your message"
./scripts/create-rc.sh 1.0.0
```

**Branch/tag already exists:**
Clean up first:
```bash
./scripts/cleanup-failed-release.sh v1.0.0
git branch -D release/1.0.0
```

### CI fails during RC

No tag involved yet, so fix and iterate:

```bash
# Fix the issue
git checkout release/1.0.0
# ... make changes ...
git push origin release/1.0.0

# CI runs automatically on new commit
```

### Promotion fails

Recover without touching the RC branch:

```bash
./scripts/cleanup-failed-release.sh v1.0.0

# Fix if needed on RC branch
git checkout release/1.0.0
# ... optional fixes ...
git push origin release/1.0.0

# Verify RC CI passes

# Retry promotion
git tag v1.0.0
git push origin v1.0.0
```

## Notes

- All scripts require `main` branch or existing release branch checkout
- Version format must be semver: `X.Y.Z`
- Tags always use `vX.Y.Z` format
- Branches always use `release/X.Y.Z` format
- Scripts are safe—they validate inputs and confirm destructive operations
- See [RELEASE_PROCESS.md](../docs/RELEASE_PROCESS.md) for complete documentation
