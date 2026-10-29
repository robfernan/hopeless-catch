# Deployment Checklist

## Pre-Deployment

- [ ] All Lua code tested locally
- [ ] No console errors when running `python3 serve.py`
- [ ] Game plays correctly at http://localhost:3000/
- [ ] All features working (fishing, menu, journal, etc.)

## Build

- [ ] Run `bash Love2d_Web/build.sh`
- [ ] Verify `Love2d_Web/dist/` folder created
- [ ] Check `Love2d_Web/dist/` contains:
  - [ ] `index.html`
  - [ ] `love.js`
  - [ ] `love.wasm`
  - [ ] `game.js`
  - [ ] `game.data`
  - [ ] `love.worker.js`

## Server Configuration

Choose your deployment platform and configure headers:

### ☐ Vercel
- [ ] Create `vercel.json` in root
- [ ] Add COOP/COEP/CSP headers
- [ ] Deploy: `vercel deploy`

### ☐ Netlify
- [ ] Create `netlify.toml` in root
- [ ] Add COOP/COEP/CSP headers
- [ ] Deploy: `netlify deploy --prod`

### ☐ Nginx
- [ ] Add headers to nginx.conf
- [ ] Test: `nginx -t`
- [ ] Reload: `systemctl reload nginx`

### ☐ Apache
- [ ] Add headers to .htaccess or vhost config
- [ ] Enable mod_headers: `a2enmod headers`
- [ ] Reload: `systemctl reload apache2`

### ☐ GitHub Pages
- [ ] Create `_config.yml` with headers (if supported)
- [ ] Or use Netlify/Vercel instead (recommended)

### ☐ Custom Server
- [ ] Ensure server sends required headers
- [ ] Test with curl:
  ```bash
  curl -I http://your-domain.com/
  # Check for COOP, COEP, CSP headers
  ```

## Upload

- [ ] Upload `Love2d_Web/dist/` contents to web server
- [ ] Verify all files uploaded (check file count)
- [ ] Test file access:
  - [ ] http://your-domain.com/index.html
  - [ ] http://your-domain.com/love.wasm
  - [ ] http://your-domain.com/game.data

## Testing

- [ ] Open game in Chrome
- [ ] Open game in Firefox
- [ ] Open game in Safari
- [ ] Open game on mobile (iOS/Android)
- [ ] Check browser console (F12) - no critical errors
- [ ] Test all features:
  - [ ] Menu navigation
  - [ ] Fishing mechanics
  - [ ] Day/night cycle
  - [ ] Journal
  - [ ] Settings
  - [ ] Save/load

## Performance

- [ ] Game loads in < 30 seconds
- [ ] Game runs at 60 FPS
- [ ] No memory leaks (check DevTools)
- [ ] Network tab shows all files loaded

## Security

- [ ] HTTPS enabled (not HTTP)
- [ ] COOP header present: `Cross-Origin-Opener-Policy: same-origin`
- [ ] COEP header present: `Cross-Origin-Embedder-Policy: require-corp`
- [ ] CSP header present with `'unsafe-eval'` and `'unsafe-inline'`
- [ ] No sensitive data in console logs

## Monitoring

- [ ] Set up error tracking (Sentry, etc.)
- [ ] Monitor server logs for errors
- [ ] Check analytics for user engagement
- [ ] Monitor performance metrics

## Post-Deployment

- [ ] Share game link
- [ ] Update social media
- [ ] Monitor for issues
- [ ] Collect user feedback

---

## Required Headers (Copy-Paste)

### For All Platforms
```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
Content-Security-Policy: default-src 'self' https:; script-src 'self' 'unsafe-eval' 'unsafe-inline' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:
```

---

## Troubleshooting During Deployment

| Issue | Solution |
|-------|----------|
| "SharedArrayBuffer not defined" | Check COOP/COEP headers |
| "main.lua not found" | Verify game.data uploaded correctly |
| Game won't load | Check CSP header allows eval |
| Blank page | Check browser console for errors |
| 404 errors | Verify all files uploaded |
| Slow loading | Check file sizes, use CDN |

---

## Rollback Plan

If deployment fails:
1. Keep previous version backed up
2. Revert DNS/server config
3. Restore previous `dist/` folder
4. Test locally before re-deploying

---

## Success Criteria

✅ Game loads in browser
✅ No console errors
✅ All features work
✅ Runs at 60 FPS
✅ Works on multiple browsers
✅ Works on mobile

---

**Once all items are checked, your game is live!** 🎣
