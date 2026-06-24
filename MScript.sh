#!/bin/bash

vm_torrent()
{
    clear
    logo
    echo "====================================="
    echo "        Preparo de VM Torrent        "
    echo "====================================="
    echo "[+] Preparando VM Torrent (Transmission)..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install transmission-daemon -y
    sudo systemctl stop transmission-daemon

    echo [+] Configurando fstab e montando HDs
    sudo mkdir -p /mnt/HD1
    sudo mkdir -p /mnt/HD2

# Verifica se as linhas já existem no fstab para não duplicar se rodar o script 2 vezes
    if ! grep -q "1a561e8f-9e39-4155-a1b5-af5d159c90a9" /etc/fstab; then
        echo "UUID=1a561e8f-9e39-4155-a1b5-af5d159c90a9 /mnt/HD1 ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
    fi
    if ! grep -q "d15cb8a0-f0f8-4505-b2bd-5b69c58b6318" /etc/fstab; then
        echo "UUID=d15cb8a0-f0f8-4505-b2bd-5b69c58b6318 /mnt/HD2 ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
    fi

    sudo mount -a
    sudo chown -R debian-transmission:debian-transmission /mnt/HD1 /mnt/HD2
    sudo chmod -R 775 /mnt/HD1 /mnt/HD2

    echo "[+] Configurando credenciais e diretórios do Transmission..."
    
    # Variáveis de credenciais (Altere aqui os valores reais)
    RPC_USER="seu_usuario_aqui"
    RPC_PASS="sua_senha_aqui"
    DIR_PADRAO="/mnt/HD" # Diretório padrão, mas você altera na WebUI a cada download
    
    JSON_FILE="/etc/transmission-daemon/settings.json"

    # Usa o 'sed' para substituir os valores no arquivo JSON
    sudo sed -i "s|\"download-dir\": \".*\"|\"download-dir\": \"$DIR_PADRAO\"|" $JSON_FILE
    sudo sed -i "s/\"rpc-authentication-required\": false/\"rpc-authentication-required\": true/" $JSON_FILE
    sudo sed -i "s/\"rpc-enabled\": false/\"rpc-enabled\": true/" $JSON_FILE
    sudo sed -i "s/\"rpc-host-whitelist-enabled\": true/\"rpc-host-whitelist-enabled\": false/" $JSON_FILE
    sudo sed -i "s/\"rpc-whitelist-enabled\": true/\"rpc-whitelist-enabled\": false/" $JSON_FILE
    sudo sed -i "s/\"rpc-username\": \".*\"/\"rpc-username\": \"$RPC_USER\"/" $JSON_FILE
    sudo sed -i "s/\"rpc-password\": \".*\"/\"rpc-password\": \"$RPC_PASS\"/" $JSON_FILE

    sudo systemctl start transmission-daemon
    sudo systemctl enable transmission-daemon

    #==============================#
    #   Comandos de Diagnostico    #
    #   Espaco no HD               #
    #   df -h                      #
    #   Montagem                   #
    #   mount | grep /mnt          #
    #   UUID HD                    #
    #   sudo blkid                 #
    #   df -h | grep /mnt          #
    #   ps aux | grep transmission #
    #   Recarregar Montagem HD     #
    #   sudo mount -a              #
    #==============================#

    #Firewall
    # Painel Web do Torrent (9091)
    sudo ufw allow in on tailscale0 to any port 9091 proto tcp

    # Tráfego do Torrent (Liberado para a internet para o download funcionar rápido)
    sudo ufw allow 51413/tcp
    sudo ufw allow 51413/udp
    echo "[!] Concluído."
    sleep2
    linux_vm
}

vm_unifi()
{
    clear
    logo
    echo "====================================="
    echo "          Preparo de VM Unifi        "
    echo "====================================="
    echo "[+] Preparando VM Unifi..."
    sudo apt-get update && sudo apt-get install curl podman slirp4netns -y
    wget "https://fw-download.ubnt.com/data/unifi-os-server/8b93-linux-x64-4.2.23-158fa00b-6b2c-4cd8-94ea-e92bc4a81369.23-x64"
    curl -o unifi "https://fw-download.ubnt.com/data/unifi-os-server/8b93-linux-x64-4.2.23-158fa00b-6b2c-4cd8-94ea-e92bc4a81369.23-x64"
    chmod +x unifi
    sudo ./unifi

    #firewall
    # Comunicação das Antenas/Switches (Adoção, STUN e Discovery)
    sudo ufw allow from 192.168.3.0/24 to any port 8080 proto tcp
    sudo ufw allow from 192.168.3.0/24 to any port 3478 proto udp
    sudo ufw allow from 192.168.3.0/24 to any port 10001 proto udp

    # Acesso ao Painel Web (HTTPS 8443)
    sudo ufw allow in on tailscale0 to any port 8443 proto tcp
    echo "[!] Concluído."
    sleep2
    linux_vm
}

