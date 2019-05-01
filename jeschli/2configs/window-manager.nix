{pkgs, environment, config, lib, ... }:

with pkgs;

let

  bar_update_interval = "1"; # Option

  i3_status_script = pkgs.writeScript "i3script.sh" ''
    #!/bin/sh

    # First time without wifi, because it blocks a long time
    BAR="$(${temp_status})"
    BAR+=" | $(${avail_disk})"
    BAR+=" | $(${volume_status})"
    BAR+=" | $(${brightness_status})"
    BAR+=" | $(${vpn_status})"
    BAR+=" | $(${eth_status})"
    BAR+=" | Wifi "
    BAR+=" | $(${date_status})"
    BAR+=" | $(${battery_status})"

    echo "$BAR"

    while true; do
      BAR="$(${temp_status})"
      BAR+=" | $(${avail_disk})"
      BAR+=" | $(${volume_status})"
      BAR+=" | $(${brightness_status})"
      BAR+=" | $(${vpn_status})"
      BAR+=" | $(${eth_status})"
      BAR+=" | $(${wifi_status})"
      BAR+=" | $(${date_status})"
      BAR+=" | $(${battery_status})"

      echo "$BAR"
      sleep ${bar_update_interval}
    done

    '';

  # TODO: Change name if you have a different vpn interface name
  vpn_status = pkgs.writeScript "vpn_status.sh" ''
    #!/bin/sh

    export PATH="$PATH:${gawk}/bin:${acpi}/bin:${coreutils}/bin:${gnugrep}/bin:${calc}/bin"

    VPN=""
    if  [ -e "/proc/sys/net/ipv4/conf/labs-vpn" ]; then
      VPN="Labs-VPN"
    elif [ -e "/proc/sys/net/ipv4/conf/office-vpn" ]; then
      VPN="Office-VPN"
    elif [ -e "/proc/sys/net/ipv4/conf/tun0" ]; then
      VPN="UKN-VPN"
    elif [ -e "/proc/sys/net/ipv4/conf/wireguard-home" ]; then
      VPN="Home-VPN"
    fi

    if [ "$VPN" = "" ]; then
      echo "VPN "
    else
      echo "$VPN "
    fi
   '';

  avail_disk = pkgs.writeScript "avail_disk.sh" ''
    #!/bin/sh
    export PATH="$PATH:${gawk}/bin:${coreutils}/bin:${gnugrep}/bin"

    avail=$(df / -h | tail -n1| awk '{print $(NF-2) }')
    echo "$avail "
    '';

  wifi_status = pkgs.writeScript "wifi_status.sh" ''
    #!/bin/sh

    export PATH="$PATH:${gawk}/bin:${coreutils}/bin:${gnugrep}/bin:${wirelesstools}/bin"

    ssid=$(iwgetid -r)
    quality=$(cat /proc/net/wireless | tail -n1 | awk '{ print $3}' | sed 's/\.//g')dB

    if [ "$ssid" = "" ]; then
      echo "Wifi "
    else
      echo "$quality at $ssid "
    fi
    '';


  eth_status = pkgs.writeScript "eth_status.sh" ''
    #!/bin/sh

    export PATH="$PATH:${gawk}/bin:${coreutils}/bin:${gnugrep}/bin:${iproute}/bin"

    first_eth=$(for i in /proc/sys/net/ipv4/conf/enp*; do basename "$i"; break; done)
    status=$(ip link show dev "$first_eth" | head -n1 | awk '{ print $9 }')

    if [ "$status" = "DOWN" ]; then
      echo ""
    else
      ip_addr=$(ip address show "$first_eth" | grep inet | head -n1 | awk '{ print $2 }' | sed 's/\/24//g')
      echo "$ip_addr "
    fi

    '';

  volume_status = pkgs.writeScript "volume_status.sh" ''
    #!/bin/sh

    export PATH="$PATH:${gawk}/bin:${coreutils}/bin:${gnugrep}/bin:${alsaUtils}/bin"

    status=$(amixer sget Master | grep 'Right:' | awk -F'[][]' '{ print $4 }')
    volume=$(amixer sget Master | grep 'Right:' | awk -F'[][]' '{ print $2 }')

    if [ "$status" = "off" ]; then
      echo "Muted "
    else
      echo "$volume "
    fi
      '';

  date_status = pkgs.writeScript "date_status.sh" ''
    #!/bin/sh

    export PATH="$PATH:${gawk}/bin:${coreutils}/bin:${gnugrep}/bin"

    echo "$(date +'%d.%m.%Y    %H:%M')"
      '';

  temp_status = pkgs.writeScript "temp_status.sh" ''
    #!/bin/sh

    export PATH="$PATH:${gawk}/bin:${acpi}/bin:${coreutils}/bin:${gnugrep}/bin:${calc}/bin"

    temp=$(acpi -t | awk '{print $4}' | calc -p)
    echo "$temp "
    '';

  brightness_status = pkgs.writeScript "brightness_status.sh" ''
      #!/bin/sh

      brightness=$(${pkgs.acpilight}/bin/xbacklight -get)
      echo "$brightness% "
    '';

  battery_status = with pkgs; pkgs.writeScript "battery_status.bash" ''
    #!${pkgs.bash}/bin/bash
    export PATH="$PATH:${gawk}/bin:${acpi}/bin:${coreutils}/bin:${gnugrep}/bin:${calc}/bin"

    get_battery_charging_status() {
    if [ "$(acpi -b | grep Discharging)" != "" ]; then
        echo "Discharging";
    else
        echo "Charging";
    fi
    }
    declare -a capacity_arr
    capacity_arr=(
    
    
    
    
    
    )

    # get charge of all batteries, combine them
    total_charge=$(acpi -b | awk '{print $4}' | grep -Eo "[0-9]+" | paste -sd+ | calc -p);

    # get amount of batteries in the device
    battery_number=$(acpi -b | wc -l);
    percent=$((total_charge / battery_number));
    index=$((percent / ( 100 / ''${#capacity_arr[@]}) ))

    if [ "$(get_battery_charging_status)" == "Charging" ]; then
      echo "$percent% "
    else
      echo "$percent% ''${capacity_arr[$index]}"
    fi
  '';

  random-wallpaper = pkgs.writeScript "random-wallpaper.sh" ''
    #!/bin/sh
    file=$(find ${config.wallpapers} -type f -print0 | shuf -z -n 1)
    ${pkgs.feh}/bin/feh --bg-scale "$file"
    '';

  reload_layout = pkgs.writeScript "reload_layout.sh" ''
    #!/bin/sh
    pkill gnome-terminal

    i3-msg append_layout ${shell_layout}

    for i in {1..16}
    do
      gnome-terminal &
    done
  '';

  single_shell_spawn = pkgs.writeScript "single_shell_spawn.sh" ''
    #!/bin/sh

    i3-msg focus parent
    i3-msg append_layout ${single_shell}
    for i in {1..2}
    do
      gnome-terminal
    done
    sleep 0.3
    i3-msg focus parent
    '';

  single_shell = pkgs.writeText "single-shell.json" ''
{
    "border": "pixel",
    "floating": "auto_off",
    "layout": "tabbed",
    "percent": 1,
    "type": "con",
    "nodes": [
        {
            "border": "pixel",
            "floating": "auto_off",
            "layout": "splith",
            "percent": 1,
            "type": "con",
            "nodes": [
                {
                    "border": "pixel",
                    "floating": "auto_off",
                    "layout": "splitv",
                    "percent": 0.5,
                    "type": "con",
                    "nodes": [
                        {
                            "border": "pixel",

                            "floating": "auto_off",
                            "geometry": {
                                "height": 434,
                                "width": 722,
                                "x": 0,
                                "y": 0
                            },
                            "percent": 0.5,
                            "swallows": [
                                {
                                    "class": "^Gnome\\-terminal$",
                                    "instance": "^gnome\\-terminal\\-server$"
                                }
                            ],
                            "type": "con"
                        },
                        {
                            "border": "pixel",

                            "floating": "auto_off",
                            "geometry": {
                                "height": 434,
                                "width": 722,
                                "x": 0,
                                "y": 0
                            },
                            "percent": 0.5,
                            "swallows": [
                                {
                                    "class": "^Gnome\\-terminal$",
                                    "instance": "^gnome\\-terminal\\-server$"
                                }
                            ],
                            "type": "con"
                        }
                    ]
                }
            ]
        }
    ]
}
  '';

  shell_layout = pkgs.writeText "shell-layout.json" ''
    {
    "border": "pixel",
    "floating": "auto_off",
    "layout": "tabbed",
    "percent": 1,
    "type": "con",
    "nodes": [
       {
            "border": "pixel",
            "floating": "auto_off",
            "layout": "splith",
            "percent": 1,
            "type": "con",
            "nodes": [
                {
                    "border": "pixel",
                    "floating": "auto_off",
                    "layout": "splitv",
                    "percent": 0.5,
                    "type": "con",
                    "nodes": [
                        {
                            "border": "pixel",

                            "floating": "auto_off",
                            "geometry": {
                                "height": 434,
                                "width": 722,
                                "x": 0,
                                "y": 0
                            },
                            "percent": 0.5,
                            "swallows": [
                                {
                                    "class": "^Gnome\\-terminal$",
                                    "instance": "^gnome\\-terminal\\-server$"
                                }
                            ],
                            "type": "con"
                        },
                        {
                            "border": "pixel",

                            "floating": "auto_off",
                            "geometry": {
                                "height": 434,
                                "width": 722,
                                "x": 0,
                                "y": 0
                            },
                            "percent": 0.5,
                            "swallows": [
                                {
                                    "class": "^Gnome\\-terminal$",
                                    "instance": "^gnome\\-terminal\\-server$"
                                }
                            ],
                            "type": "con"
                        }
                    ]
                },
                {
                    "border": "pixel",
                    "floating": "auto_off",
                    "layout": "splitv",
                    "percent": 0.5,
                    "type": "con",
                    "nodes": [
                        {
                            "border": "pixel",
                            "floating": "auto_off",
                            "layout": "splitv",
                            "percent": 1,
                            "type": "con",
                            "nodes": [
                                {
                                    "border": "pixel",

                                    "floating": "auto_off",
                                    "geometry": {
                                        "height": 434,
                                        "width": 722,
                                        "x": 0,
                                        "y": 0
                                    },
                                    "percent": 0.5,
                                    "swallows": [
                                        {
                                            "class": "^Gnome\\-terminal$",
                                            "instance": "^gnome\\-terminal\\-server$"
                                        }
                                    ],
                                    "type": "con"
                                },
                                {
                                    "border": "pixel",

                                    "floating": "auto_off",
                                    "geometry": {
                                        "height": 434,
                                        "width": 722,
                                        "x": 0,
                                        "y": 0
                                    },
                                    "percent": 0.5,
                                    "swallows": [
                                        {
                                            "class": "^Gnome\\-terminal$",
                                            "instance": "^gnome\\-terminal\\-server$"
                                        }
                                    ],
                                    "type": "con"
                                }
                            ]
                        }
                    ]
                }
            ]
        },

       {
            "border": "pixel",
            "floating": "auto_off",
            "layout": "splith",
            "percent": 1,
            "type": "con",
            "nodes": [
                {
                    "border": "pixel",
                    "floating": "auto_off",
                    "layout": "splitv",
                    "percent": 0.5,
                    "type": "con",
                    "nodes": [
                        {
                            "border": "pixel",

                            "floating": "auto_off",
                            "geometry": {
                                "height": 434,
                                "width": 722,
                                "x": 0,
                                "y": 0
                            },
                            "percent": 0.5,
                            "swallows": [
                                {
                                    "class": "^Gnome\\-terminal$",
                                    "instance": "^gnome\\-terminal\\-server$"
                                }
                            ],
                            "type": "con"
                        },
                        {
                            "border": "pixel",

                            "floating": "auto_off",
                            "geometry": {
                                "height": 434,
                                "width": 722,
                                "x": 0,
                                "y": 0
                            },
                            "percent": 0.5,
                            "swallows": [
                                {
                                    "class": "^Gnome\\-terminal$",
                                    "instance": "^gnome\\-terminal\\-server$"
                                }
                            ],
                            "type": "con"
                        }
                    ]
                },
                {
                    "border": "pixel",
                    "floating": "auto_off",
                    "layout": "splitv",
                    "percent": 0.5,
                    "type": "con",
                    "nodes": [
                        {
                            "border": "pixel",
                            "floating": "auto_off",
                            "layout": "splitv",
                            "percent": 1,
                            "type": "con",
                            "nodes": [
                                {
                                    "border": "pixel",

                                    "floating": "auto_off",
                                    "geometry": {
                                        "height": 434,
                                        "width": 722,
                                        "x": 0,
                                        "y": 0
                                    },
                                    "percent": 0.5,
                                    "swallows": [
                                        {
                                            "class": "^Gnome\\-terminal$",
                                            "instance": "^gnome\\-terminal\\-server$"
                                        }
                                    ],
                                    "type": "con"
                                },
                                {
                                    "border": "pixel",

                                    "floating": "auto_off",
                                    "geometry": {
                                        "height": 434,
                                        "width": 722,
                                        "x": 0,
                                        "y": 0
                                    },
                                    "percent": 0.5,
                                    "swallows": [
                                        {
                                            "class": "^Gnome\\-terminal$",
                                            "instance": "^gnome\\-terminal\\-server$"
                                        }
                                    ],
                                    "type": "con"
                                }
                            ]
                        }
                    ]
                }
            ]
        },

        {
            "border": "pixel",
            "floating": "auto_off",
            "layout": "splith",
            "percent": 1,
            "type": "con",
            "nodes": [
                {
                    "border": "pixel",
                    "floating": "auto_off",
                    "layout": "splitv",
                    "percent": 0.5,
                    "type": "con",
                    "nodes": [
                        {
                            "border": "pixel",

                            "floating": "auto_off",
                            "geometry": {
                                "height": 434,
                                "width": 722,
                                "x": 0,
                                "y": 0
                            },
                            "percent": 0.5,
                            "swallows": [
                                {
                                    "class": "^Gnome\\-terminal$",
                                    "instance": "^gnome\\-terminal\\-server$"
                                }
                            ],
                            "type": "con"
                        },
                        {
                            "border": "pixel",

                            "floating": "auto_off",
                            "geometry": {
                                "height": 434,
                                "width": 722,
                                "x": 0,
                                "y": 0
                            },
                            "percent": 0.5,
                            "swallows": [
                                {
                                    "class": "^Gnome\\-terminal$",
                                    "instance": "^gnome\\-terminal\\-server$"
                                }
                            ],
                            "type": "con"
                        }
                    ]
                },
                {
                    "border": "pixel",
                    "floating": "auto_off",
                    "layout": "splitv",
                    "percent": 0.5,
                    "type": "con",
                    "nodes": [
                        {
                            "border": "pixel",
                            "floating": "auto_off",
                            "layout": "splitv",
                            "percent": 1,
                            "type": "con",
                            "nodes": [
                                {
                                    "border": "pixel",

                                    "floating": "auto_off",
                                    "geometry": {
                                        "height": 434,
                                        "width": 722,
                                        "x": 0,
                                        "y": 0
                                    },
                                    "percent": 0.5,
                                    "swallows": [
                                        {
                                            "class": "^Gnome\\-terminal$",
                                            "instance": "^gnome\\-terminal\\-server$"
                                        }
                                    ],
                                    "type": "con"
                                },
                                {
                                    "border": "pixel",

                                    "floating": "auto_off",
                                    "geometry": {
                                        "height": 434,
                                        "width": 722,
                                        "x": 0,
                                        "y": 0
                                    },
                                    "percent": 0.5,
                                    "swallows": [
                                        {
                                            "class": "^Gnome\\-terminal$",
                                            "instance": "^gnome\\-terminal\\-server$"
                                        }
                                    ],
                                    "type": "con"
                                }
                            ]
                        }
                    ]
                }
            ]
        },


        {
            "border": "pixel",
            "floating": "auto_off",
            "layout": "splith",
            "percent": 1,
            "type": "con",
            "nodes": [
                {
                    "border": "pixel",
                    "floating": "auto_off",
                    "layout": "splitv",
                    "percent": 0.5,
                    "type": "con",
                    "nodes": [
                        {
                            "border": "pixel",

                            "floating": "auto_off",
                            "geometry": {
                                "height": 434,
                                "width": 722,
                                "x": 0,
                                "y": 0
                            },
                            "percent": 0.5,
                            "swallows": [
                                {
                                    "class": "^Gnome\\-terminal$",
                                    "instance": "^gnome\\-terminal\\-server$"
                                }
                            ],
                            "type": "con"
                        },
                        {
                            "border": "pixel",

                            "floating": "auto_off",
                            "geometry": {
                                "height": 434,
                                "width": 722,
                                "x": 0,
                                "y": 0
                            },
                            "percent": 0.5,
                            "swallows": [
                                {
                                    "class": "^Gnome\\-terminal$",
                                    "instance": "^gnome\\-terminal\\-server$"
                                }
                            ],
                            "type": "con"
                        }
                    ]
                },
                {
                    "border": "pixel",
                    "floating": "auto_off",
                    "layout": "splitv",
                    "percent": 0.5,
                    "type": "con",
                    "nodes": [
                        {
                            "border": "pixel",
                            "floating": "auto_off",
                            "layout": "splitv",
                            "percent": 1,
                            "type": "con",
                            "nodes": [
                                {
                                    "border": "pixel",

                                    "floating": "auto_off",
                                    "geometry": {
                                        "height": 434,
                                        "width": 722,
                                        "x": 0,
                                        "y": 0
                                    },
                                    "percent": 0.5,
                                    "swallows": [
                                        {
                                            "class": "^Gnome\\-terminal$",
                                            "instance": "^gnome\\-terminal\\-server$"
                                        }
                                    ],
                                    "type": "con"
                                },
                                {
                                    "border": "pixel",

                                    "floating": "auto_off",
                                    "geometry": {
                                        "height": 434,
                                        "width": 722,
                                        "x": 0,
                                        "y": 0
                                    },
                                    "percent": 0.5,
                                    "swallows": [
                                        {
                                            "class": "^Gnome\\-terminal$",
                                            "instance": "^gnome\\-terminal\\-server$"
                                        }
                                    ],
                                    "type": "con"
                                }
                            ]
                        }
                    ]
                }
            ]
        }
    ]
    }
  '';


  i3_conf_file =  pkgs.writeText "config" ''
    # This file has been auto-generated by i3-config-wizard(1).
    # It will not be overwritten, so edit it as you like.
    #
    # Should you change your keyboard layout some time, delete
    # this file and re-run i3-config-wizard(1).
    #

    # i3 config file (v4)
    #
    # Please see https://i3wm.org/docs/userguide.html for a complete reference!

    set $mod Mod4

    #######################
    #                     #
    #       LOOKS         #
    #                     #
    #######################
    # Font for window titles. Will also be used by the bar unless a different font
    # is used in the bar {} block below.
    font pango:Monospace 20, Icons 10
    hide_edge_borders smart
    new_window pixel 1
    new_float normal

    # Lockscreen shortcut
    bindsym $mod+l exec xscreensaver-command -l

    # start a terminal
    bindsym $mod+Return exec gnome-terminal


    # class                 border  backgr. text    indicator child_border
    client.focused          #4fceea #285577 #ffffff #2e9ef4   #285577
    client.focused_inactive #333333 #5f676a #ffffff #484e50   #5f676a
    client.unfocused        #333333 #222222 #888888 #292d2e   #222222

    # Size of border
    default_border pixel 2

    #######################
    #                     #
    #   DEFAULT CONFIG    #
    #                     #
    #######################
    floating_modifier $mod
    workspace_layout stacked
    default_orientation vertical

    # Kill focused window
    bindsym $mod+Shift+q kill

    # start dmenu (a program launcher)
    bindsym $mod+d exec ${pkgs.rofi}/bin/rofi -modi drun#run -combi-modi drun#run -show combi -show-icons -display-combi run -theme /etc/nixos/resources/gruvbox-dark-soft.rasi

    # Switch windows
    bindsym $mod+x exec ${pkgs.rofi}/bin/rofi -modi window -show window -auto-select -theme /etc/nixos/resources/gruvbox-dark-soft.rasi

    # Arrow keys for focus navigation
    bindsym $mod+Left focus left
    bindsym $mod+Down focus down
    bindsym $mod+Up focus up
    bindsym $mod+Right focus right

    # Move focused window
    bindsym $mod+Shift+j move left
    bindsym $mod+Shift+k move down
    bindsym $mod+Shift+l move up
    bindsym $mod+Shift+odiaeresis move right

    # Arrow keys for focused window movement
    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right

    # Split in horizontal orientation
    bindsym $mod+h split h

    # Split in vertical orientation
    bindsym $mod+v split v

    # Enter fullscreen mode for the focused container
    bindsym $mod+f fullscreen toggle

    # Change container layout (stacked, tabbed, toggle split)
    bindsym $mod+s layout stacking
    bindsym $mod+w layout tabbed
    bindsym $mod+e layout toggle split

    # Toggle tiling / floating
    bindsym $mod+Shift+space floating toggle

    # Change focus between tiling / floating windows
    bindsym $mod+space focus mode_toggle

    # Focus the parent container
    bindsym $mod+a focus parent

    # Reload the configuration file
    bindsym $mod+Shift+c reload

    # Restart i3 inplace (preserves your layout/session, can be used to upgrade i3)
    bindsym $mod+Shift+r restart

    # Exit i3 (logs you out of your X session)
    bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -b 'Yes, exit i3' 'i3-msg exit'"

    # Resize window. You can also use the mouse for that
    mode "resize" {
      # Pressing right will grow the window’s width.
      # Pressing up will shrink the window’s height.
      # Pressing down will grow the window’s height.
      bindsym a resize shrink width 10 px or 10 ppt
      bindsym s resize grow height 10 px or 10 ppt
      bindsym w resize shrink height 10 px or 10 ppt
      bindsym d resize grow width 10 px or 10 ppt

      # same bindings, but for the arrow keys
      bindsym Left resize shrink width 10 px or 10 ppt
      bindsym Down resize grow height 10 px or 10 ppt
      bindsym Up resize shrink height 10 px or 10 ppt
      bindsym Right resize grow width 10 px or 10 ppt

      # back to normal: Enter or Escape
      bindsym Return mode "default"
      bindsym Escape mode "default"
    }

    # Enable floating
    for_window [class="usbguard-applet-qt"] floating enable
    for_window [class="Nm-connection-editor"] floating enable
    for_window [class="Gnome-disks"] floating enable
    for_window [class="QtPass" title="QtPass"] move scratchpad

    # Make the currently focused window a scratchpad
    bindsym $mod+Shift+minus move scratchpad

    # Show the first scratchpad window
    bindsym $mod+minus scratchpad show

    # Show the sup-mail scratchpad window, if any.
    bindsym $mod+Shift+s [class="QtPass" title="QtPass"] scratchpad show

    #######################
    #                     #
    #     WORKSPACES      #
    #                     #
    #######################
    # Variables
    set $workspace1 "1: "
    set $workspace2 "2: "
    set $workspace3 "3: "
    set $workspace4 "4: "
    set $workspace5 "5: "
    set $workspace6 "6: "
    set $workspace7 "7"
    set $workspace8 "8"
    set $workspace9 "9"
    set $workspace10 "10"

    assign [class="quassel"] $workspace3
    assign [class="Firefox"] $workspace2
    assign [class="Daily"] $workspace5

    assign [class="VirtualBox Manager"] $workspace4
    assign [class="Virt-manager" title="Virtual Machine Manager"] $workspace4

    assign [class="libreoffice"] $workspace6
    assign [class="Eclipse"] $workspace6

    # Workspace lateral movement
    bindsym $mod+Next workspace next
    bindsym $mod+Prior workspace prev

    # Switch to workspace
    bindsym $mod+1 workspace $workspace1
    bindsym $mod+2 workspace $workspace2
    bindsym $mod+3 workspace $workspace3
    bindsym $mod+4 workspace $workspace4
    bindsym $mod+5 workspace $workspace5
    bindsym $mod+6 workspace $workspace6
    bindsym $mod+7 workspace $workspace7
    bindsym $mod+8 workspace $workspace8
    bindsym $mod+9 workspace $workspace9
    bindsym $mod+0 workspace $workspace10

    # Move workspace to other monitor
    bindsym $mod+Shift+Next move workspace to output right
    bindsym $mod+Shift+Prior move workspace to output left

    # move focused container to workspace
    bindsym $mod+Shift+1 move container to workspace $workspace1
    bindsym $mod+Shift+2 move container to workspace $workspace2
    bindsym $mod+Shift+3 move container to workspace $workspace3
    bindsym $mod+Shift+4 move container to workspace $workspace4
    bindsym $mod+Shift+5 move container to workspace $workspace5
    bindsym $mod+Shift+6 move container to workspace $workspace6
    bindsym $mod+Shift+7 move container to workspace $workspace7
    bindsym $mod+Shift+8 move container to workspace $workspace8
    bindsym $mod+Shift+9 move container to workspace $workspace9
    bindsym $mod+Shift+0 move container to workspace $workspace10


    #######################
    #                     #
    #  FUNCTION KEYS      #
    #                     #
    #######################
    # Backlight controls
    bindsym XF86MonBrightnessUp exec --no-startup-id xbacklight +10
    bindsym XF86MonBrightnessDown exec --no-startup-id xbacklight -10

    # Pulse Audio controls
    bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume 0 +5% #increase sound volume
    bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume 0 -5% #decrease sound volume
    bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute 0 toggle # mute sound
    bindsym XF86AudioMicMute exec --no-startup-id  amixer set Capture toggle

    #######################
    #                     #
    #  CONVENIENCE KEYS   #
    #                     #
    #######################
    bindsym Shift+Alt+3 exec screenshot

    #######################
    #                     #
    #    WINDOW LAYOUT    #
    #                     #
    #######################
    bindsym XF86LaunchA exec --no-startup-id ${reload_layout}
    bindsym XF86Explorer exec --no-startup-id ${single_shell_spawn}
    bindsym Shift+F11 exec --no-startup-id ${reload_layout}
    bindsym Shift+F12 exec --no-startup-id ${single_shell_spawn}


    bar {
        status_command ${i3_status_script}
        mode dock
        position top
        tray_output none

        font pango:monospace 14

        # Scrolling on bar changes volume
        bindsym button4 exec --no-startup-id pactl set-sink-volume 0 +5%
        bindsym button5 exec --no-startup-id pactl set-sink-volume 0 +-5%

        # Right mouse click mutes the volume
        bindsym button3 exec --no-startup-id pactl set-sink-mute 0 toggle


        colors {
          background #ffffff00
          statusline #ffe066

          inactive_workspace #ffffff00 #ffffff00 #ffe066
          active_workspace #ffffff00 #ffffff00 #3f3f3f
          urgent_workspace #ffffff00 #ffffff00 #ff8533
        }
    }

    #######################
    #                     #
    #       AUTORUNS      #
    #                     #
    #######################
    ## Start 16 gnome shells
    exec i3-msg 'workspace $workspace1;' && ${reload_layout}

    # Start firefox
    exec --no-startup-id ${pkgs.firefox}/bin/firefox --ProfileManager --new-instance --setDefaultBrowser

    # Quassel client
    exec --no-startup-id ${pkgs.quasselClient}/bin/quasselclient

    # Random wallpaper
    exec_always--no-startup-id ${random-wallpaper}

    # Start Qt-Pass
    exec ${pkgs.qtpass}/bin/qtpass
  '';

in {
  services.xserver.enable = true;
  services.xserver.layout = "de";

  # Enable i3 Window Manager
  services.xserver.windowManager.i3 = {
    enable = true;
    package = pkgs.i3;
    configFile = i3_conf_file;
    extraSessionCommands = ''
    ${pkgs.openssh}/bin/ssh-add ${config.mainUserHome}/.ssh/id_rsa
    '';
  };

  # ${pkgs.xorg.xhost}/bin/xhost +SI:localuser:${cfg.user.name}
  # ${pkgs.xorg.xhost}/bin/xhost -LOCAL:
  services.xserver.windowManager.default = "i3";
  services.xserver.desktopManager.xterm.enable = false;

  # Enable the X11 windowing system.
  services.xserver.displayManager.lightdm = {
    enable = true;
    autoLogin.enable = true;
    autoLogin.user = config.mainUser;
    autoLogin.timeout = 2;
    greeter.enable = true;
  };

  fonts = {
    fonts = with pkgs; [
      font-awesome_5
    ];
  };

  # Allow users in video group to change brightness
  hardware.brightnessctl.enable = true;

  environment.systemPackages = with pkgs; [
    rofi     # Dmenu replacement
    acpilight # Replacement for xbacklight
    arandr # Xrandr gui
    feh
    wirelesstools # To get wireless statistics
    acpi
    xorg.xhost
    xorg.xauth
  ];

}
