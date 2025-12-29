{
  lib,
  stdenvNoCC,
  bun,
  fetchFromGitHub,
  writableTmpDirAsHomeHook,
  nix-update-script,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencode-google-antigravity-auth";
  version = "0.2.11";

  src = fetchFromGitHub {
    owner = "shekohex";
    repo = "opencode-google-antigravity-auth";
    tag = "v${finalAttrs.version}";
    hash = "sha256-pax2yMAxqJWM3RYTyxer8ZJwjyl2MgZ3+RfwZXvUDT0=";
  };

  node_modules = stdenvNoCC.mkDerivation {
    pname = "opencode-google-antigravity-auth-node_modules";
    inherit (finalAttrs) version src;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)

      # Install dependencies
      bun install \
        --force \
        --ignore-scripts \
        --no-progress

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/node_modules
      cp -R ./node_modules $out

      runHook postInstall
    '';

    # Required else we get errors that our fixed-output derivation references store paths
    dontFixup = true;

    outputHash =
      {
        x86_64-linux = "sha256-pUwNpbWhLTWhxqGw3mDnhLc6NG2NWjcNbH5ujseGOdE=";
      }
      .${stdenvNoCC.hostPlatform.system};
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  nativeBuildInputs = [
    bun
    writableTmpDirAsHomeHook
  ];

  configurePhase = ''
    runHook preConfigure

    cp -R ${finalAttrs.node_modules}/node_modules .

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    # Since this is a plugin, just copy the source files
    # No need to build TypeScript since OpenCode loads TypeScript directly
    mkdir -p $out/lib

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Install the plugin files and node_modules
    mkdir -p $out/lib/node_modules/opencode-google-antigravity-auth
    cp index.ts $out/lib/node_modules/opencode-google-antigravity-auth/
    cp package.json $out/lib/node_modules/opencode-google-antigravity-auth/
    cp -R src $out/lib/node_modules/opencode-google-antigravity-auth/
    cp -R ./node_modules $out/lib/

    runHook postInstall
  '';

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "OpenCode plugin providing Antigravity OAuth for Gemini models";
    longDescription = ''
      An OpenCode plugin that provides authentication to Google Gemini models
      using Antigravity OAuth. This enables seamless integration with Google's
      advanced AI models within the OpenCode environment.
    '';
    homepage = "https://github.com/shekohex/opencode-google-antigravity-auth";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    maintainers = [
      {
        github = "shekohex";
        name = "Ahmed Salama";
      }
    ];
  };
})
