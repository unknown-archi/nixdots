{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    # Set your Git user name and email
    userName = "Mathieu";
    userEmail = "usmathieu@gmail.com";

    # Extra Git configurations
    extraConfig = {
      core.editor = "nano";        # Set default editor
      pull.rebase = true;         # Rebase on pull
      alias.co = "checkout";      # Short aliases
      alias.br = "branch";
      alias.ci = "commit";
      alias.st = "status";
    };
  };
}
