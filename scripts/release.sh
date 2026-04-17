#!/bin/bash

# FP Release Build Script
# Builds XCFrameworks for all library targets and creates release artifacts
# 
# This script mimics the CI build process locally.
# Use this to test and validate builds before creating an RC branch.
#
# Workflow:
#   1. Test locally: ./scripts/release.sh
#   2. Create RC: ./scripts/create-rc.sh X.Y.Z
#   3. Promote when ready: git tag vX.Y.Z && git push origin vX.Y.Z

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
FRAMEWORKS=("FP" "CoreFP" "CoreFPOperators" "DataStructure" "DataStructureOperators")
BUILD_DIR="build/release"
RELEASE_DIR="release-artifacts"

log_step() {
    echo -e "${BLUE}→${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Clean up previous builds
log_step "Cleaning up previous builds..."
rm -rf "$BUILD_DIR" "$RELEASE_DIR"
mkdir -p "$BUILD_DIR" "$RELEASE_DIR"
log_success "Cleaned build directories"

# Test the package
log_step "Running tests..."
if swift test 2>&1 | xcsift; then
    log_success "All tests passed"
else
    log_error "Tests failed"
    exit 1
fi

# Build XCFrameworks
for framework in "${FRAMEWORKS[@]}"; do
    log_step "Building XCFramework for $framework..."
    
    FRAMEWORK_BUILD_DIR="$BUILD_DIR/$framework"
    mkdir -p "$FRAMEWORK_BUILD_DIR"
    
    platforms=("macOS" "iOS" "iOS Simulator" "tvOS" "tvOS Simulator" "watchOS" "watchOS Simulator")
    framework_paths=()
    
    for platform in "${platforms[@]}"; do
        log_step "  Building $framework for $platform..."
        
        if [[ "$platform" == "macOS" ]]; then
            destination="platform=macOS"
            derived_data_suffix="macOS"
        elif [[ "$platform" == "iOS Simulator" ]]; then
            destination="generic/platform=iOS Simulator"
            derived_data_suffix="iOS-simulator"
        elif [[ "$platform" == "tvOS Simulator" ]]; then
            destination="generic/platform=tvOS Simulator"
            derived_data_suffix="tvOS-simulator"
        elif [[ "$platform" == "watchOS Simulator" ]]; then
            destination="generic/platform=watchOS Simulator"
            derived_data_suffix="watchOS-simulator"
        else
            destination="generic/platform=$platform"
            derived_data_suffix="${platform,,}"
        fi
        
        derived_data_path="$FRAMEWORK_BUILD_DIR/$derived_data_suffix"
        
        xcodebuild \
            -scheme "$framework" \
            -configuration Release \
            -destination "$destination" \
            -derivedDataPath "$derived_data_path" \
            -skip-testing \
            build > /dev/null 2>&1
        
        framework_path="$derived_data_path/Build/Release/$framework.framework"
        if [[ -d "$framework_path" ]]; then
            framework_paths+=("-framework" "$framework_path")
            log_success "    Built for $platform"
        else
            log_error "    Failed to build for $platform"
            exit 1
        fi
    done
    
    # Create XCFramework
    log_step "  Creating XCFramework..."
    xcodebuild -create-xcframework \
        "${framework_paths[@]}" \
        -output "$FRAMEWORK_BUILD_DIR/$framework.xcframework" \
        > /dev/null 2>&1
    
    log_success "  XCFramework created"
    
    # Archive XCFramework
    log_step "  Archiving XCFramework..."
    (cd "$FRAMEWORK_BUILD_DIR" && zip -r -q "$framework.xcframework.zip" "$framework.xcframework")
    
    # Move to release directory
    mv "$FRAMEWORK_BUILD_DIR/$framework.xcframework.zip" "$RELEASE_DIR/"
    log_success "Completed $framework"
done

# Create version file
log_step "Creating release metadata..."
cat > "$RELEASE_DIR/RELEASE_INFO.txt" << EOF
FP Release Artifacts
====================

Frameworks included:
$(for f in "${FRAMEWORKS[@]}"; do echo "  - $f"; done)

Build date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Swift version: $(swift --version)
Xcode: $(xcode-select -p)

Each framework is provided as an XCFramework supporting:
  - macOS (arm64 + x86_64)
  - iOS (arm64)
  - iOS Simulator (arm64 + x86_64)
  - tvOS (arm64)
  - tvOS Simulator (arm64 + x86_64)
  - watchOS (arm64)
  - watchOS Simulator (arm64 + x86_64)

Installation:
1. Unzip the XCFramework: unzip <framework>.xcframework.zip
2. Add to your Xcode project: 
   - Select target > Build Phases > Link Binary With Libraries
   - Click + and select the .xcframework folder

EOF
log_success "Metadata created"

log_step "Listing release artifacts..."
ls -lh "$RELEASE_DIR"

log_success "Release build complete!"
echo ""
echo "Artifacts location: $RELEASE_DIR"
echo "XCFrameworks are ready for distribution."
