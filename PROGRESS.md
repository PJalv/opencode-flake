# OpenCode TPS Meter - Integration Progress

## What

Adding `opencode-tps-meter` from [guard22/opencode-tps-meter](https://github.com/guard22/opencode-tps-meter) as a Nix flake package. This patches the OpenCode TUI to show a live TPS meter in the footer during streaming responses.

## Approach

Uses the **official OpenCode flake** (`github:anomalyco/opencode/v1.3.14`) as a source input, applies the TPS meter git patch via `overrideAttrs`, and lets the official build pipeline (`bun --bun ./script/build.ts --single`) compile everything into a standalone binary. No runtime bun dependency.

## Status: Ready to build

The flake.nix changes are complete and the patch hash is verified. The build has not been tested to completion yet due to disk space constraints on the current machine.

### What was done

- Added two new flake inputs:
  - `opencode` → `github:anomalyco/opencode/v1.3.14` (pinned to latest TPS-patch-supported version)
  - `opencode-tps-patch` → `github:guard22/opencode-tps-meter/main` (non-flake, for reference)
- Added `opencode-tps-meter` package via `overrideAttrs` on the official opencode derivation
- Added `opencode-tps-meter` app entry
- Added `opencode-tps-meter` to devShell
- Patch hash verified: `sha256-VYCIefxvDlG0WC1r6IReFVz7NDFSgNN0jMbJSxKMXZU=`

### What needs testing

1. **Build from source** (requires ~2-3GB disk space for node_modules):
   ```bash
   nix build .#opencode-tps-meter
   ```

2. **Verify the binary works**:
   ```bash
   ./result/bin/opencode --version
   ```

3. **Verify TPS meter appears** in the TUI footer during streaming

4. **Run flake check** (note: `opencode-tps-meter` is intentionally NOT in `checks` since it builds from source and would make checks very slow):
   ```bash
   nix flake check
   ```

### Potential issues to watch for

- The `postPatch` substituteInPlace for `meta.ts` may be unnecessary — the patch already sets fallback version strings, and the official build sets `OPENCODE_VERSION` via env. Remove it if `--version` works without it.
- The `opencode-tps-meter` input is declared but not directly used (patch is fetched via `fetchpatch` URL). It could be removed or used to fetch the patch from the local source instead.
- Building from source takes significantly longer than the pre-built binary approach used by the main `opencode` package.

### Updating to a new TPS patch version

When a new opencode version gets a TPS patch in the upstream repo:

1. Change the `opencode` input URL to the new tag (e.g., `v1.3.15`)
2. Update the `fetchpatch` URL to the matching patch file
3. Update the hash (set to fake hash first, build will report correct one)
4. Update the `postPatch` version string substitution if needed
5. Run `nix flake lock --update-input opencode`
