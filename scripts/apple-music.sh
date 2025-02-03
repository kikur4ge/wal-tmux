#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $current_dir/utils.sh

function current_track {
osascript <<EOD
  if application "Music" is running then
          tell application "Music"
                  if player state is playing then
                          return artist of current track & " - " & name of current track
                  end if
          end tell
  end if
EOD
}
current_track

function echo_track {
  if [ `uname` = "Darwin" ]; then
    track="$(current_track)"
    if [ "$track" ]; then
      echo "🎵 $track"
    fi
  fi
}
echo_track


main()
{
  # storing the refresh rate in the variable RATE, default is 5
  RATE=$(get_tmux_option "@dracula-refresh-rate" 5)

  echo_track
}

# run the main driver
main
