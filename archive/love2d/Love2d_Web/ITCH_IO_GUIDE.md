# Publishing to itch.io - Complete Guide

## Overview

itch.io is the perfect platform for indie games. Publishing your web port is straightforward.

---

## Prerequisites

- ✅ Game built and tested locally
- ✅ itch.io account (free)
- ✅ `Love2d_Web/dist/` folder ready

---

## Step 1: Create itch.io Account

1. Go to https://itch.io/
2. Click "Register"
3. Create account (email + password)
4. Verify email
5. Create username (this is your profile URL)

---

## Step 2: Create a New Project

1. Log in to itch.io
2. Click your profile icon → "Dashboard"
3. Click "Create new project"
4. Fill in:
   - **Project title**: "Hopeless Catch"
   - **Project URL**: "hopeless-catch" (auto-generated)
   - **Classification**: "Game"
   - **Kind of project**: "HTML"
   - **Uploads**: Leave blank for now

5. Click "Save project"

---

## Step 3: Build Your Game

```bash
bash Love2d_Web/build.sh
```

This creates `Love2d_Web/dist/` with:
- `index.html`
- `love.js`
- `love.wasm`
- `game.js`
- `game.data`
- `love.worker.js`
- `theme/` folder

---

## Step 4: Upload to itch.io

### Option A: Using Butler (Recommended)

Butler is itch.io's official upload tool. It's faster and more reliable.

#### Install Butler

**Linux/macOS**:
```bash
# Download
curl https://itch.io/api/butler/download/linux-amd64 -o butler
chmod +x butler
sudo mv butler /usr/local/bin/

# Verify
butler --version
```

**Windows**:
- Download from https://itch.io/docs/butler/installing
- Add to PATH

#### Upload with Butler

```bash
# 1. Login (one time)
butler login

# 2. Upload
butler push Love2d_Web/dist/ your-username/hopeless-catch:web

# 3. Verify
# Check itch.io project page - should see new upload
```

**Parameters**:
- `Love2d_Web/dist/` - Folder to upload
- `your-username` - Your itch.io username
- `hopeless-catch` - Your project URL
- `:web` - Channel (can be `:web`, `:windows`, `:mac`, etc.)

### Option B: Manual Upload (No Butler)

1. Go to your itch.io project
2. Click "Edit project"
3. Scroll to "Uploads" section
4. Click "Upload files"
5. Select all files from `Love2d_Web/dist/`:
   - `index.html`
   - `love.js`
   - `love.wasm`
   - `game.js`
   - `game.data`
   - `love.worker.js`
   - `theme/` folder (upload as folder)

6. After upload, click the upload
7. Check:
   - ✅ "This file will be played in the browser"
   - ✅ "Mark as executable"

8. Click "Save"

---

## Step 5: Configure Project Settings

### Basic Info

1. Click "Edit project"
2. Fill in:
   - **Title**: "Hopeless Catch"
   - **Short description**: "A peaceful fishing horror game"
   - **Description**: (see template below)
   - **Tags**: fishing, horror, puzzle, relaxing, pixel-art
   - **Genre**: Simulation, Adventure, Puzzle

### Game Settings

1. Scroll to "Embed options"
2. Check:
   - ✅ "Allow fullscreen"
   - ✅ "Embed in page"
   - ✅ "Embed in iframe"

3. Set viewport:
   - **Width**: 800
   - **Height**: 600

### Pricing

1. Scroll to "Pricing"
2. Choose:
   - **Free** (recommended for first release)
   - Or set a price if you want

3. Check "This project is free"

### Visibility

1. Scroll to "Visibility & access"
2. Set to **"Public"** (when ready)
3. Check "Published" (when ready)

---

## Step 6: Add Media

### Screenshots

1. Click "Edit project"
2. Scroll to "Screenshots"
3. Upload 3-5 screenshots:
   - Main menu
   - Fishing gameplay
   - Catch display
   - Day/night cycle
   - Journal

**Tips**:
- Use 800x600 resolution (same as game)
- Show different features
- Make them look appealing

### Cover Image

1. Scroll to "Cover image"
2. Upload a 315x250 image
3. This appears on itch.io listings

**Tips**:
- Use game artwork
- Make it eye-catching
- Include title

### GIF/Video (Optional)

1. Scroll to "Trailer"
2. Upload a short GIF or video
3. Shows gameplay in action

---

## Step 7: Write Description

