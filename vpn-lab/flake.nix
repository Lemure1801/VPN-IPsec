{
  description = "Projeto Acadêmico: VPN IPsec Site-to-Site";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";  # Define a versão utilizada do NixOS
  };

  outputs = { self, nixpkgs }: { 
    nixosConfigurations = {
      vpn-server = nixpkgs.lib.nixosSystem { # Configurações para rebuild como servidor
        system = "x86_64-linux";
        modules = [ # Arquivos importados para configuração da máquina 
          ./server-side/s-modules/hardware-configuration.nix
          ./server-side/s-modules/basic-server-configuration.nix
          ./server-side/s-modules/strongswan-server.nix
        ];
      };
      vpn-client = nixpkgs.lib.nixosSystem { # Configurações para rebuild como cliente
        system = "x86_64-linux";
        modules = [ # Arquivos importados para configuração da máquina
          ./client-side/c-modules/hardware-configuration.nix
          ./client-side/c-modules/basic-client-configuration.nix
          ./client-side/c-modules/strongswan-client.nix
        ];
      };
    };
  };
}