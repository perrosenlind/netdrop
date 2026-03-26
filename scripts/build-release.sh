#!/bin/bash
# Build a release .app bundle and zip it for distribution
set -e

echo "Building NetDrop release..."

# Generate project if needed
if [ ! -d "NetDrop.xcodeproj" ]; then
    xcodegen generate
fi

# Build release
xcodebuild -project NetDrop.xcodeproj \
    -scheme NetDrop \
    -configuration Release \
    -derivedDataPath build \
    clean build

APP_PATH="build/Build/Products/Release/NetDrop.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: NetDrop.app not found at $APP_PATH"
    exit 1
fi

# Create zip for distribution
cd build/Build/Products/Release
zip -r ../../../../NetDrop.app.zip NetDrop.app
cd ../../../..

echo ""
echo "Release build complete!"
echo "  App: $APP_PATH"
echo "  Zip: NetDrop.app.zip"
echo ""
echo "To create a GitHub release:"
echo "  gh release create v0.1.0 NetDrop.app.zip --title 'NetDrop v0.1.0' --notes 'Initial release'"
