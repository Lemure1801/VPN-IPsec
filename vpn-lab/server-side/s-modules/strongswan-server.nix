{ config, pkgs, ... }: {
   # Habilita o strongswan
  services.strongswan = {
    enable = true;
  };

  # Instala pacotes necessários
  environment.systemPackages = [ pkgs.strongswan pkgs.vim pkgs.iproute2 ];

  # Cria /etc/strongswan.conf vazio para evitar erro de inicialização
  environment.etc."strongswan.conf".text = "";

  # Cria /etc/swanctl/ e subdiretórios implicitamente via arquivos
  environment.etc = {
    "swanctl/swanctl.conf".source = ./s-swanctl/swanctl.conf;
    "swanctl/swanctl.conf".mode = "0644"; # Permissões padrão

    "swanctl/swanctl.secrets".source = ./s-swanctl/swanctl.secrets;
    "swanctl/swanctl.secrets".mode = "0600"; # Mais restrito para secrets

    # Cria /etc/swanctl/x509/ e instala certs
    "swanctl/x509/server-cert.pem".source = ../s-secrets/x509/server-cert.pem;
    "swanctl/x509/server-cert.pem".mode = "0644";

    "swanctl/x509/client-cert.pem".source = ../s-secrets/x509/client-cert.pem;  # Para verificar remoto
    "swanctl/x509/client-cert.pem".mode = "0644";

    # Cria /etc/swanctl/private/ e instala chave privada
    "swanctl/private/server-key.pem".source = ../s-secrets/private/server-key.pem;
    "swanctl/private/server-key.pem".mode = "0600";

    # Cria /etc/swanctl/x509ca/ e instala CA
    "swanctl/x509ca/ca-cert.pem".source = ../s-secrets/x509ca/ca-cert.pem;
    "swanctl/x509ca/ca-cert.pem".mode = "0644";
  };
}