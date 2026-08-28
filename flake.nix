{
  description = "jetui by moonbit";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Pin/Bump to a known-working rev deliberately. HEAD sometimes depends on packages marked broken.
    moonbit-overlay = {
      url = "github:moonbit-community/moonbit-overlay/50118f5c3c0298b5cb17cc6f1c346165801014c8";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agent-skills-nix = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    moonbit-skills = {
      url = "github:moonbitlang/skills";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      moonbit-overlay,
      agent-skills-nix,
      moonbit-skills,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        agentLib = agent-skills-nix.lib.agent-skills;
        selectedSkills = [
          "lang/moonbit-agent-guide"
        ];
        sources = {
          lang = {
            path = moonbit-skills;
            subdir = "skills";
          };
        };
        selection = agentLib.selectSkills {
          inherit sources;
          catalog = agentLib.discoverCatalog sources;
          allowlist = map builtins.baseNameOf selectedSkills;
        };
        skillsHook = agentLib.mkShellHook {
          inherit pkgs;
          bundle = agentLib.mkBundle { inherit pkgs selection; };
          targets.agents = agentLib.defaultLocalTargets.agents // { enable = true; };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            moonbit-overlay.packages.${system}.moon-patched_latest
          ];
          shellHook = ''
            # Install selected skills into .agents/skills (project-local).
            ${skillsHook}
            # First enter: fetch mooncake registry when the module exists.
            if [ -f moon.mod.json ] && [ ! -d .mooncakes ]; then
              moon update 2>/dev/null || true
            fi
          '';
        };
      }
    );
}
