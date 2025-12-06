{ config, pkgs, ... }: {
  services.strongswan = {
    enable = true;
  };

  # Instala pacotes necessários (movido para cá para evitar alterações desnecessárias no basic)
  environment.systemPackages = [ pkgs.strongswan pkgs.vim pkgs.iproute2 ];

  # Cria /etc/strongswan.conf vazio para evitar erro de inicialização
  environment.etc."strongswan.conf".text = "";

  # Cria /etc/swanctl/ e subdiretórios implicitamente via arquivos
  environment.etc = {
    "swanctl/swanctl.conf".source = ./c-swanctl/swanctl.conf;
    "swanctl/swanctl.conf".mode = "0644";  # Permissões padrão

    "swanctl/swanctl.secrets".source = ./c-swanctl/swanctl.secrets;
    "swanctl/swanctl.secrets".mode = "0600";  # Mais restrito para secrets

    # Cria /etc/swanctl/x509/ e instala certs
    "swanctl/x509/client-cert.pem".source = ../c-secrets/x509/client-cert.pem;
    "swanctl/x509/client-cert.pem".mode = "0644";

    "swanctl/x509/server-cert.pem".source = ../c-secrets/x509/server-cert.pem;  # Para verificar remoto
    "swanctl/x509/server-cert.pem".mode = "0644";

    # Cria /etc/swanctl/private/ e instala chave privada
    "swanctl/private/client-key.pem".source = ../c-secrets/private/client-key.pem;
    "swanctl/private/client-key.pem".mode = "0600";

    # Cria /etc/swanctl/x509ca/ e instala CA
    "swanctl/x509ca/ca-cert.pem".source = ../c-secrets/x509ca/ca-cert.pem;
    "swanctl/x509ca/ca-cert.pem".mode = "0644";
  };
}