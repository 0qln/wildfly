{
  description = "WildFly Application Server (FHS wrapper)";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/9da7f1cf7f8a6e2a7cb3001b048546c92a8258b4";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {pkgs, ...}: let
        wildfly = pkgs.stdenvNoCC.mkDerivation {
          name = "wildfly-39.0.0.Final";
          src = pkgs.fetchzip {
            url = "https://github.com/wildfly/wildfly/releases/download/39.0.0.Final/wildfly-39.0.0.Final.zip";
            hash = "sha256-nfdb4doRRn4AwMQZkNYwIDBKIq4iY6diFX/WlPFQqZI=";
          };
          installPhase = ''
            mkdir -p $out
            cp -r $src/* $out/
          '';
        };

        wildfly-fhs = pkgs.buildFHSEnv {
          name = "wildfly-fhs";
          targetPkgs = pkgs: with pkgs; [openjdk21 bash coreutils];
          runScript = "${wildfly}/bin/standalone.sh";
          profile = ''
            export WILDFLY_BASE_DIR="$HOME/.wildfly-fhs-base"
            mkdir -p "$WILDFLY_BASE_DIR"/{log,data,deployments,tmp,configuration}
            if [ ! -f "$WILDFLY_BASE_DIR/configuration/standalone.xml" ]; then
              cp -r ${wildfly}/standalone/configuration/* "$WILDFLY_BASE_DIR/configuration/"
              chmod -R u+w "$WILDFLY_BASE_DIR/configuration/"
            fi
            export JBOSS_HOME=${wildfly}
            export JBOSS_BASE_DIR="$WILDFLY_BASE_DIR"
          '';
        };
      in {
        packages = {
          inherit wildfly wildfly-fhs;
        };
      };
    };
}
