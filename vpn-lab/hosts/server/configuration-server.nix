{ config, pkgs, ... }:

{
  ###########################################################
  # 1. IMPORTAÇÕES E NÍVEL DE SISTEMA
  ###########################################################
  imports = [
    ../../modules/hardware-configuration.nix
    #../../modules/strongswan.nix   # ← módulo da VPN (agora correto)
  ];

  system.stateVersion = "25.05";

  nixpkgs.config.allowUnfree = true;

  ###########################################################
  # 2. CONFIGURAÇÃO DE REDE E ROTEAMENTO
  ###########################################################
  networking.hostName = "vpn-server";

  networking.networkmanager.enable = true;
  networking.interfaces.enp0s3.useDHCP = true;

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.conf.all.accept_source_route" = 0;
  };

  ###########################################################
  # 3. FIREWALL (Regras básicas; NAT é tratado no módulo)
  ###########################################################
  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ 500 4500 ];
    checkReversePath = false;
  };

  ###########################################################
  # 4. SERVIÇOS ESSENCIAIS
  ###########################################################
  services.openssh.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  ###########################################################
  # 5. LOCALIZAÇÃO E PACOTES
  ###########################################################
  time.timeZone = "America/Araguaina";
  i18n.defaultLocale = "pt_BR.UTF-8";

  environment.systemPackages = with pkgs; [
    vim wget direnv git iproute2 tcpdump nettools
  ];
}
