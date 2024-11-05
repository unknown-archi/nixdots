# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Enable Flakes and Nix commands
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  
  networking.hostName = "mathieu"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  networking.interfaces = {
  br0 = {
    ipv4 = {
      addresses = [
        {
          address = "192.168.1.100";
          prefixLength = 24;
        }
      ];
      gateway = "192.168.1.1";   # Adresse IP de la Livebox
      nameservers = [ "8.8.8.8" "8.8.4.4" ]; # Serveurs DNS (Google DNS)
    };
  };
};

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;

  # Enable Hyprland
  services.xserver.displayManager.gdm.wayland = true;  
  # services.displayManager.sddm.enable = true;
  programs.hyprland = {    
    enable = true;    
    xwayland.enable = true;
  }; 

  security.pam.services.hyprlock = { };

  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
  };
  
  # Enable QMK (Keyboard config)  
  hardware.keyboard.qmk.enable = true;

  # VIA
  services.udev.packages = [ pkgs.via ];

  # Enable Bluetooth
  hardware.bluetooth.enable = true;

  # Enable Bluetooth services
  services.blueman.enable = true;

  # Ensure Bluetooth audio support
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # Switch to WirePlumber
    wireplumber.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mathieu = {
    isNormalUser = true;
    description = "Mathieu";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "kvm" "docker" ];
    packages = with pkgs; [
    #  thunderbird
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCxaMaChsCwxzTcCGXnKMt0mUS05p8ABUsHxZ/l88SNhdOjlG7DABVJmTwL/oLoJmwOmOErvCNtEfr+zPkRq83ZsPBVTE4W4NqtcJv5zVBRjUGiTiorSvuNgsOm3L8d+UPToc+KEarDYxU6xiRG5JFNl56mzHKeO7X5jEPQvN9RKRLmUTmSV7NHpVS8KY0Y2ZCGDPW+GuX+CkIQbnfL38PZowaTh8qYMexIKELTHJ+Jbj0GzqYwKmfBSTGpgQStjFeo0o/v9wD1ZipOPEclO4rf5bfEBKm8uuOGcAh9iQc/6AKMCcDn9kS+OeeRfRHUHpQejoCsPQOr8myJa3ND4pAmt1hmkJIRrEwiO6RIIud4PzkEkXrprtYEiym1rBfk/xVJmhk+dNhCuWtrwTp6/wPPyXwC6i8TEqTFqoNSBVr7Yp9+MS6iVeN02pADZwXGEl7bKpFck/tu2BFkraISs7Gpxr3CGlLPLQm3t1n9gGQzSaG07oiA/14GT28ejIwfwyU= mathieu@mathieus-macbook-pro.home"
      # Ajoutez d'autres clés publiques ici si nécessaire
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;  

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    unzip
    curl
    vscode  
    bluez
    bluez-tools
    pavucontrol # Sound Manager
    blueman # Bluetooth Manager
    swaynotificationcenter
    webcord # Discord
    bat
    btop
    clang
    cmake        # Build system generator
    libevdev     # Library for handling input events
    libconfig    # Simple config file library
    glib.dev     # Core library for system utilities
    systemd      # System and service manager
    gcc          # GNU C/C++ compiler
    binutils     # Binary tools (assembler, linker, etc.)
    gnumake      # GNU Make tool
    automake     # Generate Makefile.in files
    autoconf     # Generate configure scripts
    pkg-config   # Helper tool for compiling applications
    cron
    docker
    ffmpeg
    gnupg
    git
    glow
    nmap
    obs-studio
    openvpn
    pandoc
    sqlite
    ninja
    xxd
    zoxide
    gparted
    parted
    hyprlock
    hypridle
    hyprcursor
    hyprpicker
    fira
    arandr # Screens GUI
    wlsunset # Gamma 
    zsh-powerlevel10k
    blackbox-terminal
    thefuck
    tldr
    todo
    wezterm
    weather-icons
    waybar
    flatpak
    gnome.nautilus
    kdeconnect
    burpsuite
    pamixer
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    mullvad-vpn
    loupe # Image viewer
    evince # PDF viewer
    eza # Better ls
    neovim
    vim
    chafa # In terminal image viewer
    fzf
    swaybg
    wl-clipboard
    glib
    gobject-introspection
    gtk3
    vlc
    prismlauncher # Minecraft
    virt-manager
    dnsmasq  # For network configuration
    bridge-utils # For bridging networks
    brave
    gimp
    telegram-desktop
    fd # Better find
    delta # Better git diff
    appimage-run
    libsecret

    # Qt Packages
    qt5.qtbase
    qt5.qtwayland
    qt5.qttools
    qt5.qtx11extras
    
    # Python
    python3Full
    pkgs.python3Packages.pip  # pip for installing Python packages
    pkgs.python3Packages.virtualenv # virtualenv for creating isolated environments    
    pkgs.python3Packages.dnspython
    pkgs.python3Packages.requests
    pkgs.python3Packages.dns
    pkgs.python3Packages.web3
    # pkgs.python3Packages.pandas
    # pkgs.python3Packages.numpy
    
    buttercup-desktop
    go

    # Games
    bottles
    mangohud # Gaming monitoring
    protonup
    lutris
    heroic
    file
    filezilla
    fileinfo
    nh
    wofi
    rofi
    tofi
    inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default # hyprcursor theme
    font-awesome
    signal-desktop-beta
    libreoffice
    via
    p7zip
    qmk
    whois
    hyprshot
    bitwarden-desktop
    bitwarden-cli
    resumed
    exiftool
    dig
    csvkit
    go-ethereum
    poetry

    jetbrains.datagrip
];

  # Enable zsh
  environment.shells = with pkgs; [ zsh ];
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  # Night light
  #services.gammastep = {
  #  enable = true;
  #  provider = "manual";
  #  latitude = 48.79;
  #  longitude = 2.3;
  #};

  # Enable Printer
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };


  # Fonts
  fonts.packages = with pkgs; [
    nerdfonts
    fira-code-symbols
    montserrat
  ];

  programs.thefuck.enable = true; # Useless ?


  # VIRTUALISATION -------------------------------
  # Enable the libvirtd service
  virtualisation.libvirtd = {
    enable = true;
  };

  # Specify the QEMU package
  virtualisation.libvirtd.qemu.package = pkgs.qemu_kvm;

  # (Optional) Additional libvirtd configuration
  virtualisation.libvirtd.extraConfig = ''
    unix_sock_group = "libvirtd"
    unix_sock_ro_perms = "0777"
    unix_sock_rw_perms = "0770"
  '';

  # BRIDGE  
  # networking = {
  # useDHCP = false; # On désactive le DHCP par défaut pour configurer le bridge
  # interfaces = {
  #   br0 = {
  #     useDHCP = true; # Le bridge utilisera DHCP pour obtenir une adresse IP
  #     ipv6.addresses = [ {
  #       address = "fe80::1";
  #       prefixLength = 64;
  #     } ];
  #   };
  # };
  # bridges = {
  #   br0.interfaces = [ "enp2s0" ]; # On ajoute enp2s0 au bridge
  # };
  # };

  # VIRTUALISATION --------------------------------

  ## DOCKER
  # Set the necessary kernel modules for Docker
  boot.kernelModules = [ "overlay" "br_netfilter" ];

  # Enable the Docker daemon (use systemd)
  systemd.services.docker = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.docker}/bin/dockerd";
    };
  };

  # GAMING --------------------------------
  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;
  
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  services.xserver.videoDrivers = ["amdgpu"];

  # GAMING --------------------------------

  # VPN
  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.package = pkgs.mullvad-vpn;
  
  # Link nautilus to browser
  services.dbus.enable = true;  

  # Set environment variables
  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/mathieu/.steam/root/compatibilitytools.d";
    FLAKE = "/home/mathieu/.dotfiles"; 
 };
  
  # Flatpak
  services.flatpak.enable = true;
  environment.sessionVariables.XDG_DATA_DIRS = [
    "/var/lib/flatpak/exports/share"
    "/home/mathieu/.local/share/flatpak/exports/share"
    "${pkgs.xdg_utils}/share"
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # SSH --------------------------------
  # Activer le service SSH
  services.openssh = {
    enable = true;
    settings = { 
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      AllowUsers = [ "mathieu" ];
    };
    ports = [ 2222 ];                         # Vous pouvez changer ce port pour une sécurité accrue, par exemple 2222
  };

  # Configurer le pare-feu pour autoriser le port SSH
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 2222 ]; # Ajoutez d'autres ports si vous en utilisez
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;      # Nombre maximal de tentatives avant bannissement
    bantime = "1h";
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}

