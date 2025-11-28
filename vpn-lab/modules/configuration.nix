# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  fileSystems."/"={
    fsType = "ext4";
  };

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "vpn-server"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  services.openssh.enable = true;
  networking.networkmanager.enable = true;
  services.resolved.enable = true;
  systemd.services.resolvconf.enable = false;
  networking.nameservers = ["1.1.1.1" "10.0.2.2" "8.8.8.8" "8.8.4.4"];
  nix.settings = {
    http2 = false;
  };

  #pacotes para integração SSH com o VS CODE
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glibc
    zlib
    stdenv.cc.cc.lib
    zlib.out
    openssl
    curl
  ];

  environment.sessionVariables = {
    VSCODE_SERVER_INSTALL_DIR = "/home/lemure/vscode-server";
  };

  # Set your time zone.
  time.timeZone = "America/Araguaina";

  # Select internationalisation properties.
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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "br";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "br-abnt2";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.lemure = {
    isNormalUser = true;
    description = "lemure";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGzOWFW75VgA3wRfiNdVQtrAP2V15KUlkAGMtaZQXfXK lemure@NoteLemure"
    ];
  };

  # Enable automatic login for the user.
  services.getty.autologinUser = "lemure";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
 
  networking.useDHCP = false;

  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    direnv
    vscode
    vscode-fhs
    pkgs.strongswan
    openssl
    tree
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
   programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 500 4500 ];
  networking.firewall.allowedUDPPorts = [ 500 4500 ];
  networking.firewall.extraCommands = ''
    # iptables -A INPUT -p esp -j ACCEPT
    # iptables -A OUTPUT -p esp -j ACCEPT
  '';
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  networking.interfaces.enp0s3.useDHCP = true;
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).

  networking.nat = {
    enable = true;
    externalInterface = "enp0s3";
    internalInterfaces = ["ipsec0"];
  };

  system.stateVersion = "25.05"; # Did you read the comment?

}
