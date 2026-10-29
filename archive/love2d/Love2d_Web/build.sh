#!/bin/bash

# Build script for Hopeless Catch web port using love.js

echo "🎣 Building Hopeless Catch for web..."

# Ensure game.love is up to date
echo "📦 Packaging game files..."
zip -r -q Love2d_Web/game.love Love2d_Web \
  -x "Love2d_Web/node_modules/*" \
  "Love2d_Web/dist/*" \
  "Love2d_Web/.git/*" \
  "Love2d_Web/*.json" \
  "Love2d_Web/vite.config.js" \
  "Love2d_Web/index.html" \
  "Love2d_Web/src/*" \
  "Love2d_Web/build.sh" \
  "Love2d_Web/README.md"

# Build with love.js
echo "🔨 Compiling with love.js..."
love.js Love2d_Web/game.love Love2d_Web/dist \
  --title "Hopeless Catch" \
  --memory 134217728

echo "✅ Build complete! Output in Love2d_Web/dist/"
echo "🌐 To run locally: python3 -m http.server 3000 --directory Love2d_Web/dist"
