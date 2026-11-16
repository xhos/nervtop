{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    git-hooks,
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = f:
      nixpkgs.lib.genAttrs systems
      (system: f system nixpkgs.legacyPackages.${system});
  in {
    checks = forAllSystems (system: pkgs: {
      pre-commit = git-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          alejandra.enable = true;
          golangci-lint = {
            enable = true;
            extraPackages = [pkgs.go];
          };
          gotest = {
            enable = true;
            stages = ["pre-push"];
            extraPackages = [pkgs.go];
          };
        };
      };
    });

    packages = forAllSystems (system: pkgs: {
      default = pkgs.buildGoModule {
        pname = "nervtop";
        meta.mainProgram = "nervtop";
        version = self.shortRev or self.dirtyShortRev or "dev";
        src = ./.;
        vendorHash = "sha256-HDjQ5sp9h2TU8jLDcIjcYUi6KTyF8hZSPAWzAnSBysU=";
        ldflags = ["-s" "-w"];
      };
    });

    devShells = forAllSystems (system: pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [go gopls golangci-lint];
        shellHook = self.checks.${system}.pre-commit.shellHook;
      };
    });

    formatter = forAllSystems (system: pkgs: pkgs.alejandra);
  };
}
