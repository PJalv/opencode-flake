# OpenCode TPS Meter - Integration Progress

## What

Adding `opencode-tps-meter` from [guard22/opencode-tps-meter](https://github.com/guard22/opencode-tps-meter) as a Nix flake package. This patches the OpenCode TUI to show a live TPS meter in the footer during streaming responses.

## Approach

Uses the **official OpenCode flake** (`github:anomalyco/opencode/v1.3.14`) as a source input, applies the TPS meter git patch via `overrideAttrs`, and lets the official build pipeline (`bun --bun ./script/build.ts --single`) compile everything into a standalone binary. No runtime bun dependency.

## Status: ✅ Complete

All automated tests pass. Ready for use.

### What was done

- Added two new flake inputs:
  - `opencode` → `github:anomalyco/opencode/v1.3.14` (pinned to latest TPS-patch-supported version)
  - `opencode-tps-patch` → `github:guard22/opencode-tps-meter/main` (non-flake, for reference)
- Added `opencode-tps-meter` package via `overrideAttrs` on the official opencode derivation
- Added `opencode-tps-meter` app entry
- Added `opencode-tps-meter` to devShell
- Patch hash verified: `sha256-VYCIefxvDlG0WC1r6IReFVz7NDFSgNN0jMbJSxKMXZU=`

### Test Results

| Test | Status |
|------|--------|
| `nix build .#opencode-tps-meter` | ✅ Pass - builds successfully |
| `./result/bin/opencode --version` | ✅ Pass - shows `1.3.14+cc50b77` |
| `nix flake check` | ✅ Pass - all checks pass |
| TPS meter in TUI footer | ⏸️ Manual testing required |

### Usage

```bash
# Build
nix build .#opencode-tps-meter

# Run directly
nix run .#opencode-tps-meter

# Or use in dev shell
nix develop
opencode --version  # Should show 1.3.14+cc50b77
```

### Known issues

- The `opencode-tps-meter` input is declared but not directly used (patch is fetched via `fetchpatch` URL). It could be removed or used to fetch the patch from the local source instead.
- Building from source takes significantly longer (~2-3 min) than the pre-built binary approach used by the main `opencode` package.

### Updating to a new TPS patch version

When a new opencode version gets a TPS patch in the upstream repo:

1. Change the `opencode` input URL to the new tag (e.g., `v1.3.15`)
2. Update the `fetchpatch` URL to the matching patch file
3. Update the hash (set to fake hash first, build will report correct one)
4. Update the `postPatch` version string substitution if needed
5. Run `nix flake lock --update-input opencode`
