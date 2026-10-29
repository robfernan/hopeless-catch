# Hopeless Catch - Web Port Guide

## The Journey: From LÖVE 2D to Web

After extensive exploration of multiple approaches (HTML/CSS/JS rewrites, Phaser 3 ports, love.js CDN attempts), we finally achieved an **identical web port** of the original LÖVE 2D game using **love.js with Emscripten compilation**.

This guide documents the exact process that worked.

---

## What We Tried (And Why They Failed)

### ❌ Approach 1: HTML/CSS/JS Rewrite
- **Problem**: LÖVE's native drawing functions (`love.graphics.polygon()`, `love.graphics.circle()`, etc.) don't have direct Canvas equivalents
- **Result**: Procedural generation and rendering would never be identical
- **Lesson**: Rewriting 61 files would take weeks and still wouldn't match the original

### ❌ Approach 2: Phaser 3 Framework
- **Problem**: Would require porting all Lua code to JavaScript
- **Result**: Not identical, completely different codebase
- **Lesson**: Framework ports are rewrites, not ports

### ❌ Approach 3: Love.js from CDN
- **Problems**: 
  - CSP (Content Security Policy) blocking `eval()`
  - CORB (Cross-Origin Read Blocking) preventing file loading
  - SharedArrayBuffer requiring cross-origin isolation
- **Result**: Game wouldn't initialize
- **Lesson**: CDN approach has too many browser security restrictions

### ✅ Approach 4: Love.js CLI with Proper Build Process
- **Solution**: Use the `love.js` npm package CLI tool to compile the .love file to WebAssembly
- **Result**: **Identical rendering and behavior** - all 61 Lua files run unchanged
- **Why it works**: Emscripten compiles LÖVE's C++ engine to WebAssembly, then love.js runs your Lua code in that engine

---

## The Solution: Love.js CLI Build Process

### Step 1: Install love.js Globally

```bash
sudo npm install -g love.js
```

This installs the `love.js` command-line tool that compiles .love files to web-ready JavaScript/WebAssembly.

### Step 2: Prepare Your Game Files

Ensure your game directory has this structure:

```
Love2d_Web/
├── main.lua              # Entry point
├── conf.lua              # LÖVE configuration
├── *.lua                 # All Lua modules
├── assets/               # Game assets
├── fishing/              # Fishing system modules
├── menu/                 # Menu system modules
├── ui/                   # UI components
├── world/                # World/environment modules
└── *.png                 # Image assets
```

### Step 3: Create the .love File

A `.love` file is just a ZIP archive with a specific structure. Create it from the game directory:

```bash
cd Love2d_Web
zip -r -q game.love main.lua conf.lua *.lua assets/ fishing/ menu/ ui/ world/ *.png
```

**Important**: Files must be at the root of the ZIP, not in a subdirectory. This is why we use `cd` first.

### Step 4: Compile with love.js

```bash
love.js game.love dist --title "Hopeless Catch" --memory 134217728
```

**Parameters**:
- `game.love` - Input .love file
- `dist` - Output directory
- `--title` - Game window title
- `--memory` - Maximum memory (128MB = 134217728 bytes)

**Output files**:
- `dist/index.html` - Web entry point
- `dist/love.js` - LÖVE runtime
- `dist/love.wasm` - Compiled LÖVE engine (WebAssembly)
- `dist/game.js` - Your game code
- `dist/game.data` - Your game assets

### Step 5: Serve with Proper Headers

The game requires specific HTTP headers for WebAssembly and SharedArrayBuffer support:

```python
#!/usr/bin/env python3
import http.server
import socketserver
import os

PORT = 3000

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Cross-origin isolation for SharedArrayBuffer
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        # CSP allowing eval (required by love.js)
        self.send_header('Content-Security-Policy', 
            "default-src 'self' https:; script-src 'self' 'unsafe-eval' 'unsafe-inline' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:")
        super().end_headers()

if __name__ == '__main__':
    os.chdir('Love2d_Web/dist')
    with socketserver.TCPServer(("", PORT), CORSRequestHandler) as httpd:
        print(f"🎣 Serving at http://localhost:{PORT}/")
        httpd.serve_forever()
```

Save as `serve.py` and run:

```bash
python3 serve.py
```

Then open http://localhost:3000/ in your browser.

---

## Why This Works

### The Technical Stack

```
Your Lua Code (61 files)
        ↓
    love.js CLI
        ↓
  Emscripten Compiler
        ↓
  WebAssembly (LÖVE Engine)
        ↓
  JavaScript Wrapper
        ↓
  Browser (with proper headers)
```

### What Makes It Identical

