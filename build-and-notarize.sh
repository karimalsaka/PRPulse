#!/bin/bash

# Build, Package, and Notarize Script for blnk
# This script builds the app, creates a DMG, and submits it for notarization

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="blnk"
PROJECT_NAME="PRPulse"
SCHEME="PRPulse"
BUILD_DIR="./build"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
DMG_NAME="$APP_NAME.dmg"

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Check required environment variables
if [ -z "$APPLE_ID" ] || [ -z "$TEAM_ID" ] || [ -z "$APP_SPECIFIC_PASSWORD" ]; then
    echo -e "${RED}Error: Missing required environment variables${NC}"
    echo "Please create a .env file with:"
    echo "  APPLE_ID=your-email@example.com"
    echo "  TEAM_ID=YOUR_TEAM_ID"
    echo "  APP_SPECIFIC_PASSWORD=your-app-specific-password"
    echo "  SIGNING_IDENTITY=Developer ID Application: Your Name (TEAM_ID)"
    exit 1
fi

if [ -z "$SIGNING_IDENTITY" ]; then
    echo -e "${YELLOW}Warning: SIGNING_IDENTITY not set, using default${NC}"
    SIGNING_IDENTITY="Developer ID Application"
fi

echo -e "${GREEN}Starting build process for $APP_NAME...${NC}"

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build and Archive
echo -e "${YELLOW}Building and archiving...${NC}"
xcodebuild clean archive \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates

# Extract app from archive
echo -e "${YELLOW}Extracting app from archive...${NC}"
mkdir -p "$EXPORT_PATH"
cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME.app" "$EXPORT_PATH/$APP_NAME.app"

# Verify the app exists
if [ ! -d "$EXPORT_PATH/$APP_NAME.app" ]; then
    echo -e "${RED}Error: App not found at $EXPORT_PATH/$APP_NAME.app${NC}"
    exit 1
fi

# Re-sign with Developer ID
echo -e "${YELLOW}Re-signing with Developer ID...${NC}"
codesign --force --deep --sign "$SIGNING_IDENTITY" \
    --options runtime \
    --timestamp \
    "$EXPORT_PATH/$APP_NAME.app"

# Verify signature
echo -e "${YELLOW}Verifying app signature...${NC}"
codesign --verify --verbose "$EXPORT_PATH/$APP_NAME.app"

# Create DMG
echo -e "${YELLOW}Creating DMG...${NC}"

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}create-dmg not found. Install it? (y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        brew install create-dmg
    else
        echo -e "${RED}Falling back to hdiutil method...${NC}"
        # Fallback to hdiutil
        hdiutil create -volname "$APP_NAME" -srcfolder "$EXPORT_PATH/$APP_NAME.app" -ov -format UDZO "$DMG_NAME"
    fi
else
    # Use create-dmg for nicer DMG
    create-dmg \
        --volname "$APP_NAME" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 175 190 \
        --hide-extension "$APP_NAME.app" \
        --app-drop-link 425 190 \
        "$DMG_NAME" \
        "$EXPORT_PATH/$APP_NAME.app" || {
        # If create-dmg fails, fall back to hdiutil
        echo -e "${YELLOW}create-dmg failed, using hdiutil...${NC}"
        hdiutil create -volname "$APP_NAME" -srcfolder "$EXPORT_PATH/$APP_NAME.app" -ov -format UDZO "$DMG_NAME"
    }
fi

# Code Sign the DMG
echo -e "${YELLOW}Signing DMG...${NC}"
codesign --sign "$SIGNING_IDENTITY" \
    --timestamp \
    --options runtime \
    "$DMG_NAME"

# Verify signature
echo -e "${YELLOW}Verifying DMG signature...${NC}"
codesign --verify --verbose "$DMG_NAME"

# Submit for Notarization
echo -e "${YELLOW}Submitting for notarization (this may take a few minutes)...${NC}"
xcrun notarytool submit "$DMG_NAME" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --wait

# Check if notarization succeeded
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Notarization successful!${NC}"

    # Staple the notarization ticket
    echo -e "${YELLOW}Stapling notarization ticket...${NC}"
    xcrun stapler staple "$DMG_NAME"

    # Verify stapling
    echo -e "${YELLOW}Verifying stapled ticket...${NC}"
    xcrun stapler validate "$DMG_NAME"

    # Final verification
    echo -e "${YELLOW}Running final Gatekeeper verification...${NC}"
    spctl -a -t open --context context:primary-signature -v "$DMG_NAME"

    echo -e "${GREEN}✓ Success! Your notarized DMG is ready: $DMG_NAME${NC}"
    echo -e "${GREEN}File size: $(du -h "$DMG_NAME" | cut -f1)${NC}"
else
    echo -e "${RED}Notarization failed. Check the logs above for details.${NC}"
    exit 1
fi
