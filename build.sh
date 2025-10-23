#!/bin/bash

# Build script for Psst iOS app using Vanes simulator
# This avoids the iPhone 16 simulator issues

echo "🔨 Building Psst for Vanes simulator..."

cd /Users/finessevanes/Desktop/gauntlet-02-second-agent

# Build using Vanes simulator (reliable, always works on first attempt)
xcodebuild -project Psst/Psst.xcodeproj -scheme Psst -destination 'platform=iOS Simulator,name=Vanes' clean build 2>&1 | tail -50

echo "✅ Build complete!"
