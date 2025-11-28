{ config, pkgs, lib, ... }:

{
  ############################################################
  # 1. HABILITAÇÃO DO STRONGSWAN
  ############################################################
  services.strongswan.enable = true;

  ############################################################
  # 2. REMOVIDO: systemd.tmpfiles.rules (NÃO É NECESSÁRIO)
  ############################################################
  # systemd.tmpfiles.rules = [
  #   "d /etc/swanctl 0750 root root -"
  #   "d /etc/swanctl/private 0750 root root -"
  #   "d /etc/swanctl/x509 0750 root root -"
  #   "d /etc/swanctl/x509ca 0750 root root -"
  # ];

  ############################################################
  # 3. swanctl.conf — REMOVIDO O BLOCO 'secrets'
  ############################################################
  environment.etc."swanctl/swanctl.conf".text = ''
connections {
  vpn {
    local_addrs  = 10.10.10.1
    remote_addrs = 10.10.20.1

    local {
      auth = pubkey
      certs = server-cert.pem
      id = vpn-server
    }

    remote {
      auth = pubkey
      id = vpn-client
    }

    children {
      vpn {
        local_ts  = 10.10.10.0/24
        remote_ts = 10.10.20.0/24

        esp_proposals = aes128-sha256-modp2048
        rekey_time = 20m
      }
    }

    version = 2
    mobike = no
    proposals = aes128-sha256-modp2048
  }
}
  '';

  ############################################################
  # 4. swanctl.secrets — CORRIGIDO
  ############################################################
  environment.etc."swanctl/swanctl.secrets".text = ''
secrets {
  private {
    server-key.pem = ""
  }
}
  '';

  ############################################################
  # 5. REFERÊNCIA AOS CERTIFICADOS
  ############################################################
  environment.etc."swanctl/private/server-key.pem".source =
    ../_secrets/private/server-key.pem;

  environment.etc."swanctl/x509/server-cert.pem".source =
    ../_secrets/x509/server-cert.pem;

  environment.etc."swanctl/x509ca/ca-cert.pem".source =
    ../_secrets/x509ca/ca-cert.pem;

  ############################################################
  # 6. FIREWALL — NAT
  ############################################################
  networking.firewall.extraCommands = ''
    iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o enp0s3 \
      -m policy --dir out --pol ipsec -j ACCEPT
    iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o enp0s3 -j MASQUERADE
  '';

  networking.firewall.extraStopCommands = ''
    iptables -t nat -D POSTROUTING -s 10.10.10.0/24 -o enp0s3 \
      -m policy --dir out --pol ipsec -j ACCEPT
    iptables -t nat -D POSTROUTING -s 10.10.10.0/24 -o enp0s3 -j MASQUERADE
  '';

  ############################################################
  # 7. strongswan.conf — necessário para swanctl
  ############################################################
  environment.etc."strongswan.conf".text = ''
charon {
  load_modular = yes
  plugins {
    include strongswan.d/*.conf
  }
}
  '';

  ############################################################
  # 8. strongswan.d — IMPORTA OS PLUGINS DO PACOTE
  ############################################################
  environment.etc."strongswan.d".source =
    "${pkgs.strongswan}/etc/strongswan.d";

  systemd.tmpfiles.rules = [
    "d /etc/swanctl 0750 root root -"
    "d /etc/swanctl/private 0750 root root -"
    "d /etc/swanctl/x509 0750 root root -"
    "d /etc/swanctl/x509ca 0750 root root -"

    # ADICIONAR:
    "d /etc/strongswan.d 0755 root root -"
  ];


}
