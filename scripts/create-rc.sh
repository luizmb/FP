#!/bin/bash

# Release Candidate Branch Creation Helper
# Creates a release/X.Y.Z branch and pushes it to trigger CI

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_step() {
    echo -e "${BLUE}→${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Show usage
if [[ $# -eq 0 ]]; then
    echo -e "${BLUE}Release Candidate Branch Creator${NC}"
    echo ""
    echo "Usage: ./scripts/create-rc.sh <version>"
    echo "Example: ./scripts/create-rc.sh 1.0.0"
    echo ""
    echo "This will:"
    echo "  1. Create a release/X.Y.Z branch"
    echo "  2. Push to GitHub"
    echo "  3. Trigger CI to build and test"
    echo ""
    exit 0
fi

VERSION="$1"

# Validate version format
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    log_error "Invalid version format: $VERSION"
    echo "Expected format: X.Y.Z (e.g., 1.0.0)"
    exit 1
fi

BRANCH="release/$VERSION"
TAG="v$VERSION"

log_step "Creating Release Candidate $VERSION"
echo ""

# Check current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
log_step "Currently on: $CURRENT_BRANCH"

# Ensure we're on main
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    log_step "Switching to main..."
    if ! git checkout main 2>/dev/null; then
        log_error "Failed to checkout main"
        exit 1
    fi
    log_success "On main branch"
fi

# Check for uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    log_error "Uncommitted changes detected"
    echo "Please commit or stash your changes first"
    exit 1
fi

# Check if branch already exists locally
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    log_error "Branch $BRANCH already exists locally"
    exit 1
fi

# Check if branch exists remotely
if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
    log_error "Branch $BRANCH already exists on GitHub"
    exit 1
fi

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    log_error "Tag $TAG already exists locally"
    exit 1
fi

if git ls-remote --tags origin "$TAG" | grep -q "$TAG"; then
    log_error "Tag $TAG already exists on GitHub"
    exit 1
fi

# Create the branch
log_step "Creating branch $BRANCH..."
if git checkout -b "$BRANCH"; then
    log_success "Branch created"
else
    log_error "Failed to create branch"
    exit 1
fi

# Push the branch
log_step "Pushing branch to GitHub..."
if git push -u origin "$BRANCH"; then
    log_success "Branch pushed"
else
    log_error "Failed to push branch"
    exit 1
fi

echo ""
log_success "Release Candidate $VERSION is ready!"
echo ""
echo "Next steps:"
echo "  1. Wait for Actions workflow to build and test"
echo "  2. Review XCFramework artifacts"
echo "  3. Test integration in your projects"
echo "  4. When ready to promote:"
echo ""
echo "     git tag $TAG"
echo "     git push origin $TAG"
echo ""
echo "Workflow: $GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions"
echo "RC Branch: $GITHUB_SERVER_URL/$GITHUB_REPOSITORY/tree/$BRANCH"
