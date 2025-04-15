{ config, pkgs, ... }:

let
  # Define the script content here
  handleAppimageScript = pkgs.writeShellScriptBin "handle-appimage" ''
    #!/bin/sh

    set -eu

    DOWNLOADS_DIR="''${HOME}/Downloads"
    APPIMAGES_DIR="''${HOME}/AppImages"
    DESKTOP_DIR="''${HOME}/.local/share/applications"
    PROCESSED_APPIMAGES=0

    # Ensure target directories exist
    mkdir -p "$APPIMAGES_DIR"
    mkdir -p "$DESKTOP_DIR"

    # Find AppImage files in Downloads
    # We remove the -mmin check as we now explicitly check for partial files
    find "$DOWNLOADS_DIR" -maxdepth 1 -type f -name '*.AppImage' -print0 | while IFS= read -r -d $'\0' appimage_path; do
        filename=$(basename "$appimage_path")

        # --- Check for partial download files --- 
        # Common extensions: .part, .crdownload, .download, .tmp
        # Check for both 'SomeApp.AppImage.part' and 'SomeApp.part'
        base_name_no_ext="''${filename%.AppImage}" # Escaped dollar sign
        if [ -e "''${appimage_path}.part" ] || \ # Escaped dollar sign
           [ -e "''${appimage_path}.crdownload" ] || \ # Escaped dollar sign
           [ -e "''${appimage_path}.download" ] || \ # Escaped dollar sign
           [ -e "''${appimage_path}.tmp" ] || \ # Escaped dollar sign
           [ -e "''${DOWNLOADS_DIR}/''${base_name_no_ext}.part" ] || \ # Escaped dollar signs
           [ -e "''${DOWNLOADS_DIR}/''${base_name_no_ext}.crdownload" ] || \ # Escaped dollar signs
           [ -e "''${DOWNLOADS_DIR}/''${base_name_no_ext}.download" ] || \ # Escaped dollar signs
           [ -e "''${DOWNLOADS_DIR}/''${base_name_no_ext}.tmp" ]; then # Escaped dollar signs
             echo "Skipping potential partial download: $filename"
             continue # Skip to the next file
        fi
        # --- End check ---

        echo "Processing: $filename"

        # Attempt to derive a clean application name
        name_base="''${filename%.AppImage}" # Escaped dollar sign
        name_base=$(echo "$name_base" | sed -E 's/-(x86_64|amd64|aarch64|armhf|i386)$//i')
        app_name=$(echo "$name_base" | sed -E 's/[-_](v?[0-9._]+|[0-9]+[a-zA-Z0-9._-]*)$//; s/[-_](latest|stable)$//i; s/[_-]$//')
        if [ -z "$app_name" ] || [ "$app_name" = "appimage" ]; then
            app_name="''${filename%.AppImage}" # Escaped dollar sign
        fi
        echo "Derived AppName: $app_name"

        app_dir="$APPIMAGES_DIR/$app_name"
        target_path="$app_dir/$filename"

        mkdir -p "$app_dir"

        # Find and remove old versions
        find "$app_dir" -maxdepth 1 -type f -name '*.AppImage' ! -name "$filename" -print -delete

        # Move and make executable
        echo "Moving to $target_path"
        mv "$appimage_path" "$target_path"
        chmod +x "$target_path"

        # Create .desktop file
        desktop_file="$DESKTOP_DIR/$app_name.desktop"
        echo "Creating/Updating $desktop_file"
        # Use pkgs.xdg-utils for update-desktop-database if possible,
        # otherwise assume it's in PATH
        local update_cmd="${pkgs.xdg-utils}/bin/update-desktop-database"
        if ! command -v "$update_cmd" > /dev/null; then
            update_cmd="update-desktop-database" # Fallback
        fi

        cat > "$desktop_file" << EOF
[Desktop Entry]
Name=$app_name
Exec=$target_path %U
TryExec=$target_path
Terminal=false
Type=Application
Categories=Utility;
# Icon needed? Might be extracted automatically, or add Icon=...
EOF
        chmod +x "$desktop_file"

        PROCESSED_APPIMAGES=$((PROCESSED_APPIMAGES + 1))
    done

    # Update desktop database if we processed any files
    if [ $PROCESSED_APPIMAGES -gt 0 ]; then
        echo "Updating desktop database..."
        if command -v "$update_cmd" > /dev/null; then
             "$update_cmd" "$DESKTOP_DIR"
        else
            echo "Warning: update-desktop-database command not found."
        fi
        echo "Done."
    else
        echo "No new AppImages found in $DOWNLOADS_DIR."
    fi
  '';

in
{
  # Systemd user units
  systemd.user.paths.appimage-watcher = {
    Unit = {
      Description = "Watch Downloads directory for new AppImages";
    };
    Path = {
      PathChanged = "%h/Downloads/";
      # Optional: Add a delay after modification to avoid triggering on partial downloads
      # PathModified=%h/Downloads/
      # UnitActivateRateLimitIntervalSec=30s
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.appimage-watcher = {
    Unit = {
      Description = "Handle downloaded AppImages";
      # Optional: Trigger only after path unit is inactive for a bit
      #PartOf = "appimage-watcher.path";
    };
    Service = {
      Type = "oneshot";
      # Execute the script defined above
      ExecStart = "${handleAppimageScript}/bin/handle-appimage";

      # Standard sandboxing recommended by systemd.exec(5)
      # Adjust ProtectHome if script needs write access outside ~/AppImages or ~/.local/share/applications
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-write"; # Needs write access to ~/AppImages, ~/.local/share/applications, read from ~/Downloads
      # Need network access if downloading icons etc. in the future, otherwise set ProtectNetwork=true
      # ProtectNetwork = true;
      # Need filesystem access, cannot use ProtectKernelTunables, ProtectKernelModules, ProtectControlGroups etc.
      NoNewPrivileges = true;
      # Add pkgs required by the script (find, sed, coreutils, xdg-utils)
      Environment = "PATH=${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnused}/bin:${pkgs.xdg-utils}/bin:${pkgs.gnugrep}/bin";
    };
    Install = {
      # Ensure it's not enabled by default, only triggered by the path unit
      WantedBy = [];
    };
  };

  # Ensure xdg-utils is available for update-desktop-database
  home.packages = [ pkgs.xdg-utils ];
} 