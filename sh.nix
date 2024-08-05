{ config, pkgs, ... }:


{
   # ZSH
   programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;                                              
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "robbyrussell";
    };
    shellAliases = {
      notebook="/Users/mathieuhommet/opt/anaconda3/bin/jupyter_mac.command ; exit;";
      python="python3";
      py="python3";
      pip="pip3";
      pyvenv="python3 -m venv";
      activate="source .venv/bin/activate";
      getip="curl icanhazip.com";
      # gsh="gcloud cloud-shell ssh --authorize-session";
      vi="nvim";
      cc="gcc -Wall -Werror -Wextra";
      comp="gcc -Wall -Werror -Wextra *.c";
      runc="comp; ./a.out";
      trash="command rm -rf /tmp/trash ; echo 'Emptied the trash !'";
      codeC="code *.c";
      save="git add .; git commit -m 'Save'; git push";
      # done="mv $(pwd) "$(pwd)_DONE"';
      ubuntu_docker="sudo docker run -it ubuntu bash";
      chmox="chmod +x";
      cat="bat -p";
      lsa= "ls -a";
      nixupdate = "sudo nixos-rebuild switch --flake ~/.dotfiles#mathieu";
      homeupdate = "home-manager switch --flake ~/.dotfiles#mathieu";
      # john="~/tools/john/run/john";
    };
    # Add the zoxide initialization command
    initExtra = ''
      eval "$(zoxide init zsh)"
    '';
  };
}