vm_ia()
{
    clear
    logo
    echo "====================================="
    echo "           Preparo de VM IA          "
    echo "====================================="
    echo "[+] Preparando VM IA (Ollama + Open WebUI)..."
    # Ollhama
    sudo apt update && sudo apt install podman -y
    sudo loginctl enable-linger $USER
    curl -fsSL https://ollama.com/install.sh | sh

    sudo mkdir -p /etc/systemd/system/ollama.service.d
    cat << 'EOF' | sudo tee /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF

sudo systemctl daemon-reload
sudo systemctl restart ollama
sleep2
ollama pull qwen2.5:7b
ollama pull deepseek-coder

# Open Web
    mkdir -p ~/.config/containers/systemd
    cat << 'EOF' > ~/.config/containers/systemd/open-webui.container
[Unit]
Description=Open WebUI

[Container]
Image=ghcr.io/open-webui/open-webui:main
ContainerName=open-webui
PublishPort=3000:8080
Volume=open-webui:/app/backend/data
AddHost=host.docker.internal:host-gateway

[Service]
Restart=always
TimeoutStartSec=300

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    podman pull ghcr.io/open-webui/open-webui:main
    systemctl --user start open-webui.service

#Firewall
# Interface Web do Open WebUI (3000) - Consumir a IA remotamente
    sudo ufw allow in on tailscale0 to any port 3000 proto tcp
    echo "[!] Concluído."
    sleep2
    linux_vm
}

linux_vm()
{
    clear
    logo
        while true; do

        echo "====================================="
        echo "         Menu Virtual Machine        "
        echo "====================================="
        echo "Escolha uma opção:"
        echo "1 - Unifi"
        echo "2 - Torrent"
        echo "3 - IA"
        echo "9 - Retornando para o Menu Principal"
        echo "0 - Sair"
        echo "====================================="
        read -p "Opção: " opcao

    case $opcao in
        1)
            echo "Preparando para configurar ambiente"
            sleep2
            vm_unifi            
        ;;
        2)
            echo "Preparando para configurar ambiente"
            sleep2
            vm_torrent            
            ;;
        3)
            echo "Preparando para configurar ambiente"
            sleep2
            vm_ia
            ;;
        9)
            echo "Retornando para o Menu Principal"
            sleep2
            menu_principal
            ;;
        0)
            echo "Saindo..."
            sleep2
            clear
            exit 0
        ;;
        *)
            echo "Opção inválida!"
            sleep2
            ;;
    esac
    done
}

linux_custom()
{
    clear
    logo
    sudo apt install pipx -y

    # 2. Instala o Terminal Text Effects de forma isolada e segura
    pipx install terminaltexteffects

    # 3. Garante que os atalhos do pipx funcionem no seu usuário
    pipx ensurepath
}

