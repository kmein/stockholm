{ lib, fetchFromGitHub, buildGoModule }:

buildGoModule rec {
  pname = "alertmanager-bot";
  version = "2020-07-13";

  src = fetchFromGitHub {
    owner = "metalmatze";
    repo = "alertmanager-bot";
    rev = "5efc0bbbf8023d4324e9da98562f064a714a7206";
    sha256 = "09cciml1j8x76jpm2v5v6h2q6j1fkhsz1kswslmx8wl4wk40xgp4";
  };

  modSha256 = "0nlnxkpcna7g7qslyz5i1619paw4jkb1ma4fgpsgvgx1spwrjm8h";
  postInstall = ''
    install -D ./default.tmpl $out/templates/default.tmpl
  '';

  meta = with lib; {
    description = "Simple command-line snippet manager, written in Go";
    homepage = https://github.com/knqyf263/pet;
    license = licenses.mit;
    maintainers = with maintainers; [ kalbasit ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
