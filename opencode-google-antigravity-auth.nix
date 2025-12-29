{
  lib,
  stdenvNoCC,
  bun,
  fetchFromGitHub,
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

  nativeBuildInputs = [ bun ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    # Copy the plugin files to the output directory
    # OpenCode plugins are TypeScript-based and loaded directly
    mkdir -p $out

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Install the plugin files
    cp index.ts $out/
    cp -R src $out/
    cp package.json $out/

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
