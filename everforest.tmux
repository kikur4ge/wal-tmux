#!/usr/bin/env bash

# source and run custom theme

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$current_dir/scripts/everforest-tmux.sh

# theme_option="@aforest-theme"
# default_theme="dark"
#
# get_tmux_option() {
# 	local option="$1"
# 	local default_value="$2"
# 	local option_value="$(tmux show-option -gqv "$option")"
# 	if [ -z "$option_value" ]; then
#     echo "$default_value"
# 	else
# 		echo "$option_value"
# 	fi
# }
#
# main() {
# 	local theme="$(get_tmux_option "$theme_option" "$default_theme")"
# 	$current_dir/scripts/aforest_${theme}.conf
# }
#
# main
#
