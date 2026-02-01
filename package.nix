{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  autoPatchelfHook,
  stdenv,
  nix-update-script,
  testers,
  makeWrapper,
  writeShellScript,
}:

let
  version = "1.1.48";
  
  # Map Nix system to OpenCode platform naming
  platformMap = {
    "x86_64-linux" = {
      platform = "linux";
      arch = "x64";
    };
    "aarch64-linux" = {
      platform = "linux";
      arch = "arm64";
    };
    "x86_64-darwin" = {
      platform = "darwin";
      arch = "x64";
    };
    "aarch64-darwin" = {
      platform = "darwin";
      arch = "arm64";
    };
  };

  # Platform-specific hashes for the pre-built binaries
  hashes = {
    "x86_64-linux" = "sha256-dSSIDDIhVDTgj8LqGlrKvjSRdFyKh1IjaDDQf8gegLw=";
    "aarch64-linux" = "sha256-9MF9SbPb7KBLno63gCWcsS5qC+/puKaZgWrgClIWHrU=";
    "x86_64-darwin" = "sha256-Ywn9u9kUTkszfVN2w5QkgNUltMcYGGU+PBi7LgM1xL8=";
    "aarch64-darwin" = "sha256-qEFBN53Qx6KxEb+W226Lz23EOCvPWFNIEyOd02IYKqU=";
  };

  # File extension varies by platform (tar.gz for Linux, zip for Darwin)
  fileExt = if stdenvNoCC.hostPlatform.isLinux then "tar.gz" else "zip";

  system = stdenvNoCC.hostPlatform.system;
  platformInfo = platformMap.${system} or (throw "Unsupported system: ${system}");
  hash = hashes.${system} or (throw "No hash for system: ${system}");

in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencode";
  inherit version;

  src = fetchurl {
    url = "https://github.com/sst/opencode/releases/download/v${version}/opencode-${platformInfo.platform}-${platformInfo.arch}.${fileExt}";
    inherit hash;
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    unzip
  ] ++ [
    makeWrapper
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  unpackPhase = ''
    runHook preUnpack
    
    ${if stdenvNoCC.hostPlatform.isLinux then ''
      tar -xzf $src
    '' else ''
      unzip -q $src
    ''}
    
    runHook postUnpack
  '';

  dontStrip = true;

   installPhase = ''
     runHook preInstall

     install -Dm755 opencode $out/bin/opencode.real

     # Create a shell wrapper script that sets up proper environment
     # This prevents the /homeless-shelter error from the hardcoded path in the binary
     cat > $out/bin/opencode << 'WRAPPER'
#!/bin/sh
export HOME="''${HOME:-$HOME}"
export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
export OPENCODE_USE_NPM_PLUGINS=1
exec $0.real "$@"
WRAPPER
     chmod +x $out/bin/opencode

     runHook postInstall
   '';

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "AI coding agent built for the terminal";
    longDescription = ''
      OpenCode is a terminal-based agent that can build anything.
      It combines TypeScript/JavaScript with native UI components
      to provide an interactive AI coding experience.
    '';
    homepage = "https://github.com/sst/opencode";
    license = lib.licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    maintainers = [
      {
        email = "jorge.alv.suarez@gmail.com";
        github = "PJalv";
        name = "Jorge Suarez";
      }
    ];
    mainProgram = "opencode";
  };
})
