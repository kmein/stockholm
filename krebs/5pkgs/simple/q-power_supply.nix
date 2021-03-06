{ gawk, gnused, writeDashBin }:

writeDashBin "q-power_supply" ''
  power_supply() {(
    set -efu
    uevent=$1
    eval "$(${gnused}/bin/sed -n '
      s/^\([A-Z_]\+=[0-9A-Za-z_-]*\)$/export \1/p
    ' $uevent)"
    case $POWER_SUPPLY_NAME in
      AC)
        exit # not battery
        ;;
    esac
    exec </dev/null
    exec ${gawk}/bin/awk '
      function die(s) {
        printf "%s: %s\n", name, s
        exit 1
      }

      function print_hm(h, m) {
        m = (h - int(h)) * 60
        return sprintf("%dh%dm", h, m)
      }

      function print_bar(n, r, t1, t2, t_col) {
        t1 = int(r * n)
        t2 = n - t1
        if (r >= .42)     t_col = "1;32"
        else if (r >= 23) t_col = "1;33"
        else if (r >= 11) t_col = "1;31"
        else              t_col = "5;1;31"
        return sgr(t_col) strdup("■", t1) sgr(";30") strdup("■", t2) sgr()
      }

      function sgr(p) {
        return "\x1b[" p "m"
      }

      function strdup(s,n,t) {
        t = sprintf("%"n"s","")
        gsub(/ /,s,t)
        return t
      }

      END {
        name = ENVIRON["POWER_SUPPLY_NAME"]

        charge_unit = "Ah"
        charge_now = ENVIRON["POWER_SUPPLY_CHARGE_NOW"] / 10^6
        charge_full = ENVIRON["POWER_SUPPLY_CHARGE_FULL"] / 10^6

        current_unit = "A"
        current_now = ENVIRON["POWER_SUPPLY_CURRENT_NOW"] / 10^6

        energy_unit = "Wh"
        energy_now = ENVIRON["POWER_SUPPLY_ENERGY_NOW"] / 10^6
        energy_full = ENVIRON["POWER_SUPPLY_ENERGY_FULL"] / 10^6

        power_unit = "W"
        power_now = ENVIRON["POWER_SUPPLY_POWER_NOW"] / 10^6

        voltage_unit = "V"
        voltage_now = ENVIRON["POWER_SUPPLY_VOLTAGE_NOW"] / 10^6
        voltage_min_design = ENVIRON["POWER_SUPPLY_VOLTAGE_MIN_DESIGN"] / 10^6

        #printf "charge_now: %s\n", charge_now
        #printf "charge_full: %s\n", charge_full
        #printf "current_now: %s\n", current_now
        #printf "energy_now: %s\n", energy_now
        #printf "energy_full: %s\n", energy_full
        #printf "energy_full: %s\n", ENVIRON["POWER_SUPPLY_ENERGY_FULL"]
        #printf "energy_full: %s\n", ENVIRON["POWER_SUPPLY_ENERGY_FULL"] / 10^6
        #printf "power_now: %s\n", power_now
        #printf "voltage_now: %s\n", voltage_now

        if (current_now == 0 && voltage_now != 0) {
          current_now = power_now / voltage_now
        }
        if (power_now == 0) {
          power_now = current_now * voltage_now
        }
        if (charge_now == 0 && voltage_min_design != 0) {
          charge_now = energy_now / voltage_min_design
        }
        if (energy_now == 0) {
          energy_now = charge_now * voltage_min_design
        }
        if (charge_full == 0 && voltage_min_design != 0) {
          charge_full = energy_full / voltage_min_design
        }
        if (energy_full == 0) {
          energy_full = charge_full * voltage_min_design
        }

        if (charge_now == 0 || charge_full == 0) {
          die("unknown charge")
        }

        charge_ratio = charge_now / charge_full

        out = out name
        out = out sprintf(" %s", print_bar(10, charge_ratio))
        out = out sprintf(" %d%", charge_ratio * 100)
        out = out sprintf(" %.2f%s", charge_now, charge_unit)
        if (current_now != 0) {
          out = out sprintf("/%.1f%s", current_now, current_unit)
        }
        out = out sprintf(" %d%s", energy_full, energy_unit)
        if (power_now != 0) {
          out = out sprintf("/%.1f%s", power_now, power_unit)
        }
        if (current_now != 0) {
          out = out sprintf(" %s", print_hm(charge_now / current_now))
        }

        print out
      }
    '
  )}

  for uevent in /sys/class/power_supply/*/uevent; do
    power_supply "$uevent" || :
  done
''
