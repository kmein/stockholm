{ lib, ... }:

with lib;
with types;

types // rec {

  host = submodule {
    options = {
      name = mkOption {
        type = label;
      };
      dc = mkOption {
        type = label;
      };
      cores = mkOption {
        type = positive;
      };
      nets = mkOption {
        type = attrsOf net;
        apply = x: assert hasAttr "retiolum" x; x;
      };
    };
  };

  net = submodule ({ config, ... }: {
    options = {
      via = mkOption {
        type = nullOr net;
        default = null;
      };
      addrs = mkOption {
        type = listOf addr;
        apply = _: config.addrs4 ++ config.addrs6;
      };
      addrs4 = mkOption {
        type = listOf addr4;
        default = [];
      };
      addrs6 = mkOption {
        type = listOf addr6;
        default = [];
      };
      aliases = mkOption {
        # TODO nonEmptyListOf hostname
        type = listOf hostname;
      };
      tinc = mkOption {
        type = let net-config = config; in submodule ({ config, ... }: {
          options = {
            config = mkOption {
              type = str;
              apply = _: ''
                ${optionalString (net-config.via != null)
                  (concatMapStringsSep "\n" (a: "Address = ${a}") net-config.via.addrs)}
                ${concatMapStringsSep "\n" (a: "Subnet = ${a}") net-config.addrs}
                ${config.pubkey}
              '';
            };
            pubkey = mkOption {
              type = str;
            };
          };
        });
      };
    };
  });

  positive = mkOptionType {
    name = "positive integer";
    check = x: isInt x && x > 0;
    merge = mergeOneOption;
  };

  # TODO
  addr = str;
  addr4 = str;
  addr6 = str;
  hostname = str;
  label = str;
}
