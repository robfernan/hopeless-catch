# Quick Reference - Web Port Commands

## Development Workflow

### 1. Make changes to Lua files
Edit any `.lua` file in `Love2d_Web/`

### 2. Rebuild the game
```bash
bash Love2d_Web/build.sh
```

This does:
- Packages all files into `game.love`
- Compiles with love.js to `dist/`
- Ready to serve

### 3. Run locally
```bash
python3 Love2d_Web/serve.py
```

Open http://localhost:3000/

---

## Manual Build Steps

If `build.sh` doesn't work:

```bash
# 1. Create .love file
cd Love2d_Web
zip -r -q game.love main.lua conf.lua *.lua assets/ fishing/ menu/ ui/ world/ *.png
cd ..

# 2. Compile with love.js
rm -rf Love2d_Web/dist
love.js Love2d_Web/game.love Love2d_Web/dist --title "Hopeless Catch" --memory 134217728

# 3. Serve
python3 Love2d_Web/serve.py
```

---

## Deployment Checklist

- [ ] Run `bash Love2d_Web/build.sh`
- [ ] Test locally: `python3 Love2d_Web/serve.py`
- [ ] Upload `Love2d_Web/dist/` folder to web server
- [ ] Configure server headers (see WEB_PORT_GUIDE.md)
- [ ] Test in production

---

## Server Headers Required

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
Content-Security-Policy: default-src 'self' https:; script-src 'self' 'unsafe-eval' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:
```

---

## File Locations

| File | Purpose |
|------|---------|
| `Love2d_Web/main.lua` | Game entry point |
| `Love2d_Web/conf.lua` | LÖVE configuration |
| `Love2d_Web/game.love` | Packaged game (generated) |
| `Love2d_Web/dist/` | Web build output (generated) |
| `Love2d_Web/serve.py` | Local dev server |
| `Love2d_Web/build.sh` | Build script |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "main.lua not found" | Rebuild: `bash build.sh` |
| Game won't load | Check console (F12), restart server |
| Performance lag | Close other tabs, check network |
| Controls not working | Click game window, try keyboard first |

---

## Key Commands

```bash
# Install love.js globally (one time)
sudo npm install -g love.js

# Build the game
bash Love2d_Web/build.sh

# Run locally
python3 Love2d_Web/serve.py

# Check .love file contents
unzip -l Love2d_Web/game.love

# Clean build
rm -rf Love2d_Web/dist Love2d_Web/game.love
bash Love2d_Web/build.sh
```

---

## Browser Console Warnings

**"Content Security Policy blocks eval"** - This is normal and expected. Love.js requires `eval()` to function. The CSP header explicitly allows it.

---

For detailed information, see **WEB_PORT_GUIDE.md**
