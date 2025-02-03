#! use/bin/env bash

current_directory="$(dirname $0)"

if [ `uname` = "Darwin" ]; then
  track="$(osascript $current_directory/current-track.sh)"
  if [ "$track" ]; then
    echo "🎵 $track"
  fi
fi
