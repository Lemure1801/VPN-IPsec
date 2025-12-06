{
  description = "Projeto Acadêmico: VPN IPsec Site-to-Site";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";  # Ou nixos-unstable
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      vpn-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";  # Ajuste para sua arch
        modules = [
          ./server-side/s-modules/hardware-configuration.nix
          ./server-side/s-modules/basic-server-configuration.nix
          ./server-side/s-modules/strongswan-server.nix
        ];
      };
      vpn-client = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./client-side/c-modules/hardware-configuration.nix
          ./client-side/c-modules/basic-client-configuration.nix
          ./client-side/c-modules/strongswan-client.nix
        ];
      };
    };
  };
}