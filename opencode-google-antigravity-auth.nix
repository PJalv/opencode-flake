{
  lib,
  stdenvNoCC,
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

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp index.ts $out/
    cp package.json $out/
    cp -R src $out/
    cp README.md $out/ 2>/dev/null || true
    cp LICENSE $out/ 2>/dev/null || true

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
      
      To use this plugin, add it to your opencode.json configuration file or
      set the OPENCODE_PLUGINS environment variable to include this package.
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