user_pentest()
{
    clear
    logo
        echo "====================================="
        echo "       Instalador de Programas       "
        echo "====================================="
        echo ""
        echo "Com grandes poderes vêm grandes responsabilidades"
        sleep2
        echo "Criar Pastas para ferramentas de seguranca"
        mkdir -p ~/src
        mkdir -p ~/.local/share/applications
        mkdir -p ~/Desktop

        #Ferramentas de seguranca compiladores e dev
        sudo apt install python3 python3-pip python3-venv python3-full python3-setuptools -y
        sudo apt install build-essential golang-go python3-dev libxml2-dev libxslt1-dev zlib1g-dev -y
        sudo apt install python3-pexpect python3-cryptography python3-requests python3-openssl python3-pyte -y
        sudo apt install libssl-dev pkg-config libgmp-dev libbz2-dev libpcap-dev libjson-perl libxml-writer-perl -y
        #==============================================Tools Pentest==============================================
        sudo apt install nmap wafw00f whatweb whois dnsutils hping3 nbtscan hydra gobuster sqlmap sslscan -y
        sudo snap install core && sudo snap install amass
        sudo apt install ruby-full build-essential zlib1g-dev -y && sudo gem install wpscan
        #==== LBD===
        cd ~/src
        if [ ! -d "meiscript" ]; then
            git clone https://github.com/HenriqueMei/meiscript.git
        else
            echo "[!] Repositório meiscript já existe. Atualizando..."
            cd meiscript && git pull && cd ..
        fi
        cd ~/src/meiscript/prog/lbd
        chmod +x lbd
        sudo cp lbd /usr/bin/lbd
        #===Nikto===
        cd ~/src && cp -r ~/src/meiscript/prog/nikto ~/src
        chmod +x ~/src/nikto/program/nikto.pl
        if ! grep -q "alias nikto=" ~/.bashrc; then
            echo "alias nikto='~/src/nikto/program/nikto.pl'" >> ~/.bashrc 
        fi 
        #===TesteSSL===
        cd ~/src && cp ~/src/meiscript/prog/testssl.sh ~/src/
        chmod +x ~/src/tesetssl.sh
        if ! grep -q "alias testssl=" ~/.bashrc; then 
            echo "alias testssl='sudo ~/src/testssl.sh'" >> ~/.bashrc 
        fi
        #===Jonh Jumbo===
        cd ~/src
        git clone https://github.com/openwall/john -b bleeding-jumbo john
        cd john/src
        ./configure && make -s clean && make -sj$(nproc)

        cd ~/src/john/run
        echo “Testando John”
        ./john --test=0
        ./john --list=build-info

        if ! grep -q "alias john=" ~/.bashrc; then 
            echo "alias john='~/src/john/run/john'" >> ~/.bashrc 
        fi

        #Interface grafica
        #cd ~/src
        #sudo apt install g++ qtbase5-dev qtchooser -y
        #if [ ! -d "john" ]; then
        #    git clone https://github.com/openwall/john -b bleeding-jumbo john 
        #fi
        #cd johnny
        #export QT_SELECT=5
        #qmake && make -j$(nproc)
        # Cria o atalho no terminal para abrir a interface
        #if ! grep -q "alias johnny=" ~/.bashrc; then 
        #    echo "alias johnny='~/src/johnny/johnny'" >> ~/.bashrc 
        #fi
    #=======The Harvester====
        cd ~/src
        # 1. Instalar o gerenciador 'uv' (necessário para o theHarvester novo) 
        curl -LsSf https://astral.sh/uv/install.sh | sh 
        export PATH="$HOME/.local/bin:$PATH"

        # 2. Instalar theHarvester 
        if [ ! -d "theHarvester" ]; then 
            git clone https://github.com/laramies/theHarvester.git 
        fi 
        cd theHarvester 
        uv sync 
        cd ..

        # --- Criando Aliases para facilitar o uso --- 
        if ! grep -q "alias theharvester=" ~/.bashrc; then 
            echo "alias theharvester='cd ~/src/theHarvester && uv run theHarvester.py'" >> ~/.bashrc 
        fi 

    #=======SetoolKit e MetaSploit======
        cd ~/src
        if [ ! -d "setoolkit" ]; then 
            git clone https://github.com/trustedsec/social-engineer-toolkit/ setoolkit 
        fi

        cd setoolkit
        sed -i 's/pycrypto/pycryptodome/g' requirements.txt
        sudo PIP_BREAK_SYSTEM_PACKAGES=1 python3 setup.py install
        #sudo python3 setup.py install

        curl -sL https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
        chmod 755 msfinstall
        sudo ./msfinstall
        sudo sed -i 's|^METASPLOIT_PATH=.*|METASPLOIT_PATH=/opt/metasploit-framework/bin|g' /etc/setoolkit/set.config
        rm msfinstall

        # Alias para facilitar (precisa de sudo para rodar o SET) 
        if ! grep -q "alias setoolkit=" ~/.bashrc; then 
            echo "alias setoolkit='sudo setoolkit'" >> ~/.bashrc 
        fi

    #=======WordLists======
        echo "Baixando Wordlists (isso pode demorar)..."
        sudo mkdir -p /usr/share/
        sudo mv ~/src/meiscript/wordlist /usr/share/
        cd /usr/share/wordlist
        tar xvzf rockyou.tar.gz && tar xvzf metasploit.tar.gz
        rm rockyou.tar.gz && rm metasploit.tar.gz

        # SecLists (Depth 1 para ser mais rápido)
        if [ ! -d "/usr/share/wordlist/SecLists" ]; then 
            sudo git clone --depth 1 https://github.com/danielmiessler/SecLists.git 
        fi
    #=======OWASP ZAP======
        sudo apt install default-jdk -y
        cd ~/src
        wget https://github.com/zaproxy/zaproxy/releases/download/v2.17.0/ZAP_2.17.0_Linux.tar.gz
        tar xvzf ZAP_2.17.0_Linux.tar.gz && rm ZAP_2.17.0_Linux.tar.gz
        cd ZAP_2.17.0

        # Define o caminho absoluto
        ZAP_PATH="$HOME/src/ZAP_2.17.0"
        cd "$ZAP_PATH"
        chmod +x zap.sh

        # Cria um link simbólico em /usr/local/bin
        sudo ln -sf "$ZAP_PATH/zap.sh" /usr/local/bin/zap

        # Criar atalho no Desktop
        echo "[Desktop Entry]
        Name=OWASP ZAP
        Comment=Web Application Security Testing
        Exec=$HOME/src/ZAP_2.17.0/zap.sh
        Icon=$HOME/src/ZAP_2.17.0/zap.ico
        Terminal=false
        Type=Application
        Categories=Development;Security;" > ~/.local/share/applications/zaproxy.desktop

        chmod +x ~/.local/share/applications/zaproxy.desktop
        cp ~/.local/share/applications/zaproxy.desktop ~/Desktop/
    #=======Burp=======
        wget -O ~/burp.sh "https://portswigger.net/burp/releases/download?product=community&version=2026.2.4&type=Linux"
        chmod +x ~/burp.sh
        ~/burp.sh -q
        sudo ln -sf ~/BurpSuiteCommunity/BurpSuiteCommunity /usr/local/bin/burpsuite
        rm ~/burp.sh
    clear
    echo "[!] Concluído"
    sleep2
    linux
}

