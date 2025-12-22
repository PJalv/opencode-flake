{
  lib,
  vimUtils,
  fetchFromGitHub,
}:

vimUtils.buildVimPlugin {
  pname = "opencode-nvim";
  version = "main-2025-12-21";
  
  src = fetchFromGitHub {
    owner = "NickvanDyke";
    repo = "opencode.nvim";
    rev = "fef07f395ed8ce7818b6858443fa9fd0bcc406ad";
    hash = "sha256-4DGupWKiFZgIWstltWM6oY2vHeOwo+pnhXwDV319rkU=";
  };

  meta = {
    description = "Neovim integration for OpenCode AI assistant";
    longDescription = ''
      Integrate the OpenCode AI assistant with Neovim — streamline editor-aware
      research, reviews, and requests. Features auto-connect to OpenCode instances,
      prompt input with completions, editor context injection, and real-time buffer
      auto-reload.
    '';
    homepage = "https://github.com/NickvanDyke/opencode.nvim";
    license = lib.licenses.mit;
    maintainers = [
      {
        email = "sebastien.pahl@gmail.com";
        github = "spahl";
        name = "Sebastien Pahl";
      }
    ];
  };
}
