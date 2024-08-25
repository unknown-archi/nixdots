#!/bin/sh

case $1 in
	up)
		pamixer --unmute
                pamixer -i 5
		hyprctl dismissnotify
		hyprctl notify -1 3000 "rgb(42edde)" "Increased volume ($(pamixer --get-volume-human))"
		;;
	down)
		pamixer --unmute
                pamixer -d 5
		hyprctl dismissnotify
		hyprctl notify -1 3000 "rgb(42edde)" "Decreased volume ($(pamixer --get-volume-human))"
		;;
	mute)
		pamixer --toggle-mute
		if [ "$(pamixer --get-mute)" = "false" ]; then
			hyprctl dismissnotify
			hyprctl notify -1 3000 "rgb(42edde)" "Unmuted Volume"
		else
			hyprctl dismissnotify
			hyprctl notify -1 3000 "rgb(42edde)" "Muted Volume"
		fi
		;;
esac
