#!/bin/sh

player=$(playerctl -l 2> /dev/null)
if [[ $player == "" ]]; then
    echo ""
else
    title=$(playerctl -p $player metadata title)
    artist=$(playerctl -p $player metadata artist)

    echo "$artist - $title"
fi
