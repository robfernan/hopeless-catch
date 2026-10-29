#!/bin/bash

# Upload to itch.io using butler
# Make sure butler is installed first

set -e

echo "🎣 Uploading to itch.io..."
echo ""

# Check if butler exists
if ! command -v butler &> /dev/null; then
    echo "❌ Butler not found. Install it first:"
    echo "   wget https://github.com/itchio/butler/releases/download/v15.21.0/butler-linux-amd64"
    echo "   chmod +x butler-linux-amd64"
    echo "   sudo mv butler-linux-amd64 /usr/local/bin/butler"
    exit 1
fi

# Build first
echo "📦 Building..."
bash Love2d_Web/build.sh
echo ""

# Upload
echo "📤 Uploading to itch.io..."
butler push Love2d_Web/dist/ mungdaal321/hopeless-catch:web

echo ""
echo "✅ Upload complete!"
echo "🌐 Your game is now at: https://mungdaal321.itch.io/hopeless-catch"
