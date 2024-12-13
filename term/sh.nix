{ config, lib, pkgs, ... }:


{
   # ZSH
   programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    sessionVariables = {
      # XCURSOR_THEME="Capitaine Cursors";
      # XCURSOR_SIZE=21;
      BAT_THEME="base16";
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
      pip="uv pip";
      #   pyvenv="python3 -m venv .venv --copies";
      activate="source .venv/bin/activate";
      venv="uv venv; activate"; 
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
      ls="eza --icons";
      sl="ls";
      lls="ls";
      tree="eza --icons --tree";
      wezterm="WAYLAND_DISPLAY=wayland-0 wezterm";
      alpine="sudo docker run -it --mount type=bind,source=/home/mathieu/VMs/alpine_docker/alpine_data,target=/mydata my_alpine";
      fix_python="fix-python --venv .venv";
      open_resume="docker run -p 3000:3000 open-resume";
      spf="superfile";
    };

    initExtra = ''
	WAYLAND_DISPLAY=wayland-1
	# Better autocompletion
	HISTFILE=$HOME/.zhistory
	SAVEHIST=1000
	HISTSIZE=999
	setopt share_history
	setopt hist_expire_dups_first
	setopt hist_ignore_dups
	setopt hist_verify
	bindkey '^[[A' history-search-backward
	bindkey '^[[B' history-search-forward	

	# My functions
	cd() { z $1; ls }

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

	findps(){ps -aux | grep $1}

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
		# sudo nixos-rebuild switch --flake ~/.dotfiles#mathieu
		nh os switch -u
	}

	homeupdate() {
		# home-manager switch --flake ~/.dotfiles#mathieu #  old command
		save $1
		nh home switch -u
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

       ssh_mode() { ~/.dotfiles/scripts/ssh_mode.sh $1 }
        csv() {
        	column -s, -t < $1 | less -#2 -N -S
	}


	# Zoxide
	eval "$(zoxide init zsh)"
	# Powerlevel 10k
	source ~/.dotfiles/p10k.zsh

	# Fzf
	eval "$(fzf --zsh)"
	
	# -- Use fd instead of fzf --

	export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix"
	export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
	export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix"

	# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
	# - The first argument to the function ($1) is the base path to start traversal
	# - See the source code (completion.{bash,zsh}) for the details.
	_fzf_compgen_path() {
	  fd --hidden --exclude .git . "$1"
	}

	# Use fd to generate the list for directory completion
	_fzf_compgen_dir() {
	  fd --type=d --hidden --exclude .git . "$1"
	}
	
	export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
	export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

	# Advanced customization of fzf options via _fzf_comprun function
	# - The first argument to the function is the name of the command.
	# - You should make sure to pass the rest of the arguments to fzf.
	_fzf_comprun() {
	  local command=$1
	  shift

	  case "$command" in
	    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
	    export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
	    ssh)          fzf --preview 'dig {}'                   "$@" ;;
	    *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
	  esac
	}
	
    '';

  };
}
