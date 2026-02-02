#!/bin/bash

# Simple Package and Notarize Script for blnk
# First build your app in Xcode (Cmd+B), then run this script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
APP_NAME="blnk"
DMG_NAME="blnk.dmg"

# Load .env
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Check required vars
if [ -z "$APPLE_ID" ] || [ -z "$TEAM_ID" ] || [ -z "$APP_SPECIFIC_PASSWORD" ] || [ -z "$SIGNING_IDENTITY" ]; then
    echo -e "${RED}Error: Missing required environment variables in .env${NC}"
    exit 1
fi

# Find the built app
BUILT_APP=$(find ~/Library/Developer/Xcode/DerivedData/PRPulse-*/Build/Products -name "$APP_NAME.app" -type d 2>/dev/null | head -n 1)

if [ -z "$BUILT_APP" ]; then
    echo -e "${RED}Error: App not found. Build it in Xcode first (Cmd+B)${NC}"
    exit 1
fi

echo -e "${GREEN}Found app at: $BUILT_APP${NC}"

# Clean old DMG
rm -f "$DMG_NAME"

# Re-sign with Developer ID
echo -e "${YELLOW}Signing with Developer ID...${NC}"
codesign --force --deep --sign "$SIGNING_IDENTITY" \
    --options runtime \
    --timestamp \
    "$BUILT_APP"

echo -e "${YELLOW}Verifying signature...${NC}"
codesign --verify --verbose "$BUILT_APP"

# Install create-dmg if needed
if ! command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}Installing create-dmg...${NC}"
    brew install create-dmg
fi

# Create DMG
echo -e "${YELLOW}Creating DMG...${NC}"
create-dmg \
    --volname "$APP_NAME" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 175 190 \
    --hide-extension "$APP_NAME.app" \
    --app-drop-link 425 190 \
    "$DMG_NAME" \
    "$BUILT_APP"

# Sign DMG
echo -e "${YELLOW}Signing DMG...${NC}"
codesign --sign "$SIGNING_IDENTITY" \
    --timestamp \
    --options runtime \
    "$DMG_NAME"

codesign --verify --verbose "$DMG_NAME"

# Notarize
echo -e "${YELLOW}Submitting for notarization (this takes a few minutes)...${NC}"
xcrun notarytool submit "$DMG_NAME" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --wait

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Notarization successful!${NC}"

    # Staple
    echo -e "${YELLOW}Stapling ticket...${NC}"
    xcrun stapler staple "$DMG_NAME"
    xcrun stapler validate "$DMG_NAME"

    # Final check
    spctl -a -t open --context context:primary-signature -v "$DMG_NAME"

    echo -e "${GREEN}✓ Success! Your notarized DMG: $DMG_NAME${NC}"
    echo -e "${GREEN}Size: $(du -h "$DMG_NAME" | cut -f1)${NC}"
else
    echo -e "${RED}Notarization failed.${NC}"
    exit 1
fi
