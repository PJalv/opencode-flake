# OpenCode Flake - Codebase Documentation

## Overview

This repository packages OpenCode (terminal-based AI assistant), OpenSpec (spec-driven development tool), and related plugins as Nix flakes. The project provides reproducible, cross-platform builds for Linux and macOS on both x86_64 and ARM64 architectures.

---

## Responsibility

### Primary Purpose

This Nix flake serves as a **packaging and distribution layer** for AI-powered development tools:

1. **OpenCode** - Terminal-based AI coding assistant that can build anything
2. **OpenSpec** - Spec-driven development tool for structured requirements and change tracking
3. **opencode.nvim** - Neovim plugin for deep editor integration with OpenCode
4. **opencode-google-antigravity-auth** - Plugin providing Google Gemini OAuth authentication

### Key Responsibilities

- **Package Management**: Create reproducible Nix derivations for all tools
- **Cross-Platform Support**: Build for Linux (x86_64, ARM64) and macOS (x86_64, ARM64)
- **Version Management**: Track and update versions from upstream GitHub releases
- **Dependency Resolution**: Handle all build-time and runtime dependencies
- **Automated Maintenance**: Provide scripts and workflows for zero-touch updates
- **Integration**: Enable seamless usage of OpenCode and OpenSpec together

---

## Design

### Architecture Pattern

The project follows the **Nix Flake Architecture** with these key patterns:

```
┌─────────────────────────────────────────────────────────────┐
│                      flake.nix                              │
│  (Entry point - defines packages, apps, devShells, checks)  │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│  package.nix  │   │ openspec.nix  │   │opencode-nvim  │
│  (OpenCode)   │   │  (OpenSpec)   │   │    .nix       │
└───────────────┘   └───────────────┘   └───────────────┘
        │                     │                     │
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ Pre-built     │   │ TypeScript    │   │ Lua Plugin    │
│ Binaries      │   │ Compilation   │   │ (No build)    │
│ (Bun compile) │   │ (Bun compile) │   │               │
└───────────────┘   └───────────────┘   └───────────────┘
```

### Package Derivations

#### 1. OpenCode (`package.nix`)

**Design Pattern**: Binary Distribution

```
Input: GitHub Release (pre-built binaries)
  ↓
Download platform-specific archive (tar.gz/zip)
  ↓
Extract standalone binary
  ↓
Apply autoPatchelfHook (Linux) for dynamic libraries
  ↓
Create wrapper script for environment setup
  ↓
Output: /bin/opencode
```

**Key Abstractions**:
- `platformMap`: Maps Nix system tuples to OpenCode platform/architecture naming
- `hashes`: Platform-specific SHA256 hashes for reproducible builds
- `dontStrip = true`: Preserves embedded version string in binary
- Wrapper script: Sets HOME, XDG paths, and plugin environment variables

**Platform Support Matrix**:
| Nix System | Platform | Arch | Archive Format |
|------------|----------|------|----------------|
| x86_64-linux | linux | x64 | tar.gz |
| aarch64-linux | linux | arm64 | tar.gz |
| x86_64-darwin | darwin | x64 | zip |
| aarch64-darwin | darwin | arm64 | zip |

#### 2. OpenSpec (`openspec.nix`)

**Design Pattern**: Two-Stage Build

```
Stage 1: node_modules (Fixed-Output Derivation)
  ↓
Download source from GitHub
  ↓
bun install --ignore-scripts
  ↓
Output: /node_modules (reproducible dependency tree)

Stage 2: Main Derivation
  ↓
Copy node_modules from Stage 1
  ↓
Inject version into CLI source (sed replacement)
  ↓
bun build --compile (TypeScript → JavaScript → Binary)
  ↓
Output: /bin/openspec
```

**Key Abstractions**:
- `bun-target`: Maps Nix systems to Bun target triples
- Fixed-output derivation for node_modules: Ensures reproducible dependency installation
- Version injection: Replaces dynamic `package.json` import with static version
- `dontStrip = true`: Preserves embedded version information

**Build Phases**:
1. `configurePhase`: Copy pre-built node_modules
2. `buildPhase`: Compile TypeScript, create standalone binary
3. `postFixup`: Set LD_LIBRARY_PATH on Linux for libstdc++

#### 3. opencode.nvim (`opencode-nvim.nix`)

**Design Pattern**: Pure Distribution

```
Input: GitHub Repository (main branch)
  ↓
fetchFromGitHub with specific commit
  ↓
vimUtils.buildVimPlugin
  ↓
Output: Neovim plugin package
```

**Key Abstractions**:
- Version format: `main-YYYY-MM-DD` (derived from commit date)
- No compilation: Pure Lua plugin
- Track latest commit from main branch

#### 4. opencode-google-antigravity-auth (`opencode-google-antigravity-auth.nix`)

