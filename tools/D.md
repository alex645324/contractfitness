- use P.md to execute the task below:

---

# **AI Agent Task: Deploy Web Build to GitHub Pages**

## Critical Information

**IMPORTANT**: This deployment requires a **complete clean rebuild** to avoid service worker caching issues. Flutter creates a service worker file even with `--pwa-strategy=none`, which must be manually deleted.

**Deployment Target**:
- Branch: `current branch`
- Folder: `docs/` (GitHub Pages serves from this folder)
- Domain: www.bas.today

---

## Steps

### 1. Clean Build Directory (on working branch)

**CRITICAL**: Complete deletion ensures no remnants from previous builds.

```bash
rm -rf build/web
```

### 2. Build for Web (No Service Worker)

Run Flutter build with service worker disabled:

```bash
flutter build web --pwa-strategy=none --base-href /
```

**Why:**
- `--pwa-strategy=none`: Attempts to disable service worker (Flutter still creates empty file)
- `--base-href /`: Ensures correct base href for custom domain www.bas.today

### 3. Manually Remove Service Worker

**CRITICAL**: Flutter creates this file despite the flag above. Must be deleted manually.

```bash
rm build/web/flutter_service_worker.js
```

Verify deletion:
```bash
ls -la build/web/ | grep -i service || echo "✓ No service worker file"
```

### 4. Add CNAME File

```bash
echo "www.bas.today" > build/web/CNAME
```

Verify:
```bash
cat build/web/CNAME
```

### 5. Backup Fresh Build

**CRITICAL**: Must backup before switching branches, otherwise build files will be lost.

```bash
cp -r build/web /tmp/fresh_build_$(date +%s)
```

### 6. Switch to Deployment Branch

Handle any file conflicts by removing conflicting directories:

```bash
# Remove conflicting directories if needed
rm -rf .dart_tool build

# Restore any modified files in working branch
git restore tools/D.md  # Or any other modified files

# Now switch
git checkout deployment_7
```

### 7. Complete Wipe of Docs Folder

**CRITICAL**: Delete entire folder, don't just replace files. This ensures zero remnants.

```bash
rm -rf docs/
```

### 8. Deploy Fresh Build

Find the backup timestamp and copy:

```bash
# Find latest backup
ls -dt /tmp/fresh_build_* | head -1

# Create docs and copy
mkdir docs
cp -r /tmp/fresh_build_[timestamp]/* docs/
```

### 9. Remove Platform Folders (if present)

Clean up any platform folders that shouldn't be in deployment branch:

```bash
rm -rf android/ ios/ macos/
```

### 10. Verify No Service Worker

**CRITICAL**: Confirm service worker is completely absent.

```bash
ls -la docs/ | grep -i service || echo "✓ Confirmed: No service worker in docs/"
```

### 11. Commit and Push

```bash
# Stage all changes including deletions
git add -A

# Verify what's being committed
git status

# Commit with descriptive message
git commit -m "Deploy: Complete clean rebuild with no service worker

- Deleted entire build/web and rebuilt from scratch
- Manually removed flutter_service_worker.js
- Completely wiped and recreated docs/ folder
- Ensures zero chance of stale cached files



# Push to deployment branch
git push origin deployment_7
```

### 12. Return to Working Branch

```bash
git checkout Prototype_7
```

---

## GitHub Pages Configuration

- **Repository**: momsbondgit/bas
- **Branch**: deployment_7
- **Folder**: docs/
- **Custom Domain**: www.bas.today (configured via CNAME file)
- **Auto-deployment**: Updates automatically when pushed

---

## Troubleshooting

### If users still see old version:
1. Verify service worker file is completely absent (not just empty)
2. Check GitHub Pages deployment status in repository settings
3. May need to wait 1-2 minutes for CDN propagation
4. Users may need hard refresh (Cmd+Shift+R / Ctrl+Shift+R)

### If branch checkout fails:
- Remove conflicting directories: `rm -rf .dart_tool build`
- Restore modified files: `git restore [filename]`

### If build is missing after branch switch:
- Use the backup in `/tmp/fresh_build_[timestamp]`
- Always backup BEFORE switching branches

---

## Key Learnings

1. **Complete wipe is essential**: Never trust incremental file replacement
2. **Manual service worker deletion required**: Flutter creates it despite `--pwa-strategy=none`
3. **Backup before branch switch**: Build files disappear when switching branches
4. **Verify absence, not just emptiness**: Service worker must be completely gone
5. **GitHub Pages serves from docs/**: Not from root of deployment_7 branch

---

## Goal

✅ Fresh, clean deployment with zero remnants
✅ No service worker file whatsoever
✅ Correct domain setup (www.bas.today)
✅ Build served from docs/ folder on deployment_7 branch