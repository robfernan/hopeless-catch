#!/bin/bash

# Deploy script - Build, zip, and prepare for itch.io upload

set -e  # Exit on error

echo "🎣 Hopeless Catch - Deploy Script"
echo "=================================="
echo ""

# Step 1: Build
echo "📦 Building web version..."
bash Love2d_Web/build.sh
echo "✅ Build complete"
echo ""

# Step 2: Create zip
echo "📦 Creating zip file..."
cd Love2d_Web/dist
zip -r -q hopeless-catch-web.zip *
cd ../..
echo "✅ Zip created: Love2d_Web/dist/hopeless-catch-web.zip"
echo ""

# Step 3: Show file info
echo "📊 File Info:"
ls -lh Love2d_Web/dist/hopeless-catch-web.zip
echo ""

# Step 4: Instructions
echo "🚀 Next Steps:"
echo "1. Go to: https://mungdaal321.itch.io/hopeless-catch/edit"
echo "2. Scroll to 'Uploads'"
echo "3. Click 'Upload files'"
echo "4. Select: Love2d_Web/dist/hopeless-catch-web.zip"
echo "5. Check: 'This file will be played in the browser'"
echo "6. Click 'Save'"
echo ""
echo "✨ Done! Your game will be playable in browser on itch.io"