### Template

```markdown
# Hopeless Catch

A cozy pixel art fishing game with a subtle secret. Unwind by the lake, catch 9 unique fish species, and discover what lurks in the tranquil waters after dark.

## Features

- 🎣 7-phase fishing system
- 🌙 Dynamic day/night cycle
- 🐟 9 unique fish species
- 📖 Fish encyclopedia
- ⚙️ Peaceful mode (disable anomalies)
- 💾 Save/load system
- 🎵 Procedurally generated music

## Gameplay

- **WASD/Arrows** - Move
- **SPACE** - Cast/Reel/Hook
- **B** - Tackle box
- **TAB** - Journal
- **H** - Rest in cabin
- **ESC** - Pause/Menu

## Day Experience

Beautiful sky transitions, animated water, peaceful music, and 5 day fish species.

## Night Experience

Darkened visuals, eerie music, 4 night creatures, and optional anomalies.

## Peaceful Mode

Toggle in settings to disable night creatures and anomalies for a stress-free experience.

## About

Built with LÖVE 2D and ported to web using love.js and Emscripten.

Enjoy your peaceful fishing adventure! 🎣
```

---

## Step 8: Test Before Publishing

1. Click "View page"
2. Play the game in browser
3. Test on mobile (if possible)
4. Check console (F12) for errors
5. Verify all features work:
   - Menu navigation
   - Fishing mechanics
   - Day/night cycle
   - Journal
   - Settings
   - Save/load

---

## Step 9: Publish

1. Go to project page
2. Click "Edit project"
3. Scroll to "Visibility & access"
4. Check:
   - ✅ "Published"
   - ✅ "Public"

5. Click "Save"
6. Your game is now live!

---

## After Publishing

### Share Your Game

- **Twitter**: "Just published Hopeless Catch on itch.io! 🎣 [link]"
- **Reddit**: Post to r/itch_io, r/indiegames, r/fishing
- **Discord**: Share in game dev communities
- **Friends**: Send the link!

### Monitor

- Check play count
- Read comments
- Fix bugs if reported
- Update if you add features

### Updates

To update your game:

```bash
# 1. Make changes to Lua files
# 2. Rebuild
bash Love2d_Web/build.sh

# 3. Upload new version
butler push Love2d_Web/dist/ your-username/hopeless-catch:web

# Or manually upload new files to itch.io
```

---

## Troubleshooting

### Game won't load on itch.io

- Check browser console (F12)
- Verify all files uploaded
- Ensure `index.html` is included
- Check file permissions

### Game loads but doesn't play

- Verify `love.wasm` uploaded
- Check `game.data` file size (should be ~15MB)
- Try different browser
- Check network tab for failed requests

### Performance issues

- Game may be slow on first load (downloading 15MB)
- Subsequent plays are faster (cached)
- Close other tabs
- Try different browser

### Controls not working

- Click game window to focus
- Try keyboard first
- Check browser console for errors

---

## itch.io Features

### Analytics

- View play count
- See where players are from
- Track engagement

### Comments

- Players can leave feedback
- Respond to comments
- Build community

### Ratings

- Players can rate your game
- Aim for 5 stars!

### Collections

- Add to collections
- Get featured on itch.io

---

## Tips for Success

1. **Write a good description** - Explain what makes your game unique
2. **Add screenshots** - Show gameplay, not just menus
3. **Be responsive** - Reply to comments and feedback
4. **Update regularly** - Add features, fix bugs
5. **Engage community** - Share on social media
6. **Ask for feedback** - Help improve the game

---

## itch.io Links

- **Main site**: https://itch.io/
- **Dashboard**: https://itch.io/dashboard
- **Butler docs**: https://itch.io/docs/butler/
- **Game jam**: https://itch.io/jams
- **Community**: https://itch.io/community

---

## Your Game URL

Once published, your game will be at:
```
https://your-username.itch.io/hopeless-catch
```

Share this link everywhere!

---

## Next Steps

1. ✅ Build: `bash Love2d_Web/build.sh`
2. ✅ Create itch.io account
3. ✅ Create project
4. ✅ Upload files (butler or manual)
5. ✅ Configure settings
6. ✅ Add media (screenshots, cover)
7. ✅ Write description
8. ✅ Test
9. ✅ Publish
10. ✅ Share!

---

**Your game is ready for the world!** 🎣

Good luck, and enjoy sharing Hopeless Catch with players!
