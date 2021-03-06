{ pass, write, writeDash, ... }:

write "secrets" {
  "/bin/secrets".link = writeDash "secrets" ''
    PASSWORD_STORE_DIR=$HOME/.secrets-pass/ \
    exec ${pass}/bin/pass $@
  '';
  "/bin/secretsmenu".link = writeDash "secretsmenu" ''
    PASSWORD_STORE_DIR=$HOME/.secrets-pass/ \
    exec ${pass}/bin/passmenu $@
  '';
}
