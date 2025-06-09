!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $current_dir/utils.sh

main()
{
  # set configuration option variables
  show_kubernetes_context_label=$(get_tmux_option "@everforest_tmux-kubernetes-context-label" "")
  eks_hide_arn=$(get_tmux_option "@everforest_tmux-kubernetes-eks-hide-arn" false)
  eks_extract_account=$(get_tmux_option "@everforest_tmux-kubernetes-eks-extract-account" false)
  hide_kubernetes_user=$(get_tmux_option "@everforest_tmux-kubernetes-hide-user" false)
  terraform_label=$(get_tmux_option "@everforest_tmux-terraform-label" "")
  show_fahrenheit=$(get_tmux_option "@everforest_tmux-show-fahrenheit" true)
  show_location=$(get_tmux_option "@everforest_tmux-show-location" true)
  fixed_location=$(get_tmux_option "@everforest_tmux-fixed-location")
  show_powerline=$(get_tmux_option "@everforest_tmux-show-powerline" false)
  show_flags=$(get_tmux_option "@everforest_tmux-show-flags" false)
  show_left_icon=$(get_tmux_option "@everforest_tmux-show-left-icon" smiley)
  show_left_icon_padding=$(get_tmux_option "@everforest_tmux-left-icon-padding" 1)
  show_military=$(get_tmux_option "@everforest_tmux-military-time" false)
  timezone=$(get_tmux_option "@everforest_tmux-set-timezone" "")
  show_timezone=$(get_tmux_option "@everforest_tmux-show-timezone" true)
  show_left_sep=$(get_tmux_option "@everforest_tmux-show-left-sep" )
  show_right_sep=$(get_tmux_option "@everforest_tmux-show-right-sep" )
  show_border_contrast=$(get_tmux_option "@everforest_tmux-border-contrast" false)
  show_day_month=$(get_tmux_option "@everforest_tmux-day-month" false)
  show_refresh=$(get_tmux_option "@everforest_tmux-refresh-rate" 5)
  show_synchronize_panes_label=$(get_tmux_option "@everforest_tmux-synchronize-panes-label" "Sync")
  time_format=$(get_tmux_option "@everforest_tmux-time-format" "")
  show_ssh_session_port=$(get_tmux_option "@everforest_tmux-show-ssh-session-port" false)
  IFS=' ' read -r -a plugins <<< $(get_tmux_option "@everforest_tmux-plugins" "battery network weather")
  show_empty_plugins=$(get_tmux_option "@everforest_tmux-show-empty-plugins" true)
  theme=$(get_tmux_option "@everforest_tmux-theme" dark)
  if [[ $theme == "dark" ]]; then
    # Dark Status Line
    source $current_dir/themes/dark.theme
  elif [[ $theme == "light" ]]; then
    # Light Status Line
    source $current_dir/themes/light.theme
  elif [[ $theme == "pywal" ]]; then
    # Light Status Line
    source $current_dir/themes/pywal.theme
  fi

  # Handle left icon configuration
  case $show_left_icon in
    smiley)
      left_icon="☺";;
    session)
      left_icon="#S";;
    window)
      left_icon="#W";;
    hostname)
      left_icon="#H";;
    shortname)
      left_icon="#h";;
    *)
      left_icon=$show_left_icon;;
  esac

  # Handle left icon padding
  padding=""
  if [ "$show_left_icon_padding" -gt "0" ]; then
    padding="$(printf '%*s' $show_left_icon_padding)"
  fi
  left_icon="$left_icon$padding"

  # Handle powerline option
  if $show_powerline; then
    right_sep="$show_right_sep"
    left_sep="$show_left_sep"
  fi

  # Set timezone unless hidden by configuration
  if [[ -z "$timezone" ]]; then
    case $show_timezone in
      false)
        timezone="";;
      true)
        timezone="#(date +%Z)";;
    esac
  fi

  case $show_flags in
    false)
      flags=""
      current_flags="";;
    true)
      flags="#{?window_flags,#[fg=${aqua}]#{window_flags},}"
      current_flags="#{?window_flags,#[fg=${dark_blue}]#{window_flags},}"
  esac

  # sets refresh interval to every 5 seconds
  tmux set-option -g status-interval $show_refresh

  # set the prefix + t time format
  if $show_military; then
    tmux set-option -g clock-mode-style 24
  else
    tmux set-option -g clock-mode-style 12
  fi

  # set length
  tmux set-option -g status-left-length 100
  tmux set-option -g status-right-length 100

  # pane border styling
  if $show_border_contrast; then
    tmux set-option -g pane-active-border-style "fg=${dark_blue}"
  else
    tmux set-option -g pane-active-border-style "fg=${aqua}"
  fi
  tmux set-option -g pane-border-style "fg=${gray}"

  # message styling
  tmux set-option -g message-style "bg=${gray},fg=${dark_gray}"

  # status bar
  tmux set-option -g status-style "bg=${gray},fg=${dark_gray}"

  # Status left
  if $show_powerline; then
    tmux set-option -g status-left "#[bg=${green},fg=${dark_gray}]#{?client_prefix,#[bg=${yellow}],} ${left_icon} #[fg=${green},bg=${gray}]#{?client_prefix,#[fg=${yellow}],}${left_sep}"
    powerbg=${gray}
  else
    tmux set-option -g status-left "#[bg=${green},fg=${dark_gray}]#{?client_prefix,#[bg=${yellow}],} ${left_icon}"
  fi

  # Status right
  tmux set-option -g status-right ""

  for plugin in "${plugins[@]}"; do

    if case $plugin in custom:*) true;; *) false;; esac; then
      script=${plugin#"custom:"}
      if [[ -x "${current_dir}/${script}" ]]; then
        IFS=' ' read -r -a colors <<<$(get_tmux_option "@everforest_tmux-custom-plugin-colors" "blue dark_gray")
        script="#($current_dir/${script})"
      else
        colors[0]="red"
        colors[1]="dark_gray"
        script="${script} not found!"
      fi

    elif [ $plugin = "cwd" ]; then
      IFS=' ' read -r -a colors  <<< $(get_tmux_option "@everforest_tmux-cwd-colors" "dark_gray dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/cwd.sh)"

    elif [ $plugin = "fossil" ]; then
      IFS=' ' read -r -a colors  <<< $(get_tmux_option "@everforest_tmux-fossil-colors" "green dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/fossil.sh)"

    elif [ $plugin = "git" ]; then
      IFS=' ' read -r -a colors  <<< $(get_tmux_option "@everforest_tmux-git-colors" "green dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/git.sh)"

    elif [ $plugin = "hg" ]; then
      IFS=' ' read -r -a colors  <<< $(get_tmux_option "@everforest_tmux-hg-colors" "green dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/hg.sh)"

    elif [ $plugin = "battery" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@everforest_tmux-battery-colors" "pink dark_gray")
      script="#($current_dir/battery.sh)"

    elif [ $plugin = "gpu-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@everforest_tmux-gpu-usage-colors" "pink dark_gray")
      script="#($current_dir/gpu_usage.sh)"

    elif [ $plugin = "gpu-ram-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@everforest_tmux-gpu-ram-usage-colors" "blue dark_gray")
      script="#($current_dir/gpu_ram_info.sh)"

    elif [ $plugin = "gpu-power-draw" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@everforest_tmux-gpu-power-draw-colors" "green dark_gray")
      script="#($current_dir/gpu_power.sh)"

    elif [ $plugin = "cpu-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@everforest_tmux-cpu-usage-colors" "orange dark_gray")
      script="#($current_dir/cpu_info.sh)"

    elif [ $plugin = "ram-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@everforest_tmux-ram-usage-colors" "blue dark_gray")
      script="#($current_dir/ram_info.sh)"

    elif [ $plugin = "tmux-ram-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@everforest_tmux-tmux-ram-usage-colors" "blue dark_gray")
      script="#($current_dir/tmux_ram_info.sh)"

    elif [ $plugin = "network" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@everforest_tmux-network-colors" "blue dark_gray")
      script="#($current_dir/network.sh)"

    elif [ $plugin = "network-bandwidth" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@everforest_tmux-network-bandwidth-colors" "blue dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/network_bandwidth.sh)"

    elif [ $plugin = "network-ping" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@everforest_tmux-network-ping-colors" "blue dark_gray")
      script="#($current_dir/network_ping.sh)"

    elif [ $plugin = "network-vpn" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@everforest_tmux-network-vpn-colors" "blue dark_gray")
      script="#($current_dir/network_vpn.sh)"

    elif [ $plugin = "attached-clients" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@everforest_tmux-attached-clients-colors" "blue dark_gray")
      script="#($current_dir/attached_clients.sh)"

    elif [ $plugin = "mpc" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@everforest_tmux-mpc-colors" "green dark_gray")
      script="#($current_dir/mpc.sh)"

    elif [ $plugin = "spotify-tui" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@everforest_tmux-spotify-tui-colors" "green dark_gray")
      script="#($current_dir/spotify-tui.sh)"

    elif [ $plugin = "apple-music" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@everforest_tmux-apple-music-colors" "green dark_gray")
      script="#($current_dir/apple-music.sh)"

    elif [ $plugin = "playerctl" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@everforest_tmux-playerctl-colors" "green dark_gray")
      script="#($current_dir/playerctl_nowplaying.sh)"

    elif [ $plugin = "kubernetes-context" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@everforest_tmux-kubernetes-context-colors" "blue dark_gray")
      script="#($current_dir/kubernetes_context.sh $eks_hide_arn $eks_extract_account $hide_kubernetes_user $show_kubernetes_context_label)"

    elif [ $plugin = "terraform" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@everforest_tmux-terraform-colors" "dark_blue dark_gray")
      script="#($current_dir/terraform.sh $terraform_label)"

    elif [ $plugin = "continuum" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@everforest_tmux-continuum-colors" "blue dark_gray")
      script="#($current_dir/continuum.sh)"

    elif [ $plugin = "weather" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@everforest_tmux-weather-colors" "orange dark_gray")
      script="#($current_dir/weather_wrapper.sh $show_fahrenheit $show_location $fixed_location)"

    elif [ $plugin = "time" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@everforest_tmux-time-colors" "aqua dark_gray")
      if [ -n "$time_format" ]; then
        script=${time_format}
      else
        if $show_day_month && $show_military ; then # military time and dd/mm
          script="%a %d/%m %R ${timezone} "
        elif $show_military; then # only military time
          script="%a %m/%d %R ${timezone} "
        elif $show_day_month; then # only dd/mm
          script="%a %d/%m %I:%M %p ${timezone} "
        else
          script="%a %m/%d %I:%M %p ${timezone} "
        fi
      fi
    elif [ $plugin = "synchronize-panes" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@everforest_tmux-synchronize-panes-colors" "blue dark_gray")
      script="#($current_dir/synchronize_panes.sh $show_synchronize_panes_label)"

    elif [ $plugin = "ssh-session" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@everforest_tmux-ssh-session-colors" "green dark_gray")
      script="#($current_dir/ssh_session.sh $show_ssh_session_port)"

    else
      continue
    fi

    if $show_powerline; then
      if $show_empty_plugins; then
        tmux set-option -ga status-right "#[fg=${!colors[0]},bg=${powerbg},nobold,nounderscore,noitalics]${right_sep}#[fg=${!colors[1]},bg=${!colors[0]}] $script "
      else
        tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[0]},nobold,nounderscore,noitalics]${right_sep}#[fg=${!colors[1]},bg=${!colors[0]}] $script }"
      fi
      powerbg=${!colors[0]}
    else
      if $show_empty_plugins; then
        tmux set-option -ga status-right "#[fg=${!colors[1]},bg=${!colors[0]}] $script "
      else
        tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[1]},bg=${!colors[0]}] $script }"
      fi
    fi
  done

  # Window option
  if $show_powerline; then
    tmux set-window-option -g window-status-current-format "#[fg=${gray},bg=${aqua}]${left_sep}#[fg=${dark_gray},bg=${dark_purple}] #I #W${current_flags} #[fg=${dark_purple},bg=${gray}]${left_sep}"
  else
    tmux set-window-option -g window-status-current-format "#[fg=${dark_gray},bg=${aqua}] #I #W${current_flags} "
  fi

  tmux set-window-option -g window-status-format "#[fg=${dark_gray}]#[bg=${gray}] #I #W${flags}"
  tmux set-window-option -g window-status-activity-style "bold"
  tmux set-window-option -g window-status-bell-style "bold"
}

# run main function
main
