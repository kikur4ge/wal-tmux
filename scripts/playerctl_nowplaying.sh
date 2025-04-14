#!/bin/sh

player=$(playerctl -l)
title=$(playerctl -p $player metadata title)
artist=$(playerctl -p $player metadata artist)

echo "$artist - $title"
