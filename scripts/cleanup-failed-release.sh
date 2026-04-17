#!/bin/bash

# Tag cleanup helper for failed releases
# Usage: ./scripts/cleanup-failed-release.sh <tag>
# Example: ./scripts/cleanup-failed-release.sh v1.0.0

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $# -eq 0 ]]; then
    echo -e "${BLUE}Tag cleanup helper for failed releases${NC}"
    echo ""
    echo "Usage: ./scripts/cleanup-failed-release.sh <tag>"
    echo "Example: ./scripts/cleanup-failed-release.sh v1.0.0"
    echo ""
    echo "This will:"
    echo "  1. Delete the tag locally"
    echo "  2. Delete the tag from remote GitHub"
    echo "  3. Verify the tag is removed"
    exit 0
fi

TAG="$1"

# Validate tag format
if [[ ! "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo -e "${RED}✗ Invalid tag format: $TAG${NC}"
    echo "   Expected format: vX.Y.Z (e.g., v1.0.0)"
    exit 1
fi

# Check if tag exists locally
if ! git rev-parse "$TAG" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Tag $TAG not found locally${NC}"
fi

# Confirm action
echo -e "${YELLOW}This will delete tag: $TAG${NC}"
read -p "Are you sure? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Delete local tag
echo -e "${BLUE}→${NC} Deleting local tag..."
if git tag -d "$TAG" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Deleted local tag"
else
    echo -e "${YELLOW}⚠ Local tag didn't exist or couldn't be deleted${NC}"
fi

# Delete remote tag
echo -e "${BLUE}→${NC} Deleting remote tag..."
if git push origin ":refs/tags/$TAG" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Deleted remote tag"
else
    echo -e "${RED}✗ Failed to delete remote tag${NC}"
    echo "   Try manually: git push origin :refs/tags/$TAG"
    exit 1
fi

# Verify
echo -e "${BLUE}→${NC} Verifying removal..."
if git rev-parse "$TAG" > /dev/null 2>&1; then
    echo -e "${RED}✗ Tag still exists locally${NC}"
    exit 1
fi

if git ls-remote --tags origin "$TAG" | grep -q "$TAG"; then
    echo -e "${RED}✗ Tag still exists on remote${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Tag $TAG successfully removed"
echo ""
echo "Next steps:"
echo "  1. Fix the issue locally"
echo "  2. Commit fixes: git add . && git commit -m 'Fix release issue'"
echo "  3. Push main: git push origin main"
echo "  4. Re-validate: ./scripts/release.sh"
echo "  5. Create new tag: git tag $TAG && git push origin $TAG"
