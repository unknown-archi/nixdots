{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    # Existing configurations
    userName = "Mathieu";
    userEmail = "unknown-archi@users.noreply.github.com";

    # Add your Git configurations here
    extraConfig = {
      # Existing extraConfig settings if any
      core.editor = "nano";
      pull.rebase = true;

      # New configurations based on your .gitconfig snippet
      core.pager = "delta";

      interactive.diffFilter = "delta --color-only";

      delta = {
        navigate = true;        # use n and N to move between diff sections
        "side-by-side" = true;

        # Uncomment one of the following if you want to disable auto-detection of terminal colors
        # dark = true;
        # light = true;
      };

      merge.conflictstyle = "diff3";

      diff.colorMoved = "default";

      # Optionally, add your aliases back if they were in extraConfig
      alias.co = "checkout";
      alias.br = "branch";
      alias.ci = "commit";
      alias.st = "status";
    };
  };
}