**Design Pattern**: Source Distribution

```
Input: GitHub Release
  ↓
fetchFromGitHub with tag
  ↓
Copy source files (index.ts, package.json, src/)
  ↓
Output: Plugin source package
```

### Flake Structure

```nix
{
  description = "OpenCode - A powerful terminal-based AI assistant for developers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }: {
    # Packages for all supported systems
    packages = forEachSystem ({ pkgs, system }: {
      opencode = pkgs.callPackage ./package.nix { };
      openspec = pkgs.callPackage ./openspec.nix { };
      opencode-nvim = pkgs.callPackage ./opencode-nvim.nix { };
      opencode-google-antigravity-auth = pkgs.callPackage ./opencode-google-antigravity-auth.nix { };
      default = self.packages.${system}.opencode;
    });

    # Runnable applications
    apps = forEachSystem ({ pkgs, system }: {
      opencode = { type = "app"; program = "${self.packages.${system}.opencode}/bin/opencode"; };
      default = self.apps.${system}.opencode;
    });

    # Development environment
    devShells = forEachSystem ({ pkgs, system }: {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          self.packages.${system}.opencode
          self.packages.${system}.openspec
          self.packages.${system}.opencode-nvim
          self.packages.${system}.opencode-google-antigravity-auth
        ];
      };
    });

    # CI/CD checks
    checks = forEachSystem ({ pkgs, system }: {
      opencode = self.packages.${system}.opencode;
      openspec = self.packages.${system}.openspec;
      opencode-nvim = self.packages.${system}.opencode-nvim;
      opencode-google-antigravity-auth = self.packages.${system}.opencode-google-antigravity-auth;
    });
  };
}
```

---

## Flow

### Build Flow

#### OpenCode Build Flow

```
nix build .#opencode
  ↓
flake.nix → package.nix
  ↓
Determine system (e.g., x86_64-linux)
  ↓
Lookup platform info: platformMap["x86_64-linux"] = { platform="linux", arch="x64" }
  ↓
Lookup hash: hashes["x86_64-linux"]
  ↓
fetchurl: Download https://github.com/anomalyco/opencode/releases/download/v1.2.4/opencode-linux-x64.tar.gz
  ↓
Verify hash (SHA256)
  ↓
unpackPhase: tar -xzf $src
  ↓
nativeBuildInputs: autoPatchelfHook (Linux) / unzip (Darwin)
  ↓
buildInputs: stdenv.cc.cc.lib (Linux only)
  ↓
installPhase:
  - Install binary to $out/bin/opencode.real
  - Create wrapper script at $out/bin/opencode
  - Set environment variables (HOME, XDG_*, OPENCODE_USE_NPM_PLUGINS)
  ↓
Output: /nix/store/...-opencode-1.2.4/bin/opencode
```

#### OpenSpec Build Flow

```
nix build .#openspec
  ↓
flake.nix → openspec.nix
  ↓
Stage 1: Build node_modules (Fixed-Output Derivation)
  ↓
fetchFromGitHub: Fission-AI/OpenSpec@v1.1.1
  ↓
nativeBuildInputs: bun, writableTmpDirAsHomeHook
  ↓
buildPhase:
  - Set BUN_INSTALL_CACHE_DIR
  - bun install --force --ignore-scripts --no-progress
  ↓
installPhase: Copy node_modules to $out
  ↓
Verify outputHash matches expected value
  ↓
Stage 2: Main Derivation
  ↓
configurePhase: Copy node_modules from Stage 1
  ↓
buildPhase:
  - sed: Inject version into src/cli/index.ts
  - bun --bun node_modules/typescript/bin/tsc (TypeScript → JavaScript)
  - rm -rf openspec (avoid conflict)
  - bun build --compile --target=bun-linux-x64 --outfile=openspec-bin ./dist/cli/index.js
  ↓
installPhase: Install openspec-bin to $out/bin/openspec
  ↓
postFixup (Linux): wrapProgram with LD_LIBRARY_PATH
  ↓
Output: /nix/store/...-openspec-1.1.1/bin/openspec
```

### Update Flow

#### Automated Version Update Flow

```
./scripts/update-version.sh
  ↓
Fetch latest versions from GitHub API:
  - OpenCode: GET /repos/sst/opencode/releases/latest
  - OpenSpec: GET /repos/Fission-AI/OpenSpec/releases/latest
  - opencode.nvim: GET /repos/NickvanDyke/opencode.nvim/commits/main
  ↓
Compare with current versions in package files
  ↓
If updates needed:
  ↓
OpenCode Update:
  - Update version in package.nix
  - Download all 4 platform binaries
  - Compute SHA256 hashes for each
  - Update hashes attribute set
  ↓
OpenSpec Update:
  - nix-prefetch-url to get source hash
  - Convert to SRI format
  - Update version and hash in openspec.nix
  ↓
opencode.nvim Update:
  - Get latest commit SHA and date
  - nix-prefetch-url to get source hash
  - Update version, rev, and hash in opencode-nvim.nix
  ↓
Build and Test:
  - nix flake check (up to 3 attempts)
  - If hash mismatch: Update node_modules hash automatically
  ↓
Success: Display updated packages
```

