{
  description = "Tally. A distributed event driven task execution system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    flake-utils,
    nixpkgs,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    outputs = flake-utils.lib.eachSystem systems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            kubernetes-helm-wrapped = prev.wrapHelm prev.kubernetes-helm {
              plugins = with prev.kubernetes-helmPlugins; [
                helm-diff
                helm-git
                helm-s3
                helm-secrets
              ];
            };
          })
        ];
      };
    in {
      # packages exported by the flake
      packages = {};

      # nix fmt
      formatter = pkgs.alejandra;

      # nix develop -c $SHELL
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          argc
          go
          k3d
          k9s
          kafkactl
          kcat
          kubectl
          kubernetes-helm-wrapped
          skaffold
        ];

        shellHook = ''
          export IN_NIX_DEVSHELL=1;
          export KUBECONFIG="$(realpath .)/.local/kubeconfig";
        '';
      };
    });
  in
    outputs;
}
