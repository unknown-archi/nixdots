# Function to toggle SSH mode with desktop notifications
ssh_mode() {
    STATE_FILE="$HOME/.ssh_mode_state"

    if [ "$1" = "on" ]; then
        echo "🔒 Enabling SSH Mode: Disabling Hypridle and Mullvad VPN..."
        notify-send -i dialog-information "SSH Mode" "Enabling SSH Mode: Disabling Hypridle and Mullvad VPN..."

        # Disable Hypridle
        echo "Stopping Hypridle..."
        notify-send -i dialog-information "SSH Mode" "Stopping Hypridle..."
        pkill hypridle
        if [ $? -eq 0 ]; then
            echo "✅ Hypridle disabled."
            notify-send -i dialog-ok "SSH Mode" "Hypridle disabled."
        else
            echo "⚠️ Hypridle was not running or failed to stop."
            notify-send -i dialog-warning "SSH Mode" "Hypridle was not running or failed to stop."
        fi

        # Disconnect Mullvad VPN
        echo "Disconnecting Mullvad VPN..."
        notify-send -i dialog-information "SSH Mode" "Disconnecting Mullvad VPN..."
        mullvad disconnect
        if [ $? -eq 0 ]; then
            echo "✅ Mullvad VPN disconnected."
            notify-send -i dialog-ok "SSH Mode" "Mullvad VPN disconnected."
        else
            echo "⚠️ Failed to disconnect Mullvad VPN."
            notify-send -i dialog-warning "SSH Mode" "Failed to disconnect Mullvad VPN."
        fi

        # Record state
        echo "on" > "$STATE_FILE"

        echo "🔐 SSH Mode enabled. You can now connect via SSH."
        notify-send -i dialog-ok "SSH Mode Enabled" "SSH Mode has been enabled. You can now connect via SSH."

    elif [ "$1" = "off" ]; then
        echo "🔓 Disabling SSH Mode: Enabling Hypridle and Mullvad VPN..."
        notify-send -i dialog-information "SSH Mode" "Disabling SSH Mode: Enabling Hypridle and Mullvad VPN..."

        # Enable Hypridle
        echo "Starting Hypridle..."
        notify-send -i dialog-information "SSH Mode" "Starting Hypridle..."
        hypridle &
        if [ $? -eq 0 ]; then
            echo "✅ Hypridle started."
            notify-send -i dialog-ok "SSH Mode" "Hypridle started."
        else
            echo "⚠️ Failed to start Hypridle."
            notify-send -i dialog-warning "SSH Mode" "Failed to start Hypridle."
        fi

        # Connect Mullvad VPN
        echo "Connecting Mullvad VPN..."
        notify-send -i dialog-information "SSH Mode" "Connecting Mullvad VPN..."
        mullvad connect
        if [ $? -eq 0 ]; then
            echo "✅ Mullvad VPN connected."
            notify-send -i dialog-ok "SSH Mode" "Mullvad VPN connected."
        else
            echo "⚠️ Failed to connect Mullvad VPN."
            notify-send -i dialog-warning "SSH Mode" "Failed to connect Mullvad VPN."
        fi

        # Record state
        echo "off" > "$STATE_FILE"

        echo "🔓 SSH Mode disabled. Regular operations resumed."
        notify-send -i dialog-ok "SSH Mode Disabled" "SSH Mode has been disabled. Regular operations resumed."

    elif [ "$1" = "status" ]; then
        if [ -f "$STATE_FILE" ]; then
            STATE=$(cat "$STATE_FILE")
            echo "🛡️ SSH Mode is currently '$STATE'."
            notify-send -i dialog-information "SSH Mode Status" "SSH Mode is currently '$STATE'."
        else
            echo "🛡️ SSH Mode state unknown."
            notify-send -i dialog-warning "SSH Mode Status" "SSH Mode state is unknown."
        fi

    else
        echo "❌ Usage: ssh_mode [on|off|status]"
        echo "   on      - Enable SSH Mode (disable Hypridle and disconnect VPN)"
        echo "   off     - Disable SSH Mode (enable Hypridle and connect VPN)"
        echo "   status  - Show current SSH Mode status"

        notify-send -i dialog-error "SSH Mode" "Invalid usage. Use: ssh_mode [on|off|status]"
    fi
}

