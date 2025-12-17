{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  autoPatchelfHook,
  stdenv,
  nix-update-script,
  testers,
}:

let
  version = "1.0.164";
  
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
    "x86_64-linux" = "sha256-yDuxyGyngv09AcAnLBVNZxnNe55lDVc/SgM81n1kDOY=";
    "aarch64-linux" = "sha256-78X9ht1ebAqOWDGessje1iG3MkiEGLTXqe3wwjkfvWM=";
    "x86_64-darwin" = "sha256-eaTdhguJlSIyOVzxOCegy8IPkNiXrJzv8ZnPFRQQazY=";
    "aarch64-darwin" = "sha256-LX5xwdOBHYNd4V0zGrRk6QJ67dphXrPEVPdMYmq8T6Q=";
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

    install -Dm755 opencode $out/bin/opencode

    runHook postInstall
  '';

  passthru = {
    tests.version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "HOME=$(mktemp -d) opencode --version";
      inherit (finalAttrs) version;
    };
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
