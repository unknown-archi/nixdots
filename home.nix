{ config, pkgs, ... }:

{

  imports = [
  
    ./sh.nix

  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "mathieu";
  home.homeDirectory = "/home/mathieu";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    pkgs.hello
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;   
    
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/mathieu/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  
  # ZSH
#   programs.zsh = {
#     enable = true;
#     enableCompletion = true;
#     autosuggestion.enable = true;
#     syntaxHighlighting.enable = true;
#     oh-my-zsh = {
#       enable = true;
#       plugins = [ "git" ];
#       theme = "robbyrussell";
#     };
#     shellAliases = {
#       notebook="/Users/mathieuhommet/opt/anaconda3/bin/jupyter_mac.command ; exit;";
#       python="python3";
#       py="python3";
#       pip="pip3";
#       pyvenv="python3 -m venv";
#       activate="source .venv/bin/activate";
#       getip="curl icanhazip.com";
#       # gsh="gcloud cloud-shell ssh --authorize-session";
#       vi="nvim";
#       cc="gcc -Wall -Werror -Wextra";
#       comp="gcc -Wall -Werror -Wextra *.c";
#       runc="comp; ./a.out";
#       trash="command rm -rf /tmp/trash ; echo 'Emptied the trash !'";
#       codeC="code *.c";
#       save="git add .; git commit -m 'Save'; git push";
#       # done="mv $(pwd) "$(pwd)_DONE"';
#       ubuntu_docker="sudo docker run -it ubuntu bash";
#       chmox="chmod +x";
#       cat="bat -p";
#       lsa= "ls -a";
#       nixupdate = "sudo nixos-rebuild switch --flake ~/.dotfiles#mathieu";
#       homeupdate = "home-manager switch --flake ~/.dotfiles#mathieu";
#       # john="~/tools/john/run/john";
#     };
#     # Add the zoxide initialization command
#     initExtra = ''
#       eval "$(zoxide init zsh)"
#     '';
#   };

  # Rofi
  programs.rofi = {
    enable = true;
    theme = "~/.dotfiles/rofi-theme.rasi";
  };

  # Tofi 
  # home.file.".config/tofi/config".source = ./tofi/config;

  # Hyprland
  home.file.".config/hypr/hyprland.conf".source = ./hyprland.conf;

  # Hyprlock
  home.file.".config/hypr/hyprlock.conf".source = ./hyprlock.conf;
  
  # HyprIdle
  home.file.".config/hypr/hypridle.conf".source = ./hypridle.conf;
  
  # Wezterm
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    extraConfig = builtins.readFile ./wezterm.lua;
  };
}


