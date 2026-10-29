# Development Guide - Continuing to Build

Now that you have a working web port, here's how to continue developing the game.

---

## Development Workflow

### 1. Make Changes

Edit any `.lua` file in `Love2d_Web/`:

```bash
# Example: Add a new fish
nano Love2d_Web/fishing/fishdata.lua

# Or edit in your editor
code Love2d_Web/
```

### 2. Rebuild

```bash
bash Love2d_Web/build.sh
```

This:
- Packages all files into `game.love`
- Compiles with love.js
- Outputs to `dist/`

### 3. Test Locally

```bash
python3 Love2d_Web/serve.py
```

Open http://localhost:3000/ and test your changes.

### 4. Iterate

Repeat steps 1-3 until satisfied.

---

## Common Development Tasks

### Adding a New Fish

1. **Add data** to `fishing/fishdata.lua`:
```lua
{
    name = "Rainbow Trout",
    weight = 2.5,
    rarity = "uncommon",
    baitMultipliers = {
        worms = 1.2,
        minnows = 0.8,
        cheese = 1.0,
        corn = 0.9
    },
    sprite = "assets/fish/rainbow_trout.png"
}
```

2. **Add sprite** to `assets/fish/rainbow_trout.png`

3. **Rebuild**:
```bash
bash Love2d_Web/build.sh
```

4. **Test** and verify it appears in journal

### Adding a New Location

1. **Create room data** in `world/` (e.g., `river.lua`)
2. **Add platforms, fishing spots, decorations**
3. **Register in room index**
4. **Add transitions** between locations
5. **Rebuild and test**

### Adding New UI Elements

1. **Create UI module** in `ui/` (e.g., `achievements.lua`)
2. **Implement draw and update functions**
3. **Integrate into main game loop** (`main.lua`)
4. **Rebuild and test**

### Adding Audio

1. **Create audio file** (OGG format recommended)
2. **Place in `assets/audio/`**
3. **Load in `assets.lua`**
4. **Play with `love.audio.play()`**
5. **Rebuild and test**

### Modifying Game Mechanics

1. **Edit relevant module** (e.g., `fishing/fishing.lua`)
2. **Test thoroughly** - fishing is complex!
3. **Check for side effects** on other systems
4. **Rebuild and test**

---

## Project Structure

```
Love2d_Web/
├── main.lua                    # Game entry point
├── conf.lua                    # LÖVE configuration
├── gamestate.lua               # State management
├── player.lua                  # Player logic
├── assets.lua                  # Asset loading
│
├── fishing/                    # Fishing system
│   ├── fishing.lua             # Main fishing logic
│   ├── fishdata.lua            # Fish definitions
│   ├── baitsystem.lua          # Bait mechanics
│   ├── castingsystem.lua       # Casting phase
│   ├── reelingsystem.lua       # Reeling phase
│   ├── bitedetection.lua       # Bite detection
│   └── statisticssystem.lua    # Stats tracking
│
├── menu/                       # Menu system
│   ├── menu.lua                # Main menu
│   ├── menucontroller.lua      # Menu logic
│   ├── menurenderer.lua        # Menu rendering
│   ├── menudata.lua            # Menu options
│   └── settings.lua            # Settings menu
│
├── ui/                         # UI components
│   ├── ui.lua                  # Main UI
│   ├── journal.lua             # Catch journal
│   ├── catchdisplay.lua        # Catch popup
│   └── visualtacklebox.lua     # Bait selection
│
├── world/                      # World/environment
│   ├── world.lua               # World manager
│   ├── worldcontroller.lua     # World logic
│   ├── daynightcycle.lua       # Day/night system
│   ├── skyrenderer.lua         # Sky rendering
│   ├── terrainrenderer.lua     # Terrain rendering
│   ├── vegetation.lua          # Trees, grass
│   ├── structures.lua          # Buildings, docks
│   ├── lakeelements.lua        # Water effects
│   └── weather.lua             # Weather system
│
├── assets/                     # Game assets
│   ├── fish/                   # Fish sprites
│   ├── bait/                   # Bait sprites
│   └── ui/                     # UI graphics
│
├── dist/                       # Web build (generated)
├── game.love                   # Packaged game (generated)
├── serve.py                    # Dev server
└── build.sh                    # Build script
```

---

## Key Files to Understand

### main.lua
- Game entry point
- Initializes all systems
- Main game loop (update/draw)
- Input handling

### gamestate.lua
- Manages game states (menu, playing, paused, etc.)
- State transitions
- Screen transitions

### fishing/fishing.lua
- Core fishing mechanics
- Fishing state machine
- Bite detection
- Catch logic

### world/daynightcycle.lua
- Time progression
- Sky color changes
- Fish availability
- Lighting effects

