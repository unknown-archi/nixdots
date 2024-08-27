{ config, lib, pkgs, ... }:


{
   # ZSH
   programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    sessionVariables = {
      XCURSOR_THEME="Capitaine Cursors";
      XCURSOR_SIZE=21;
    };
 
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
      # done="mv $(pwd) "$(pwd)_DONE"';
      ubuntu_docker="sudo docker run -it ubuntu bash";
      chmox="chmod +x";
      cat="bat -p";
      lsa= "ls -a";
      # nixupdate = "save; sudo nixos-rebuild switch --flake ~/.dotfiles#mathieu";
      # homeupdate = "save; home-manager switch --flake ~/.dotfiles#mathieu";
      # john="~/tools/john/run/john";
    };

    initExtra = ''
	# My functions
	
	save() {
		if [ -z "$1" ]; then
			commit_message="Save"
		else
			commit_message="$1"
		fi

		git add .
		git commit -m "$commit_message"
		git push
	}

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

	nixupdate() {
		save $1
		sudo nixos-rebuild switch --flake ~/.dotfiles#mathieu
	}

	homeupdate() {
		save $1
		home-manager switch --flake ~/.dotfiles#mathieu
	}

	nixstall() {
		local package_name=$1
		local config_file="/home/mathieu/.dotfiles/configuration.nix"

		# Check if the package is already in the list
		if grep -q "$package_name" "$config_file"; then
			echo "Package '$package_name' is already in the list."
			return
		fi

		# Use sed to insert the package at the correct position
		sed -i "/environment.systemPackages = with pkgs;/,/];/ s/];/    $1\n&/" "$config_file"

		echo "Package '$package_name' has been added to your configuration.nix."
		nixupdate "Installed $package_name"
}
	nixrm() {
		local package_name=$1
		local config_file="/home/mathieu/.dotfiles/configuration.nix"

		# Check if the package is in the list
		if ! grep -q "$package_name" "$config_file"; then
			echo "Package '$package_name' is not in the list."
			return
		fi

		# Remove the package from the list
		sed -i "/environment.systemPackages = with pkgs;/,/];/s/^[[:space:]]*$package_name//g" "$config_file"
		sed -i "/environment.systemPackages = with pkgs;/,/];/s/,$//g" "$config_file"


		echo "Package '$package_name' has been removed from your configuration.nix."
		nixupdate "Uninstalled $package_name"
	}

	nixlist() {
		local config_file="/home/mathieu/.dotfiles/configuration.nix"

		# Extract lines between environment.systemPackages and the closing bracket
		sed -n '/environment.systemPackages = with pkgs;/,/];/p' "$config_file" | \
		# Remove the first and last lines (containing the opening and closing brackets)
		sed '1d;$d' | \
		# Trim leading/trailing spaces and commas
		sed 's/^[[:space:]]*//;s/[[:space:]]*,[[:space:]]*$//' | \
		# Filter out any empty lines
		sed '/^$/d'

		# Check if no packages were found
		if [[ $? -ne 0 ]]; then
			echo "No packages found in $config_file."
		fi
	}


	# Zoxide
	eval "$(zoxide init zsh)"
	# Powerlevel 10k
	source ~/.dotfiles/p10k.zsh
    '';

  };
}
