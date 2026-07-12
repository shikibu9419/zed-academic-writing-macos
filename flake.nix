{
  description = "zaw — Zed academic writing toolkit for macOS (Docker LaTeX + Skim)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
        f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        zaw = pkgs.stdenvNoCC.mkDerivation {
          pname = "zed-academic-writing-macos";
          version = "0.1.0";
          src = self;
          dontBuild = true;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          # jq is the only non-macOS-native runtime dependency; put it on
          # PATH via a wrapper (plutil/awk/sed/bash come from the system).
          installPhase = ''
            mkdir -p $out
            cp -r bin libexec template config $out/
            wrapProgram $out/bin/zaw --prefix PATH : ${pkgs.jq}/bin
          '';
          meta = {
            description = "Zed academic writing toolkit for macOS";
            homepage = "https://github.com/shikibu9419/zed-academic-writing-macos";
            platforms = systems;
          };
        };
        default = zaw;
      });
    };
}