### ui/journal.lua
- Catch history
- Fish encyclopedia
- Statistics

---

## Debugging Tips

### Enable Debug Mode

Add to `main.lua`:
```lua
DEBUG = true
```

Then use:
```lua
if DEBUG then
    print("Debug message:", variable)
end
```

### Check Console

Open browser console (F12) to see:
- Lua print statements
- JavaScript errors
- Network requests
- Performance metrics

### Use Browser DevTools

**Chrome/Firefox DevTools**:
- **Console** - See logs and errors
- **Network** - Check file loading
- **Performance** - Profile frame rate
- **Memory** - Check memory usage

### Test Specific Features

```bash
# Test fishing only
# Comment out menu code in main.lua
# Start directly in playing state

# Test day/night cycle
# Add debug keys to speed up time
# Press F1-F4 to change time scale
```

---

## Performance Optimization

### Profile Your Game

1. Open DevTools (F12)
2. Go to Performance tab
3. Record gameplay
4. Analyze frame times

### Common Bottlenecks

- **Too many sprites** - Reduce draw calls
- **Complex shaders** - Simplify or remove
- **Large images** - Compress or use atlases
- **Frequent allocations** - Cache objects

### Optimization Tips

1. **Use sprite atlases** - Combine images
2. **Batch draw calls** - Draw similar objects together
3. **Cache calculations** - Don't recalculate every frame
4. **Limit particles** - Cap particle count
5. **Use LOD** - Lower detail at distance

---

## Testing Checklist

Before rebuilding for deployment:

- [ ] All features work
- [ ] No console errors
- [ ] Game runs at 60 FPS
- [ ] Save/load works
- [ ] Menu navigation works
- [ ] Fishing mechanics work
- [ ] Day/night cycle works
- [ ] Journal displays correctly
- [ ] Settings apply correctly
- [ ] No memory leaks (play for 10+ minutes)

---

## Version Control

### Initialize Git

```bash
cd Love2d_Web
git init
git add .
git commit -m "Initial commit: Web port working"
```

### Workflow

```bash
# Make changes
nano fishing/fishdata.lua

# Test
bash build.sh
python3 serve.py

# Commit
git add .
git commit -m "Add new fish species"

# Push to GitHub
git push origin main
```

### .gitignore

Already included, but covers:
- `node_modules/`
- `dist/`
- `game.love`
- `.DS_Store`

---

## Collaboration

### Share Code

1. Push to GitHub
2. Share link with collaborators
3. They can clone and build

### Merge Changes

```bash
# Pull latest
git pull origin main

# Rebuild
bash build.sh

# Test
python3 serve.py
```

---

## Deployment Workflow

### Development → Testing → Production

```bash
# 1. Develop locally
nano fishing/fishdata.lua
bash Love2d_Web/build.sh
python3 Love2d_Web/serve.py

# 2. Test thoroughly
# Play for 10+ minutes
# Check all features
# Monitor console

# 3. Commit
git add .
git commit -m "Add new feature"

# 4. Deploy to itch.io
butler push Love2d_Web/dist/ username/hopeless-catch:web

# 5. Test on itch.io
# Play the web version
# Verify it works
```

---

## Future Enhancements

### Easy Additions

- ✅ New fish species
- ✅ New locations
- ✅ New UI elements
- ✅ New audio/music
- ✅ New graphics
- ✅ New game modes

### Medium Difficulty

- ⚠️ New fishing mechanics
- ⚠️ Procedural generation
- ⚠️ Advanced AI
- ⚠️ Complex puzzles

### Hard/Not Possible

- ❌ Multiplayer (requires backend)
- ❌ Lua threading
- ❌ FFI/C libraries
- ❌ Window resizing

---

## Resources

- **LÖVE Documentation**: https://love2d.org/wiki
- **Lua Guide**: https://www.lua.org/pil/
- **Game Dev Patterns**: https://gameprogrammingpatterns.com/
- **Pixel Art**: https://www.aseprite.org/

---

## Getting Help

### Debugging

1. Check browser console (F12)
2. Add print statements
3. Use browser DevTools
4. Check LÖVE documentation

### Community

- **LÖVE Forums**: https://love2d.org/forums
- **LÖVE Discord**: https://discord.gg/love2d
- **Game Dev Stack Exchange**: https://gamedev.stackexchange.com/

---

## Summary

**Development cycle**:
1. Edit `.lua` files
2. Run `bash Love2d_Web/build.sh`
3. Test with `python3 Love2d_Web/serve.py`
4. Repeat until satisfied
5. Deploy to itch.io

**Key points**:
- All 61 files are editable
- Rebuild takes ~1 second
- Test locally before deploying
- Use browser DevTools for debugging
- Commit changes to Git

**You're ready to keep building!** 🎣

Happy coding!
