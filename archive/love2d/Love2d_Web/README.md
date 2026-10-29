# Hopeless Catch - Web Port (Love.js)

An **identical web port** of the original LÖVE 2D game. All 61 Lua files run unchanged, compiled to WebAssembly using love.js and Emscripten.

## Quick Start

### Play It Now
```bash
python3 serve.py
# Open http://localhost:3000/
```

### Rebuild After Changes
```bash
bash build.sh
python3 serve.py
```

## How It Works

The game is compiled from Lua to WebAssembly using the `love.js` CLI tool. This means:
- ✅ **Identical rendering** - Same graphics engine
- ✅ **All 61 files unchanged** - Original Lua code runs as-is
- ✅ **Procedural generation works** - Native LÖVE shapes compile correctly
- ✅ **Cross-platform** - Works in any modern browser

## The Process

1. **Package game files** into a `.love` file (ZIP archive)
2. **Compile with love.js** to WebAssembly
3. **Serve with proper headers** for SharedArrayBuffer support
4. **Play in browser** - Identical to desktop version

For detailed technical explanation, see **[WEB_PORT_GUIDE.md](WEB_PORT_GUIDE.md)**.

## File Structure

```
Love2d_Web/
├── main.lua              # Entry point
├── conf.lua              # LÖVE configuration
├── *.lua                 # All game modules
├── assets/               # Game assets
├── fishing/              # Fishing system
├── menu/                 # Menu system
├── ui/                   # UI components
├── world/                # World/environment
├── dist/                 # Compiled web build (generated)
├── game.love             # Packaged game (generated)
├── serve.py              # Local development server
├── build.sh              # Build script
└── WEB_PORT_GUIDE.md     # Detailed technical guide
```

## Deployment

### Local
```bash
python3 serve.py
```

### Production
Upload `dist/` folder to any web server with these headers:
```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
Content-Security-Policy: default-src 'self' https:; script-src 'self' 'unsafe-eval' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:
```

See WEB_PORT_GUIDE.md for Nginx, Apache, Vercel, and Netlify examples.

## Browser Compatibility

- ✅ Chrome/Chromium 91+
- ✅ Firefox 79+
- ✅ Safari 15.2+
- ✅ Edge 91+

Requires WebAssembly and SharedArrayBuffer support.

## Features

- 🎣 Full fishing mechanics
- 🌙 Day/night cycle
- 🐟 9 fish species
- 📖 Journal/catch log
- ⚙️ Settings menu
- 💾 Save/load system
- 🎵 Audio support
- 📱 Touch controls

## Known Limitations

- No Lua threading
- No FFI (Foreign Function Interface)
- Fixed 800x600 resolution
- Some shaders may differ in WebGL

## Build Info

- **Engine**: LÖVE 2D (compiled to WebAssembly)
- **Compiler**: Emscripten
- **Build Tool**: love.js CLI
- **Runtime**: ~15-20MB (game.data + love.wasm)

## Troubleshooting

**Game won't load?**
- Check browser console (F12)
- Ensure server is running with proper headers
- Try a different browser

**Performance issues?**
- Close other tabs
- Check network speed (game.data is ~15MB)
- Increase browser memory allocation

**Controls not working?**
- Ensure browser window has focus
- Try keyboard first (mouse may have issues in some browsers)

## Resources

- **WEB_PORT_GUIDE.md** - Complete technical documentation
- **Love.js**: https://github.com/TannerRogalsky/love.js
- **LÖVE**: https://love2d.org/

---

**Status**: ✅ Fully playable!

🎣 Enjoy Hopeless Catch on the web!
