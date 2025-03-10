{
  programs.ssh = {
    enable = true;
    # Add your custom SSH configuration as extraConfig
    extraConfig = ''
      Host satory
          HostName 89.116.111.156
          User root
          Port 22
    '';
  };
}
