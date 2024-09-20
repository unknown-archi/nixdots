#!/bin/sh

# Check if a MAC address was provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <MAC_ADDRESS>"
    exit 1
fi

# Use the provided MAC address as the device's MAC
DEVICE_MAC="$1"

# Check the current connection status
STATUS=$(bluetoothctl info $DEVICE_MAC | grep "Connected:" | awk '{print $2}')

if [ "$STATUS" == "yes" ]; then
    # If the device is connected, disconnect it
    bluetoothctl disconnect $DEVICE_MAC
    echo "Disconnected from device $DEVICE_MAC"
else
    # If the device is not connected, connect to it
    bluetoothctl connect $DEVICE_MAC
    echo "Connected to device $DEVICE_MAC"
fi
