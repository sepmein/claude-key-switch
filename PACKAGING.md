# Package Manager Installation Guide

This guide explains how to publish claude-key-switch to various package managers.

## Homebrew (macOS/Linux)

### For Users

Once published, users can install with:

```bash
brew tap sepmein/claude-key-switch
brew install claude-key-switch
```

**The interactive installer runs automatically!** Users will be prompted to:
1. Choose their shell (bash or zsh)
2. Enter their API keys
3. Confirm installation

Or from the main tap (if accepted):

```bash
brew install claude-key-switch
```

### For Maintainers: Publishing to Homebrew

**Option 1: Create a Tap (Recommended for organization-owned projects)**

1. Create a new repository: `homebrew-claude-key-switch`
2. Add the formula:
   ```bash
   mkdir -p Formula
   cp HomebrewFormula/claude-key-switch.rb Formula/
   git add Formula/claude-key-switch.rb
   git commit -m "Add claude-key-switch formula"
   git push
   ```

3. Create a release with tag `v1.0.0`:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

4. Calculate SHA256 hash:
   ```bash
   curl -L https://github.com/sepmein/claude-key-switch/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256
   ```

5. Update formula with correct SHA256 hash

6. Users can install with:
   ```bash
   brew tap sepmein/claude-key-switch
   brew install claude-key-switch
   ```

**Option 2: Submit to Homebrew Core**

1. Fork `homebrew-core`
2. Add formula to `Formula/` directory
3. Create pull request following [Homebrew guidelines](https://docs.brew.sh/Adding-Software-to-Homebrew)

### Formula Location

The formula file is located at: `HomebrewFormula/claude-key-switch.rb`

---

## Scoop (Windows)

### For Users

Once published, users can install with:

```powershell
scoop bucket add sepmein https://github.com/sepmein/scoop-bucket
scoop install claude-key-switch
```

**The interactive installer runs automatically!** Users will be prompted to:
1. Choose their PowerShell profile
2. Enter their API keys
3. Confirm installation

### For Maintainers: Publishing to Scoop

**Option 1: Create a Bucket (Recommended)**

1. Create a new repository: `scoop-bucket`
2. Add the manifest:
   ```powershell
   mkdir bucket
   cp ScoopManifest/claude-key-switch.json bucket/
   git add bucket/claude-key-switch.json
   git commit -m "Add claude-key-switch manifest"
   git push
   ```

3. Create a release with tag `v1.0.0`:
   ```powershell
   git tag v1.0.0
   git push origin v1.0.0
   ```

4. Calculate SHA256 hash:
   ```powershell
   curl -L https://github.com/sepmein/claude-key-switch/archive/refs/tags/v1.0.0.zip -o temp.zip
   (Get-FileHash temp.zip -Algorithm SHA256).Hash.ToLower()
   Remove-Item temp.zip
   ```

5. Update manifest with correct hash

6. Users can install with:
   ```powershell
   scoop bucket add anthropics https://github.com/anthropics/scoop-bucket
   scoop install claude-key-switch
   ```

**Option 2: Submit to Main Bucket**

1. Fork `scoop-main` or `scoop-extras`
2. Add manifest to `bucket/` directory
3. Create pull request following [Scoop guidelines](https://github.com/ScoopInstaller/Scoop/wiki/Criteria-for-including-apps-in-the-main-bucket)

### Manifest Location

The manifest file is located at: `ScoopManifest/claude-key-switch.json`

---

## winget (Windows)

### For Users

Once published, users can install with:

```powershell
winget install claude-key-switch
```

### For Maintainers: Publishing to winget

1. Fork [microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs)

2. Create manifest directory:
   ```
   manifests/a/Anthropic/ClaudeKeySwitch/1.0.0/
   ```

3. Create manifests:
   - `Anthropic.ClaudeKeySwitch.installer.yaml`
   - `Anthropic.ClaudeKeySwitch.locale.en-US.yaml`
   - `Anthropic.ClaudeKeySwitch.yaml`

4. Submit pull request

5. Once merged, users can install with:
   ```powershell
   winget install Anthropic.ClaudeKeySwitch
   ```

**Note:** winget requires an installer (MSI, EXE, or MSIX). For PowerShell scripts, consider creating a simple installer or using Scoop instead.

---

## Release Checklist

Before creating a release:

- [ ] Update version in all files:
  - [ ] `claude-key-switch` (line 84)
  - [ ] `claude-key-switch.ps1` (line 44)
  - [ ] `HomebrewFormula/claude-key-switch.rb` (version)
  - [ ] `ScoopManifest/claude-key-switch.json` (version)
  - [ ] `README.md` (footer)

- [ ] Create git tag:
  ```bash
  git tag -a v1.0.0 -m "Release version 1.0.0"
  git push origin v1.0.0
  ```

- [ ] Create GitHub release with release notes

- [ ] Calculate SHA256 hashes:
  ```bash
  # For Homebrew (.tar.gz)
  curl -L https://github.com/sepmein/claude-key-switch/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256

  # For Scoop (.zip)
  curl -L https://github.com/sepmein/claude-key-switch/archive/refs/tags/v1.0.0.zip | shasum -a 256
  ```

- [ ] Update formula/manifest with correct SHA256 hashes

- [ ] Test installation:
  - [ ] `brew install` (from tap)
  - [ ] `scoop install` (from bucket)

- [ ] Announce release

---

## Comparison

| Package Manager | Platform | Target Audience | Complexity | Recommendation |
|----------------|----------|-----------------|------------|----------------|
| **Homebrew** | macOS/Linux | Developers | Low | ✅ **Best for macOS** |
| **Scoop** | Windows | Developers | Low | ✅ **Best for Windows** |
| **winget** | Windows | General users | Medium | ⚠️ Requires installer |
| **NPM** | Cross-platform | Node.js users | Medium | ❌ Adds dependencies |
| **pip** | Cross-platform | Python users | Medium | ❌ Wrong tool |

## Recommendations

1. **Start with Homebrew** (macOS) - Natural fit, easy setup
2. **Add Scoop** (Windows) - Developer-friendly, simple manifest
3. **Consider winget later** - Broader reach but requires installer creation
4. **Skip NPM/pip** - Not the right tool for shell scripts
