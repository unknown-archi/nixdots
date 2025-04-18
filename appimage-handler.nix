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

    # Use process substitution to avoid subshell issues with the loop variable
    while IFS= read -r -d $'\0' appimage_path; do
        filename=$(basename "$appimage_path")

        # --- Check for partial download files --- 
        # Common extensions: .part, .crdownload, .download, .tmp
        # Check for both 'SomeApp.AppImage.part' and 'SomeApp.part'
        base_name_no_ext="''${filename%.AppImage}"
        if [ -e "''${appimage_path}.part" ] || \
           [ -e "''${appimage_path}.crdownload" ] || \
           [ -e "''${appimage_path}.download" ] || \
           [ -e "''${appimage_path}.tmp" ] || \
           [ -e "''${DOWNLOADS_DIR}/''${base_name_no_ext}.part" ] || \
           [ -e "''${DOWNLOADS_DIR}/''${base_name_no_ext}.crdownload" ] || \
           [ -e "''${DOWNLOADS_DIR}/''${base_name_no_ext}.download" ] || \
           [ -e "''${DOWNLOADS_DIR}/''${base_name_no_ext}.tmp" ]; then
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

        # Check if exactly the same file already exists in destination
        if [ -f "$target_path" ]; then
            echo "File with same name already exists at target location: $target_path"
            
            # Create temporary files to store checksums for more reliable comparison
            source_checksum_file=$(mktemp)
            target_checksum_file=$(mktemp)
            
            # Get checksums with enhanced debugging
            echo "Computing checksum of downloaded file: $appimage_path"
            sha256sum "$appimage_path" > "$source_checksum_file"
            echo "Source checksum: $(cat "$source_checksum_file" | cut -d ' ' -f1)"
            
            echo "Computing checksum of existing file: $target_path"
            sha256sum "$target_path" > "$target_checksum_file"
            echo "Target checksum: $(cat "$target_checksum_file" | cut -d ' ' -f1)"
            
            # Extract just the hash portion for comparison
            source_sum=$(cat "$source_checksum_file" | cut -d ' ' -f1)
            target_sum=$(cat "$target_checksum_file" | cut -d ' ' -f1)
            
            # Compare with enhanced debugging
            echo "Comparing checksums: [$source_sum] and [$target_sum]"
            if [ "$source_sum" = "$target_sum" ]; then
                echo "==> MATCH: Files are identical based on SHA256 checksums."
                
                # Send notification that file is already installed
                notify_cmd="${pkgs.libnotify}/bin/notify-send"
                if command -v "$notify_cmd" > /dev/null; then
                    echo "Sending 'already installed' notification..."
                    "$notify_cmd" -i applications-utilities -a "AppImage Handler" \
                      "Already Installed: $app_name" "This exact version is already installed" 
                fi
                
                # Remove the duplicate file from downloads and cleanup
                echo "Removing duplicate file from downloads"
                rm "$appimage_path"
                rm "$source_checksum_file" "$target_checksum_file"
                continue
            else
                echo "==> DIFFERENT: Files have different checksums."
            fi
            
            # Clean up temporary files
            rm "$source_checksum_file" "$target_checksum_file"
            
            # Different checksums but same name = update case
            is_update=true
            echo "Same filename but different checksums. Treating as update."
        else
            is_update=false
            echo "No existing file found. This is a new installation."
        fi
        
        # Only count old versions with different names if we haven't already determined this is an update
        if [ "$is_update" != true ]; then
            # Find and count old versions to determine if this is an update
            old_count=$(find "$app_dir" -maxdepth 1 -type f -name '*.AppImage' ! -name "$filename" | wc -l)
            
            if [ "$old_count" -gt 0 ]; then
                is_update=true
                echo "Found $old_count old version(s). This is an update."
            fi
        fi
        
        # Extract version information for updates
        # More aggressively extract version info regardless of filename format
        extract_version() {
            local fname="$1"
            local appname="$2"
            
            # First attempt: Standard format - remove app name and .AppImage
            # CurseForge-1.2.3.AppImage → "1.2.3"
            local version=""
            
            # Remove app name prefix if present
            if [[ "$fname" == "$appname"* ]]; then
                version="''${fname#$appname}"
            else
                version="$fname"
            fi
            
            # Remove .AppImage extension
            version="''${version%.AppImage}"
            
            # Clean leading separators
            version="''${version#[-_]}"
            
            # If it's just the same as filename, try a more aggressive approach
            # Extract anything that looks like a version (numbers, dots, etc.)
            if [ -z "$version" ] || [ "$version" = "$fname" ]; then
                # This regex extracts typical version patterns
                version=$(echo "$fname" | grep -o '[0-9]\+\(\.[0-9]\+\)*\(-[0-9a-zA-Z]\+\)*')
            fi
            
            # If still no version, use filename as-is without .AppImage
            if [ -z "$version" ]; then
                version="''${fname%.AppImage}"
            fi
            
            echo "$version"
        }
        
        # Get versions
        new_version=$(extract_version "$filename" "$app_name")
        echo "New version: $new_version"
        
        # Identify old version if this is an update
        if [ "$is_update" = true ]; then
            echo "Preparing to remove old versions..."
            
            # Get first old file to extract version
            old_file=$(find "$app_dir" -maxdepth 1 -type f -name '*.AppImage' ! -name "$filename" | head -n 1)
            
            if [ -n "$old_file" ]; then
                old_filename=$(basename "$old_file")
                old_version=$(extract_version "$old_filename" "$app_name")
                echo "Old version: $old_version"
            else
                old_version="previous"
            fi
            
            # Now delete the old files
            echo "Removing old versions..."
            find "$app_dir" -maxdepth 1 -type f -name '*.AppImage' ! -name "$filename" -delete
        fi

        # Move and make executable
        echo "Moving to $target_path"
        mv "$appimage_path" "$target_path"
        chmod +x "$target_path"

        # Create .desktop file
        desktop_file="$DESKTOP_DIR/$app_name.desktop"
        echo "Creating/Updating $desktop_file"
        update_cmd="${pkgs.desktop-file-utils}/bin/update-desktop-database"
        if ! command -v "$update_cmd" > /dev/null; then
            update_cmd="update-desktop-database" # Fallback
        fi
        # Use appimage-run from pkgs
        appimage_runner="${pkgs.appimage-run}/bin/appimage-run"

        cat > "$desktop_file" << EOF
