{
  description = "Projeto Acadêmico: VPN IPsec - Flake de construção e aplicação";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }: {

    # 1. Configurações NixOS (devem ficar na raiz!)
    nixosConfigurations = {
      vpn-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./vpn-lab/hosts/server/configuration-server.nix
          ./vpn-lab/modules/configuration.nix

          ({ ... }: {
              _module.args.secrets = {
                ca = builtins.path { path = ./vpn-lab/_secrets/x509ca/ca-cert.pem; };
                cert = builtins.path { path = ./vpn-lab/_secrets/x509/server-cert.pem; };
                key = builtins.path { path = ./vpn-lab/_secrets/private/server-key.pem; };
              };
          })
          ./vpn-lab/modules/strongswan.nix
        ];
      };

      vpn-client = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./vpn-lab/hosts/client/configuration-client.nix ];
      };
    };

    # 2. DevShells por sistema (aqui sim usamos eachDefaultSystem)
    devShells = flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        default = pkgs.mkShell {
          buildInputs = [ pkgs.git pkgs.vim ];
        };
      }
    );
  };
}