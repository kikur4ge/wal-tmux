#!/usr/bin/env bash
export LC_ALL=en_US.UTF-8

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $current_dir/utils.sh

main()
{
    player=$(playerctl -l | head -n 1)
    echo $player
    if [[ $player == "" ]]; then
        echo ""
    else
        title=$(playerctl -p $player metadata title)
        artist=$(playerctl -p $player metadata artist)

        RATE=$(get_tmux_option "@dracula-refresh-rate" 5)

        echo "🎵$artist - $title"
    fi
}
main