### Integration Flow

#### OpenCode + OpenSpec Workflow

```
User runs: openspec init
  ↓
Select "OpenCode" as AI tool
  ↓
OpenSpec creates .opencode/command/ directory with:
  - openspec-proposal.md (slash command)
  - openspec-apply.md (slash command)
  - openspec-archive.md (slash command)
  ↓
User runs: opencode
  ↓
OpenCode loads slash commands from .opencode/command/
  ↓
User: /openspec-proposal Add user authentication
  ↓
OpenCode executes openspec proposal command
  ↓
OpenSpec creates openspec/changes/add-auth/ with:
  - proposal.md
  - tasks.md
  - specs/*.md
  ↓
User: /openspec-apply add-auth
  ↓
OpenCode executes openspec apply command
  ↓
OpenSpec implements tasks from proposal
  ↓
User: /openspec-archive add-auth
  ↓
OpenCode executes openspec archive command
  ↓
OpenSpec merges spec deltas and archives change
```

---

## Integration

### Dependencies

#### External Dependencies

**OpenCode**:
- Upstream: https://github.com/anomalyco/opencode
- Pre-built binaries (Bun-compiled)
- Runtime: None (standalone binary)
- Build-time: `autoPatchelfHook`, `unzip`, `makeWrapper`, `stdenv.cc.cc.lib`

**OpenSpec**:
- Upstream: https://github.com/Fission-AI/OpenSpec
- Source: TypeScript
- Build-time: `bun`, `typescript`, `makeBinaryWrapper`, `writableTmpDirAsHomeHook`
- Runtime: `stdenv.cc.cc.lib` (Linux only)

**opencode.nvim**:
- Upstream: https://github.com/NickvanDyke/opencode.nvim
- Source: Lua
- Build-time: None (pure distribution)
- Runtime: Neovim

**opencode-google-antigravity-auth**:
- Upstream: https://github.com/shekohex/opencode-google-antigravity-auth
- Source: TypeScript
- Build-time: None (source distribution)
- Runtime: OpenCode plugin system

#### Nix Dependencies

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
};
```

### Consumers

#### Direct Consumers

1. **Nix Users** (via `nix run`):
   ```bash
   nix run github:aodhanhayter/opencode-flake
   nix run github:aodhanhayter/opencode-flake#openspec
   ```

2. **Nix Profile Installations**:
   ```bash
   nix profile install github:aodhanhayter/opencode-flake
   ```

3. **NixOS System Configurations**:
   ```nix
   environment.systemPackages = [
     inputs.opencode-flake.packages.${pkgs.system}.opencode
     inputs.opencode-flake.packages.${pkgs.system}.openspec
   ];
   ```

4. **Home Manager Configurations**:
   ```nix
   home.packages = [
     inputs.opencode-flake.packages.${pkgs.system}.opencode
     inputs.opencode-flake.packages.${pkgs.system}.openspec
   ];
   ```

5. **Neovim Plugin Users**:
   ```nix
   programs.neovim.plugins = [ pkgs.opencode-nvim ];
   # or
   programs.nixvim.extraPlugins = [ pkgs.opencode-nvim ];
   ```

#### Integration Points

1. **OpenCode ↔ OpenSpec**:
   - Slash commands in `.opencode/command/`
   - Native workflow integration
   - Shared project context

2. **OpenCode ↔ opencode.nvim**:
   - Editor context injection
   - Real-time buffer synchronization
   - Command completion

3. **OpenCode ↔ opencode-google-antigravity-auth**:
   - Plugin system integration
   - OAuth authentication for Gemini models

### CI/CD Integration

#### GitHub Actions Workflow

**Automated Updates** (`update-opencode-nix.yml`):
- Schedule: Every 6 hours (00:15, 06:15, 12:15, 18:15 UTC)
- Tool: `nix-update`
- Actions:
  - Detect new releases from upstream
  - Update package versions
  - Compute new hashes
  - Run `nix flake check`
  - Create git tag and release
  - Push changes

**Manual Trigger**:
- Can be triggered via GitHub Actions UI
- Useful for immediate updates after upstream releases

### File Structure

```
opencode-flake/
├── flake.nix                          # Main flake definition
├── flake.lock                         # Nix input lock file
├── package.nix                        # OpenCode package (pre-built binaries)
├── openspec.nix                       # OpenSpec package (TypeScript compilation)
├── opencode-nvim.nix                  # Neovim plugin package
├── opencode-google-antigravity-auth.nix # Google Auth plugin package
├── README.md                          # User documentation
├── AGENTS.md                          # Development guide for contributors
├── INTEGRATION.md                     # Integration guide for OpenCode + OpenSpec
├── LICENSE                            # MIT License
├── .gitignore                         # Git ignore rules
├── scripts/
│   └── update-version.sh              # Automated version update script
└── result -> /nix/store/...           # Symlink to latest build output
```

### Key Files Summary

| File | Purpose | Lines | Key Components |
|------|---------|-------|----------------|
| `flake.nix` | Main flake entry point | 74 | packages, apps, devShells, checks |
| `package.nix` | OpenCode package definition | 137 | platformMap, hashes, wrapper script |
| `openspec.nix` | OpenSpec package definition | 171 | node_modules derivation, TypeScript compilation |
| `opencode-nvim.nix` | Neovim plugin package | 36 | fetchFromGitHub, buildVimPlugin |
| `opencode-google-antigravity-auth.nix` | Google Auth plugin | 59 | Source distribution |
| `update-version.sh` | Update automation script | 169 | Version detection, hash computation |
| `README.md` | User documentation | 168 | Installation, usage, CI/CD |
| `AGENTS.md` | Developer guide | 114 | Build commands, version updates |
| `INTEGRATION.md` | Integration guide | 159 | OpenCode + OpenSpec workflow |

---

## Development Workflow

### Local Development

```bash
# Enter development shell
nix develop