[Desktop Entry]
Name=$app_name
Exec=$appimage_runner $target_path %U
TryExec=$appimage_runner
Terminal=false
Type=Application
Categories=Utility;
StartupWMClass=$app_name
Icon=applications-utilities
EOF
        chmod +x "$desktop_file"

        PROCESSED_APPIMAGES=$((PROCESSED_APPIMAGES + 1))

        # Send notification with different messages for updates vs new installs
        notify_cmd="${pkgs.libnotify}/bin/notify-send"
        if command -v "$notify_cmd" > /dev/null; then
            echo "Sending notification..."
            if [ "$is_update" = true ]; then
                # Always use the version info for updates - use fallbacks if needed
                "$notify_cmd" -i applications-utilities -a "AppImage Handler" \
                  "Updated: $app_name" "From version $old_version to $new_version"
            else
                "$notify_cmd" -i applications-utilities -a "AppImage Handler" \
                  "Installed: $app_name" "AppImage ready to use"
            fi
        else
            echo "notify-send command not found, skipping notification."
        fi
    done < <(find "$DOWNLOADS_DIR" -maxdepth 1 -type f -name '*.AppImage' -print0)

    # Update desktop database if we processed any files
    if [ $PROCESSED_APPIMAGES -gt 0 ]; then
        echo "Attempting to update desktop database..."
        # Use desktop-file-utils directly
        update_cmd_path="${pkgs.desktop-file-utils}/bin/update-desktop-database"
        
        echo "Executing: $update_cmd_path $DESKTOP_DIR"
        # Directly execute using the full path
        "$update_cmd_path" "$DESKTOP_DIR"
        update_exit_code=$?
        
        echo "update-desktop-database finished with exit code: $update_exit_code"
        if [ $update_exit_code -ne 0 ]; then
            echo "Warning: update-desktop-database failed! Apps may not appear in launchers immediately."
            echo "Ensure pkgs.desktop-file-utils is available and provides update-desktop-database."
        fi
        echo "Done."
    else
        echo "No AppImages processed, skipping desktop database update."
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
      # PathChanged watches all file changes, which may trigger the service twice
      # PathModified is more specific to completed files
      # Use PathExistsGlob instead to watch for specific file patterns
      PathExistsGlob = "%h/Downloads/*.AppImage";
      
      # Add rate limiting to prevent multiple executions in quick succession
      # This helps avoid running the service twice for the same file
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.appimage-watcher = {
    Unit = {
      Description = "Handle downloaded AppImages";
      # Add rate limiting to prevent too frequent service execution
      # The path unit will queue events, but we'll wait before starting
      StartLimitIntervalSec = "30s";
      StartLimitBurst = 1;
    };
    Service = {
      Type = "oneshot";
      # Execute the script defined above
      ExecStart = "${handleAppimageScript}/bin/handle-appimage";
      # Add a 2 second delay before starting, to ensure files are fully written
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";

      # Standard sandboxing recommended by systemd.exec(5)
      # Adjust ProtectHome if script needs write access outside ~/AppImages or ~/.local/share/applications
      PrivateTmp = true;
      ProtectSystem = "strict";
      # Need network access if downloading icons etc. in the future, otherwise set ProtectNetwork=true
      # ProtectNetwork = true;
      # Need filesystem access, cannot use ProtectKernelTunables, ProtectKernelModules, ProtectControlGroups etc.
      NoNewPrivileges = true;
      # Add pkgs required by the script (find, sed, coreutils, desktop-file-utils, appimage-run, libnotify, grep)
      # Note: xdg-utils might still be needed if other xdg tools were used, but let's try without for now.
      Environment = "PATH=${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnused}/bin:${pkgs.desktop-file-utils}/bin:${pkgs.appimage-run}/bin:${pkgs.libnotify}/bin:${pkgs.gnugrep}/bin";
    };
    Install = {
      # Ensure it's not enabled by default, only triggered by the path unit
      WantedBy = [];
    };
  };

  # Ensure required tools are available
  # appimage-run and xdg-utils are likely already in systemPackages
  # libnotify (for notify-send) also seems to be available
  # We removed the redundant home.packages definition here.
} 