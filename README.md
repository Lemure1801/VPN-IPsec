![alt text](image.png)

## Propósito
Esta VPN foi criada com o propósito de funcionar de forma **prática e reprodutível** em quaisquer máquinas com NixOS. Combina facilidade de uso com confiabilidade em conexões site-to-site, para qual a rede virtual privada foi construída.

## Tópicos
* [Pilar e Ferramentas Utilizadas](#pilar-e-ferramentas-utilizadas)
* [Estrutura de Diretórios](#estrutura-de-diretórios)
* [Implementar e Configurar a VPN](#implementar-e-configurar-a-vpn)
* [Conexão e Tunelagem](#conexão-e-tunelagem)
* [Resumo Técnico](#resumo-técnico-do-funcionamento)
* [Contribuidores]()
* [Licença]()

## Pilar e Ferramentas Utilizadas
A Academic VPN conta com a utilização de:
* **[NixOS](https://github.com/NixOS/nixpkgs)** (como sistema operacional e linguagem do projeto, junto dos arquivos de Strongswan)
* **[Strongswan](https://github.com/strongswan/strongswan)** (para configuração da conexão)
* **[OpenSSL](https://github.com/openssl/openssl)** (para geração das chaves, certificados e AC)

## Estrutura de Diretórios
A base do projeto é 90% baseada nos arquivos, necessitando de poucos comandos para funcionar plenamente. Tendo isso em mente, é importante compreender como devem ficar as pastas e seus respectivos arquivos. <br>
```bash
./VPN-IPsec
└── vpn-lab
    ├── client-side
    │   ├── c-modules
    │   │   ├── basic-client-configuration.nix
    │   │   ├── c-swanctl
    │   │   │   ├── swanctl.conf
    │   │   │   └── swanctl.secrets
    │   │   ├── hardware-configuration.nix
    │   │   └── strongswan-client.nix
    │   └── c-secrets
    │       ├── private
    │       │   └── client-key.pem
    │       ├── x509
    │       │   └── client-cert.pem
    │       └── x509ca
    │           └── ca-cert.pem
    ├── flake.lock
    ├── flake.nix
    └── server-side
        ├── s-modules
        │   ├── basic-server-configuration.nix
        │   ├── hardware-configuration.nix
        │   ├── s-swanctl
        │   │   ├── swanctl.conf
        │   │   └── swanctl.secrets
        │   └── strongswan-server.nix
        └── s-secrets
            ├── private
            │   └── server-key.pem
            ├── x509
            │   ├── client-cert.pem
            │   └── server-cert.pem
            └── x509ca
                └── ca-cert.pem
```
Arquivos * **.pem** e pastas * **-secrets** não estão presentes no repositório por precaução de segurança. É preferível que você gerencie estes arquivos sensíveis de acordo com o guia deste README.md, de fato.
* ### ``vpn-lab/``
>Diretório inicial do projeto. Contém `client-side`, `server-side`, `flake.nix` e `flake.lock`.
* ### ``server-side/ e client-side/``
>Diretórios que contém todos os arquivos necessários para o rebuild da máquina como servidor/cliente da VPN. Contam com `*-modules` e `*-secrets`.
* ### ``*-modules/``
>Diretório que guarda os módulos importados pelo `flake.nix`, como `strongswan-*.nix`, `basic-*-configuration.nix` e o subdiretório `*-swanctl/`.
* ### ``*-swanctl/``
>Diretório responsável por guardar os ``arquivos swanctl.conf`` e ``swanctl.secrets``, vitais para estabelecer a conexão entre máquinas.
* ### ``*-secrets/``
>Diretório que contém todos os arquivos `*.pem`, necessários para garantir a segurança das conexões efetivadas e validação de chaves e certificados.

## Implementar e Configurar a VPN
Antes, deixemos claro quais arquivos serão modificados (quaisquer outros **NÃO DEVEM SER ALTERADOS**):

* ### `basic-*-configuration.nix`
>É o pilar que vai impedir que a sua máquina quebre ou dê problemas no geral por conta da VPN. Nela há uma parte reservada do código para você copiar o seu usuário (dentro de /etc/nixos/configuration.nix)dentro dela. Caso sua máquina conte com alterações diversas que não estejam presentes nas *configurações básicas*, adicione-as com cuidado. Evite importar o seu /etc/nixos/configuration.nix dentro do próprio ``basic`` para previnir erros de conflito de declarações.

```Nix
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
```
<br>

* ### `hardware-configuration.nix`
>Este arquivo deve ser a exata cópia do seu `/etc/nixos/hardware-configurtion.nix`. O que está presente neste arquivo é apenas para expressar a necessidade de sua presença no mesmo diretório que `basic-*-configuration.nix`. Ao executar o comando abaixo, certifique-se de estar em ``c-modules`` ou ``s-modules``.
```Bash
# Remover o arquivo antigo pelo atual pela cópia do hardware-configuration.nix da sua máquina
sudo rm ./hardware-configuration.nix
sudo cp /etc/nixos/hardware-configuration.nix ./
``` 
<br>

* ### `*-secrets/` e arquivos `*.pem`

Tendo feito a configuração dos arquivos acima, iremos tratar agora do diretório `*-secrets/`.
```Bash
# Criar o diretório na sua máquina (console ou WSL pra quem usa Windows)
sudo mkdir -p s-secrets/{private,x509,x509ca}
```

No seu console (ou WSL caso use Windows), execute os seguintes comandos dentro do *-secrets/:
>Atenção! Configurando tanto o cliente quanto o servidor, organize **APENAS O ``*-secrets`` DO HOST EM QUESTÃO**, deixando organizado de forma idêntica à parte `*-secrets` em questão da `tree` apresentada inicialmente.
```Bash
# Verificar se está instalado
openssl version

# Caso não tenha
sudo apt update
sudo apt install openssl

# Gerar certificado e chave da Autoridade Certificadora
openssl genpkey -algorithm RSA -out ca-key.pem -pkeyopt rsa_keygen_bits:4096
openssl req -new -x509 -days 3650 -key ca-key.pem -out ca-cert.pem -subj "/CN=VPN-CA" -addext "basicConstraints=critical,CA:TRUE"

# Verificação (deve retornar OK)
openssl x509 -in ca-cert.pem -noout -text | grep -A1 "Basic Constraints"

# Gerar certificado e chave do servidor
openssl genpkey -algorithm RSA -out server-key.pem -pkeyopt rsa_keygen_bits:4096
openssl req -new -key server-key.pem -out server.csr -subj "/CN=server.example.org"
openssl x509 -req -days 3650 -in server.csr -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -addext "basicConstraints=CA:FALSE" -addext "keyUsage=digitalSignature" -addext "extendedKeyUsage=serverAuth"

# Verificação (deve retornar OK)
openssl verify -CAfile ca-cert.pem server-cert.pem

# Gerar certificado e chave do cliente
openssl genpkey -algorithm RSA -out client-key.pem -pkeyopt rsa_keygen_bits:4096
openssl req -new -key client-key.pem -out client.csr -subj "/CN=client@example"
openssl x509 -req -days 3650 -in client.csr -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out client-cert.pem -addext "basicConstraints=CA:FALSE" -addext "keyUsage=digitalSignature" -addext "extendedKeyUsage=clientAuth"

# Verificação (deve retornar OK)
openssl verify -CAfile ca-cert.pem client-cert.pem

# Lembre de mover os arquivos até que estejam idênticos à estrutura da tree.
# Por fim, copie a pasta do seu computador para a máquina que você implementará a VPN (certifique-se de estar na pasta onde o diretório secrets está)

# Para o servidor
sudo scp s-screts <usuário-da-sua-máquina>@<ip-da-sua-máquina>:/path/até/dentro/de/server-side

# Para o cliente
sudo scp c-screts <usuário-da-sua-máquina>@<ip-da-sua-máquina>:/path/até/dentro/de/client-side
```
<br>

* ### ``swanctl.conf``
>Para este arquivo, você irá apenas alterar os IP's nele. Certifique-se de que todos estão nos locais corretos. **NÃO ALTERE NADA NO BLOCO `children`** principalmente, mas evite mudar quaisquer configurações que não as indicadas aqui. O exemplo a seguir é usado com base no ``s-swanctl/swanctl.conf``.

```Nix
connections {
  vpn-tunnel {
    local_addrs = 192.168.0.1# IP do servidor (exemplo)
    remote_addrs = 192.168.0.2 # IP do cliente (exemplo)
    local1 { # Recursos da máquina local para autenticação e trust
      auth = pubkey
      certs = server-cert.pem
    }
    remote1 {# Recursos da máquina remota (cliente) para autenticação e trust (não inclui chave do cliente)
      auth = pubkey
      certs = client-cert.pem
    }
    children { # child (produto das configurações de tunelagem anteriores)
      vpn-tunnel-child {
        local_ts = 10.0.0.0/24  # Sub-rede local do servidor
        remote_ts = 10.1.0.0/24  # Sub-rede remota do cliente
        esp_proposals = aes256-sha256-ecp384 # Proposta de criptografia
        start_action = start
      }
    }
  }
}

authorities {  # Autoridade Certificadora para validação das chaves e afins
  myca {
    cacert = ca-cert.pem
  }
}
```

<br>

>Após todos estes passos, você configurou o seu servidor e/ou cliente. Portanto, iremos ao passo final para levantar a VPN: subir a conexão das máquinas e subir o túnel entre elas.

<br>

## Conexão e Tunelagem
Para executar a tunelagem, certifique-se de que o seu IP está corretamente colocado em swanctl.conf, de acordo com o que já foi falado. <br>
<p>

**Execute os seguintes comandos no servidor:**

<p>

```Bash
# Após aplicar todas as configurações anteriores. Certifique-se de estar em vpn-lab/
sudo nixos-rebuild switch --flake .#vpn-server

# Após o rebuild, crie a rota IP entre as máquinas
sudo ip route add 10.1.0.0/24 via <ip-da-sua-máquina> 

# Após criar a rota, suba a conexão do servidor. Algumas partes da mensagem dirão que tal arquivo falhou em ser adicionado ou afim, mas o que importa são as mensagen de:
# successfully loaded 1 authorities, 0 unloaded
# successfully loaded 1 connections, 0 unloaded
sudo swanctl --load-all
```
<p>

**Feito isso, execute no cliente:**

</p>

```Bash
sudo nixos-rebuild switch --flake .#vpn-client

# Depois do rebuild, crie a rota
sudo ip route add 10.1.0.0/24 via <ip-da-sua-máquina> 

# Ocorrendo tudo corretamente, faça:
sudo swanctl --load-all

# Caso a connection e a authoritie sejam carregadas, execute:
sudo swanctl --initiate --child vpn-tunnel-child

# Possivelmente ocorrerá um erro dizendo que não foi possível iniciar ou estabilizar o túnel/conexão. Se isso acontecer, repita o comando e se der erro dizendo que não foi possível estabelecer o túnel/conexão porque já existe um anterior, significa que deu certo.

# Execute para pingar a outra máquina e dê 'ctrl + C' após alguns segundos
ping -4 10.0.0.1

# Após isso, execute:
sudo swanctl --list-sas

# Deve aparecer algo como:
'vpn-tunnel: #1, ESTABLISHED, IKEv2, bd93636028b6dab7_i* 719406c5c8b2d364_r
  local  'CN=vpn-client' @ 192.168.56.116[4500]
  remote 'CN=vpn-server' @ 192.168.56.114[4500]
  AES_CBC-128/HMAC_SHA2_256_128/PRF_HMAC_SHA2_256/ECP_256
  established 38s ago, rekeying in 13150s
  vpn-tunnel-child: #1, reqid 1, INSTALLED, TUNNEL, ESP:AES_CBC-256/HMAC_SHA2_256_128
    installed 38s ago, rekeying in 3220s, expires in 3922s
    in  c6241fed,    252 bytes,     3 packets,     4s ago
    out c7e099ac,    252 bytes,     3 packets,     4s ago
    local  10.1.0.0/24
    remote 10.0.0.0/24'
```

<br>

Feito isso... Pronto! Você concluiu a configuração da sua VPN IPsec. Fácil fácil, não? Agradecemos toda a sua atenção e disposição para ler até aqui. Bons estudos, bom trabalho e boa sorte nos seus projetos! Só não use este poder para o mal...

## Resumo Técnico do Funcionamento
 A VPN idealizada neste projeto opera estabelecendo um túnel seguro IPsec IKEv2 entre o cliente e o servidor. Esse túnel atua como uma ponte criptografada conectando dois hosts, permitindo que máquinas interajam como se estivessem numa LAN a parte da rede local.

>1. **Identidade e Confiança**<br>
*O cliente e o servidor ostentam certificados gerados com OpenSSL. Esses certificados proclamam: “Eu sou, sem dúvidas, o cara certo”. Ambos depositam confiança na mesma CA, autoridade certificadora, o que lhes permite validar mutuamente de modo automático. Não existe senha: a autenticação é conduzida pela criptografia.*

>2. **Configuração do Túnel (IKEv2)** <br>
Quando o cliente tenta conectar: <br>
*Ele remete seu certificado ao servidor.
O servidor o retorna.
Ambos negociam algoritmos de criptografia e permutam chaves.
Estabelecem uma ligação segura, conhecida como IKE_SA.
Internamente, criam o túnel de dados autêntico: o CHILD_SA.
A partir daí, a comunicação entre eles se torna inteiramente criptografada.*

>3. **Empacotamento dos Pacotes** <br>
Com o túnel ativo: <br>
*Pacotes originários da sub-rede do cliente (10.1.0.0/24) são encapsulados pelo StrongSwan.
São remetidos ao servidor utilizando o protocolo ESP, que representa um método seguro de empacotamento.
O servidor desembrulha esse pacote e o direciona para sua própria rede, 10.0.0.0/24.
A ocorrência contrária tambêm é possível.
Assim, as duas redes parecem interligadas, como se fossem uma coisa só.*

>4. **Roteamento e Firewall** <br>
Para tudo funcionar:<br>
*O NixOS ativa o ip_forward.
As regras do firewall deixam ESP, AH e portas 500/4500 livres.
Rotas estáticas, sabem como alcançar a sub-rede remota de cada lado.
Sem isso, os pacotes ficariam perdidos, mesmo com o túnel funcionando.*

>5. **Uso do NixOS** <br>
Escolher NixOS torna o ambiente de rede determinístico: <br>
*Interfaces e IPs são declarados, não se alteram por si só.
NetworkManager desativado, para evitar conflitos.
Regras de firewall e roteamento se repetem idênticas a cada reconstrução.
Em outras palavras: o túnel funciona do mesmo jeito sempre, sem sustos.*

## Licença de Uso

Este projeto foi desenvolvido com foco em aprendizado, pesquisa e experimentação em ambientes controlados. Seu uso é livre para fins educacionais, incluindo estudos individuais, atividades acadêmicas, demonstrações em laboratório e referências técnicas.<br>

No entanto, o projeto não está autorizado para uso comercial, seja direta ou indiretamente. Isso inclui, mas não se limita a:
- venda do software ou de partes dele;
- uso em produtos ou serviços oferecidos comercialmente;
- integração a soluções corporativas com fins lucrativos. <br>

A ideia é garantir que o conteúdo permaneça acessível para quem deseja aprender sobre NixOS, StrongSwan e redes, preservando também o caráter experimental e não lucrativo do projeto.

Caso haja interesse em utilizar o material em um contexto comercial ou distribuí-lo de forma distinta do permitido, entre em contato para discutir termos específicos de autorização.

O uso do projeto implica a aceitação dessas condições.

## Contribuintes
- **Arquiteto de Infraestrutura & Mantenedor:** <u>[Ian Gutieres (Lêmure)](https://github.com/Lemure1801)</u>
- **Analista de QA (Quality Assurance):** <u>[Ludmilla]()</u>

