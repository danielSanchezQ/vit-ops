{
  description = "Bitte for VIT";

  inputs = {
    bitte.url = "github:input-output-hk/bitte/terraform-state-in-vault";
    # bitte.url = "path:/home/jlotoski/work/iohk/bitte-wt/bitte";
    # bitte.url = "path:/home/manveru/github/input-output-hk/bitte";
    ops-lib.url = "github:input-output-hk/ops-lib/zfs-image?dir=zfs";
    nixpkgs.follows = "bitte/nixpkgs";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    terranix.follows = "bitte/terranix";
    utils.follows = "bitte/utils";
    jormungandr-nix = {
      url = "github:input-output-hk/jormungandr-nix";
      flake = false;
    };
    jormungandr.url = "github:input-output-hk/jormungandr";
    vit-servicing-station.url =
      "github:input-output-hk/vit-servicing-station/use-rust-nix";
    cardano-node.url =
      "github:input-output-hk/cardano-node?rev=14229feb119cc3431515dde909a07bbf214f5e26";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, utils, bitte, ... }@inputs:
    let
      vitOpsOverlay = import ./overlay.nix { inherit inputs self; };
      bitteOverlay = bitte.overlay.x86_64-linux;

      hashiStack = bitte.mkHashiStack {
        flake = self;
        rootDir = ./.;
        inherit pkgs;
        domain = "vit.iohk.io";
      };

      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [
          (final: prev: { inherit (hashiStack) clusters dockerImages; })
          bitteOverlay
          vitOpsOverlay
        ];
      };

      nixosConfigurations = hashiStack.nixosConfigurations // {
        nspawn-test = import ./nspawn/test.nix { inherit nixpkgs; };
      };
    in {
      inherit self nixosConfigurations;
      inherit (hashiStack) nomadJobs dockerImages consulTemplates;
      inherit (pkgs) sources;
      clusters.x86_64-linux = hashiStack.clusters;
      legacyPackages.x86_64-linux = pkgs;
      devShell.x86_64-linux = pkgs.devShell;
      hydraJobs.x86_64-linux = {
        inherit (pkgs)
          devShellPath bitte nixFlakes sops terraform-with-plugins cfssl consul
          nomad vault-bin cue grafana haproxy grafana-loki victoriametrics
          jormungandr-entrypoint jormungandr-monitor-entrypoint restic-backup
          nomad-driver-nspawn devbox-entrypoint cardano-cli jormungandr-monitor
          jormungandr vit-servicing-station-server vit-servicing-station-cli;
      } // (pkgs.lib.mapAttrs (_: v: v.config.system.build.toplevel)
        nixosConfigurations);
    };
}
