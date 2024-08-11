{ config, lib, pkgs, ... }:


{
   # ZSH
   programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    plugins = [   
      {                                                                                   
        name = "powerlevel10k";                                                           
        src = pkgs.zsh-powerlevel10k;                                                     
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";                         
      }
    ];

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "thefuck" ];
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
      msave= "git add .; git commit -m '$1'; git push";
      # done="mv $(pwd) "$(pwd)_DONE"';
      ubuntu_docker="sudo docker run -it ubuntu bash";
      chmox="chmod +x";
      cat="bat -p";
      lsa= "ls -a";
      nixupdate = "save; sudo nixos-rebuild switch --flake ~/.dotfiles#mathieu";
      homeupdate = "save; home-manager switch --flake ~/.dotfiles#mathieu";
      # john="~/tools/john/run/john";
    };

    initExtra = ''
      # My functions
      rm()
	{
	if [ ! -d "/tmp/trash" ]; then
		mkdir -p /tmp/trash
		echo "Created trash folder"
	fi

	if [ "$#" -eq 0 ]; then
		echo "No files provided."
		return 1
	fi

	mv $@ /tmp/trash
	echo "\033[1;32mMoved $@ to /tmp/trash.\033[0m"
	}

	# Create a new directory and cd into it
	nd(){mkdir $1; cd $1}

	# Get Local IP address
	localIP(){
		IP=$(ifconfig | grep 'inet ' | grep -Fv 127.0.0.1 | awk '{print $2}')
		echo "Your local IP address is : $IP"
	}

	# Creates a python HTTP server and displays its IP address
	shareLocal() {
		IP=$(ifconfig | grep 'inet ' | grep -Fv 127.0.0.1 | awk '{print $2}')
		echo "\nServing on : http://$IP:8000\n\n"
		python3 -m http.server
	}

    install() {
	local config_file="~/.dotfiles/configuration.nix"

	# Check if the package is already in the list
	if grep -q "$package_name" "$config_file"; then
		echo "Package '$package_name' is already in the list."
		return
	fi

	# Use sed to insert the package at the correct position
	sed -i "/environment.systemPackages = with pkgs;/,/];/ s/];/    $1\n    &/" "$config_file"

	echo "Package '$package_name' has been added to your configuration.nix."
}



      # Zoxide
      eval "$(zoxide init zsh)"
      # Powerlevel 10k
      source ~/.dotfiles/p10k.zsh
    '';

  };
}