# Build packages
nix build                    # OpenCode (default)
nix build .#openspec         # OpenSpec
nix build .#opencode-nvim    # Neovim plugin

# Test packages
nix flake check              # Run all checks
nix run . -- --version       # Test OpenCode
nix run .#openspec -- --version  # Test OpenSpec

# Update versions
./scripts/update-version.sh  # Auto-update all packages
```

### Version Update Process

1. **Detection**: Script fetches latest versions from GitHub API
2. **Comparison**: Compares with current versions in package files
3. **Download**: Downloads binaries/sources for new versions
4. **Hash Computation**: Computes SHA256 hashes for reproducibility
5. **Update**: Updates version numbers and hashes in package files
6. **Build**: Runs `nix flake check` to verify builds
7. **Retry**: Automatically retries with updated node_modules hash if needed

### Code Style Conventions

- **Language**: Nix expressions with functional programming style
- **Indentation**: 2 spaces
- **Naming**: camelCase for variables, kebab-case for package names
- **Comments**: Use `#` for single-line comments
- **Error Handling**: Use `throw` for unsupported systems
- **Platform Support**: Maintain compatibility across all 4 platforms

---

## Testing

### Build Verification

```bash
# Test all packages
nix flake check

# Test individual packages
nix build .#opencode && ./result/bin/opencode --version
nix build .#openspec && ./result/bin/openspec --version
nix build .#opencode-nvim
```

### Version Verification

```bash
# Verify OpenCode version
nix run . -- --version

# Verify OpenSpec version
nix run .#openspec -- --version
```

### Integration Testing

```bash
# Test OpenCode + OpenSpec integration
nix develop
cd test-project
openspec init  # Select OpenCode
opencode       # Use slash commands
```

---

## Maintenance

### Automated Maintenance

- **Schedule**: Every 6 hours via GitHub Actions
- **Tool**: `nix-update` for reliable version detection
- **Coverage**: All packages (OpenCode, OpenSpec, opencode.nvim)
- **Zero-Touch**: Automatic testing, tagging, and releasing

### Manual Maintenance

```bash
# Update all packages
./scripts/update-version.sh

# Update specific package
nix-update --flake opencode
nix-update --flake openspec
nix-update --flake opencode-nvim
```

### Troubleshooting

**Hash Mismatch**:
- The update script automatically handles node_modules hash mismatches
- Retries build up to 3 times with updated hashes

**Build Failures**:
- Check `/tmp/nix-build.log` for detailed error messages
- Verify upstream releases are available
- Ensure all dependencies are in nixpkgs-unstable

**Platform Issues**:
- Verify platformMap entries in package.nix
- Check hashes for specific platform
- Test with `nix build` on target platform

---

## References

- **OpenCode**: https://github.com/anomalyco/opencode
- **OpenSpec**: https://github.com/Fission-AI/OpenSpec
- **opencode.nvim**: https://github.com/NickvanDyke/opencode.nvim
- **opencode-google-antigravity-auth**: https://github.com/shekohex/opencode-google-antigravity-auth
- **Nix Flakes**: https://nixos.wiki/wiki/Flakes
- **Nixpkgs**: https://github.com/NixOS/nixpkgs

---

## License

MIT License - See LICENSE file for details.
