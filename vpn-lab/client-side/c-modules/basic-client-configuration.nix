#################################
#          ATENÇÃO!!!           #
#################################
# Cole abaixo de "CONFIGURAÇÕES DE USUÁRIO" tudo entre
# 'users.users.exemplo = {'
#   ...
# }
# e...
# nixpkgs.config.allowUnfree = ...;
#################################

{ config, pkgs, ...}:
{
  ############################
  # CONFIGURAÇÕES DE USUÁRIO #
  ############################



  #############################
  #   CONFIGURAÇÕES BÁSICAS   #
  #############################

  # Importações básicas do sistema
  imports =
    [
      ./hardware-configuration.nix
    ];

  # Configuração do boot para inicialização da máquina e alcocação de partição
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # Define o nome do host
  networking.hostName = "vpn-client";

  # Configuração de IP's fixos
  networking.interfaces.enp0s8.ipv4.addresses = [ { address = "192.168.56.116"; prefixLength = 24; } ];
  networking.interfaces.lo.ipv4.addresses = [ { address = "10.1.0.1"; prefixLength = 24; } ];

  # Configuração de roteamento da máquina
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.conf.all.accept_source_route" = 0;
  };

  # Configuração de DNS, rede e habilitação do SSH
  networking.networkmanager.enable = false;
  services.openssh.enable = true;
  services.resolved.enable = true;
  systemd.services.resolvconf.enable = false;
  networking.nameservers = ["1.1.1.1" "10.0.2.2" "8.8.8.8" "8.8.4.4"];
  nix.settings = {
    http2 = false;
  };

  # Download de pacotes necessários e importantes
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    direnv
    vscode
    vscode-fhs
    pkgs.strongswan
    openssl
    tree
  ];

  # Habilitação de binários externos 
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glibc
    zlib
    stdenv.cc.cc.lib
    zlib.out
    openssl
    curl
  ];

  # Definição do path para o servidor de código do VS Code
  environment.sessionVariables = {
    VSCODE_SERVER_INSTALL_DIR = "/home/lemure/vscode-server";
  };

  # COnfigurações de idioma e afins de região
  time.timeZone = "America/Araguaina";

  i18n.defaultLocale = "pt_BR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  services.xserver.xkb = {
    layout = "br";
    variant = "";
  };

  console.keyMap = "br-abnt2";

  # Habilita suporte para SSH
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Configuração de firewall
  networking.firewall.allowedTCPPorts = [ 500 4500 ];
  networking.firewall.allowedUDPPorts = [ 500 4500 ];
  networking.firewall.extraCommands = ''
    iptables -A INPUT -p esp -j ACCEPT
    iptables -A OUTPUT -p ah -j ACCEPT
    iptables -A FORWARD -s 10.0.0.0/24 -d 10.1.0.0/24 -j ACCEPT 
    iptables -A FORWARD -s 10.1.0.0/24 -d 10.0.0.0/24 -j ACCEPT
    iptables -t nat -A POSTROUTING -s 10.1.0.0/24 -o lo -j MASQUERADE
  '';
    networking.firewall.extraStopCommands = ''
    iptables -D FORWARD -s 10.1.0.0/24 -d 10.0.0.0/24 -j ACCEPT
    iptables -D FORWARD -s 10.0.0.0/24 -d 10.1.0.0/24 -j ACCEPT
    iptables -t nat -D POSTROUTING -s 10.1.0.0/24 -o lo -j MASQUERADE
  '';

  # Definição da versão do sistema
  system.stateVersion = "25.05";
}