linux_maker()
{
    clear
    logo
    echo "====================================="
    echo "      Preparar Ambiente Linux        "
    echo "====================================="
    echo "[+] Atualizando o Sistema"
    sleep2
    sudo apt update && sudo apt full-upgrade -y
    echo "[+] Instalando pacotes basicos"
    sleep2
    sudo apt install git snapd dkms gnupg -y
    sudo apt install apt-transport-https ca-certificates lsb-release -y
    sudo systemctl enable --now snapd.apparmor
    echo "[!] Concluído"
    sleep2
    linux
}

app_install()
{
    clear
    logo
    echo "====================================="
    echo "       Instalador de Programas       "
    echo "====================================="
    echo "Escolha os programas:"
    echo "1 - Steam"
    echo "2 - Discord"
    echo "3 - Spotify"
    echo "4 - Telegram"
    echo "5 - OBS"
    echo "6 - Google Chrome"
    echo "7 - Proton VPN"
    echo "8 - Burp"
    echo "9 - Glow"
    echo "---------------------------"
    echo "Digite os números separados por espaço"
    echo "Exemplo: 1 2 3"
    read -p "Lista de Programas: " listProg

    clear
    for item in $listProg; do
        case $item in
        1)
            logo
            echo "[+] Instalando Steam"
            curl -L -o steam.deb "https://repo.steampowered.com/steam/archive/precise/steam_latest.deb"
            sudo apt install ./steam.deb -y
            rm steam.deb
        ;;
        2)
            echo "[+] Instalando Discord"
            curl -L -o discord.deb "https://discordapp.com/api/download?platform=linux&format=deb"
            sudo apt install ./discord.deb -y
            rm discord.deb
        ;;
        3)
            echo "[+] Instalando Spotify"
            curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
            echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
            sudo apt-get update && sudo apt-get install spotify-client -y
        ;;
        4)
            echo "[+] Instalando Telegram"
            sudo snap install telegram-desktop
        ;;
        5)
            echo "[+] Instalando OBS"
            sudo snap install obs-studio --classic
        ;;
        6)
            echo "[+] Instalando Google"
            wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
            sudo apt install ./google-chrome-stable_current_amd64.deb -y
            rm google-chrome-stable_current_amd64.deb
        ;;
        7)
            echo "[+] Instalando Proton VPN"
            wget https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.8_all.deb
            sudo dpkg -i ./protonvpn-stable-release_1.0.8_all.deb && sudo apt update
            sudo apt install proton-vpn-gnome-desktop -y
            rm protonvpn-stable-release_1.0.8_all.deb
        ;;
        8)
            echo "[+] Instalando Glow"
            sudo apt install golang-go -y
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
            echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
            sudo apt update && sudo apt install glow
        ;;
        9)
            echo "[+] Instalando Burp Suite Community"
            wget -O ~/burp.sh "https://portswigger.net/burp/releases/download?product=community&version=2026.2.4&type=Linux"
            chmod +x ~/burp.sh
            ~/burp.sh -q
            sudo ln -sf ~/BurpSuiteCommunity/BurpSuiteCommunity /usr/local/bin/burpsuite
            rm ~/burp.sh
        ;;
        0)
            linux
            ;;
        *)
            echo "[-] Opção '$item' não existe."
        esac
    done
    linux
}