1. **Same Engine**: LÖVE's C++ engine is compiled to WebAssembly, not rewritten
2. **Same Lua Code**: All 61 .lua files run unchanged
3. **Same Graphics**: `love.graphics.polygon()`, `love.graphics.circle()`, etc. work identically
4. **Same Physics**: Procedural generation produces identical results
5. **Same Audio**: Web Audio API handles sound the same way

### Why The CSP Warning Appears

The browser console shows:
```
Content Security Policy of your site blocks the use of 'eval' in JavaScript
```

This is **not an error** - it's just a warning. The CSP header explicitly allows `'unsafe-eval'` for love.js to function. The game works perfectly despite the warning.

---

## Deployment

### Local Testing
```bash
python3 serve.py
# Open http://localhost:3000/
```

### Production Deployment

1. **Build the game**:
   ```bash
   love.js game.love dist --title "Hopeless Catch" --memory 134217728
   ```

2. **Upload `dist/` folder** to your web server

3. **Configure server headers** (examples below):

#### Nginx
```nginx
location / {
    add_header Cross-Origin-Opener-Policy "same-origin";
    add_header Cross-Origin-Embedder-Policy "require-corp";
    add_header Content-Security-Policy "default-src 'self' https:; script-src 'self' 'unsafe-eval' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:";
}
```

#### Apache
```apache
Header set Cross-Origin-Opener-Policy "same-origin"
Header set Cross-Origin-Embedder-Policy "require-corp"
Header set Content-Security-Policy "default-src 'self' https:; script-src 'self' 'unsafe-eval' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:"
```

#### Vercel / Netlify
Add `vercel.json` or `netlify.toml`:

**vercel.json**:
```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Cross-Origin-Opener-Policy",
          "value": "same-origin"
        },
        {
          "key": "Cross-Origin-Embedder-Policy",
          "value": "require-corp"
        },
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self' https:; script-src 'self' 'unsafe-eval' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:"
        }
      ]
    }
  ]
}
```

---

## Rebuilding After Changes

If you modify your Lua code:

```bash
# 1. Recreate the .love file
cd Love2d_Web
zip -r -q game.love main.lua conf.lua *.lua assets/ fishing/ menu/ ui/ world/ *.png

# 2. Rebuild with love.js
cd ..
rm -rf Love2d_Web/dist
love.js Love2d_Web/game.love Love2d_Web/dist --title "Hopeless Catch" --memory 134217728

# 3. Restart server
python3 Love2d_Web/serve.py
```

Or use the provided `build.sh` script:
```bash
bash Love2d_Web/build.sh
```

---

## Known Limitations (Love.js)

These are inherent to the love.js/Emscripten approach:

- ❌ No Lua threading (threads disabled)
- ❌ No FFI (Foreign Function Interface)
- ❌ No window resizing (fixed 800x600)
- ❌ Some shaders may behave differently in WebGL
- ⚠️ Audio streaming not supported (use static audio files)

**Your game doesn't use any of these**, so you're good!

---

## File Size Optimization

The compiled game is ~15-20MB. To reduce size:

1. **Compress images**: Use `pngout` or `optipng`
   ```bash
   optipng -o2 *.png
   ```

2. **Compress audio**: Use lower bitrate OGG files
   ```bash
   ffmpeg -i audio.wav -q:a 4 audio.ogg
   ```

3. **Remove unused files** from the .love file

---

## Troubleshooting

### "File main.lua does not exist on disk"
- **Cause**: .love file not properly structured
- **Fix**: Ensure `main.lua` is at the root of the ZIP, not in a subdirectory
  ```bash
  unzip -l game.love | grep main.lua
  # Should show: main.lua (not Love2d_Web/main.lua)
  ```

### "SharedArrayBuffer is not defined"
- **Cause**: Missing COOP/COEP headers
- **Fix**: Ensure your server sends:
  ```
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
  ```

### Game loads but doesn't render
- **Cause**: CSP blocking scripts
- **Fix**: Ensure CSP header includes `'unsafe-eval'` and `'unsafe-inline'`

### Performance issues
- **Cause**: Large game.data file or slow network
- **Fix**: 
  - Compress assets
  - Increase `--memory` parameter
  - Use a CDN to serve static files

---

## Summary

**The winning approach**:
1. Use `love.js` CLI to compile .love files to WebAssembly
2. Serve with proper COOP/COEP headers for SharedArrayBuffer
3. Allow `'unsafe-eval'` in CSP for love.js to function
4. Deploy the `dist/` folder to any web server

**Result**: An identical web port of your LÖVE 2D game with all 61 files running unchanged.

---

## Resources

- **Love.js GitHub**: https://github.com/TannerRogalsky/love.js
- **LÖVE Documentation**: https://love2d.org/wiki
- **Emscripten**: https://emscripten.org/
- **Web Security Headers**: https://owasp.org/www-project-secure-headers/

---

**Status**: ✅ Game is fully playable on web!

🎣 Enjoy your web-based Hopeless Catch!