linux()
{
    clear
    logo
    while true; do
    echo "====================================="
    echo "         Configurações Gerais        "
    echo "====================================="
    echo "Escolha uma opção:"
    echo "1 - Ambiente Linux"
    echo "2 - Configuracao de Notebook"
    echo "3 - Instalar Programas"
    echo "4 - Ambiente Pentest"
    echo "5 - DualBoot"
    echo "9 - Menu Principal"
    echo "0 - Sair"
    echo "---------------------------"
    echo "Se for uma maquina recem formatada, execute a opção 1 - Ambiente Linux..."

    read -p "Opção: " opcao

    case $opcao in
        1)
            echo "Preparando para configurar ambiente"
            sleep2
            linux_maker
        ;;
        2)
            clear
            logo
            echo "Configurando Notebook + Acesso Remoto KDE"
            sleep2
            # Energia: Sempre Ligado (Tampa fechada e inatividade)
            sudo sed -i 's/.*HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
            sudo sed -i 's/.*HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' /etc/systemd/logind.conf
            sudo sed -i 's/.*HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/systemd/logind.conf
            sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
            # Acesso remoto
            sudo apt install xrdp ssl-cert -y
            sudo systemctl enable xrdp
            echo "exec startplasma-x11" > ~/.xsession
            echo "[!] Concluído."
            sleep2
            linux
            ;;
        3)
            echo "Carregando lista de programas..."
            echo "Aguarde um momento"
            sleep2
            app_install
            ;;
        4)
            echo "Montando arsenal Hacker"
            sleep2
            user_pentest
            ;;
        5)
            clear
            logo
            echo "Preparando Linux para DualBoot"
            sudo timedatectl set-local-rtc 1
            echo "[!] Conclído."
            sleep2
            linux
            ;;
        9)
            echo "Retornando para o Menu Principal"
            sleep2
            menu_principal
            ;;
        0)
            echo "Saindo..."
            sleep2
            clear
            exit 0
        ;;
        *)
            echo "Opção inválida!"
            sleep2
            ;;
    esac
    done
}

setup_inicial()
{
    clear
    logo
        echo "[!] Se o script já foi executado, ele vai pular essas etapas."
        echo "[!] Aguarde por favor, dependendo da sua internet pode demorar um pouco."

        if ! command -v ufw &> /dev/null || ! command -v curl &> /dev/null || ! command -v wget &> /dev/null || ! command -v ssh &> /dev/null; then       
        sudo apt update && sudo apt install ufw curl wget openssh-server -y
        sudo systemctl enable ssh
        else
            echo "[!] Dependências básicas já estão instaladas."
        fi
        if ! command -v tailscale &> /dev/null; then
            echo "[+] Instalando Tailscale..."
            curl -fsSL https://tailscale.com/install.sh | sh
        else
            echo "[!] Tailscale já está instalado."
        fi
        # 1. Bloqueia tudo que entra, permite tudo que sai (atualizações, downloads)
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        # 2. Permite SSH (Porta 22) APENAS Tailscale
        sudo ufw allow in on tailscale0 to any port 22 proto tcp
        sudo ufw --force enable
        sleep2
}

menu_principal()
{
    clear
    logo
    while true; do

        clear
        logo
        echo "====================================="
        echo "            Menu Principal           "
        echo "====================================="
        echo "Escolha uma opção:"
        echo "1 - Computador/Notebook"
        echo "2 - VM"
        echo "3 - Linux Custom"
        echo "0 - Sair"
        echo "====================================="

        read -p "Opção: " opcao

        case $opcao in
            1)
                echo "Preparando Opcões..."
                sleep2
                linux
                ;;
            2)
                echo "Preparando Opcões..."
                sleep2
                linux_vm
                ;;
            3)
                echo "Preparando Opções..."
                sleep2
                linux_custom
                ;;
            0)
                echo "Saindo..."
                sleep2
                clear
                exit 0
                ;;
            *)
                echo "Opção inválida!"
                sleep2
                ;;
        esac
        clear
    done
}

logo()
{
    CYAN='\e[36m'
    GREEN='\e[32m'
    NC='\e[0m'

    echo -e "${CYAN}"
    echo "    __  __ __  ___   ______   ____ "
    echo "   / / / //  |/  /  / ____/  /  _/ "
    echo "  / /_/ // /|_/ /  / __/     / /   "
    echo " / __  // /  / /  / /___   _/ /    "
    echo "/_/ /_//_/  /_/  /_____/  /___/    "
    echo -e "${GREEN}                              by HMEI${NC}"
    echo ""
}

setup_inicial
menu_principal