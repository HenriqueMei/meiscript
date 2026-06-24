sudo apt\#!/bin/bash

set -e

# Sistem e tools verificar
echo "========== Configurando WiFi automático =========="
nmcli dev wifi connect "Mei_5G" password "Mei3847Mei"

echo "========== Atualizando o sistema =========="
sudo apt update && sudo apt full-upgrade -y

echo "========== Corrigindo o problema de horário dual boot =========="
timedatectl set-local-rtc 1 --adjust-system-clock

echo "========== Adicionando layouts de teclado (ABNT + US) =========="
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'br'), ('xkb', 'us')]"

echo "========== Ativando tema escuro no Gnome =========="
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

echo "========== Icone Pequeno Desktop =========="
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'small'

echo "========== Dock no centro, oculta, cortada e com ícones tamanho 34 =========="
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 34

echo "========== Instalando pacotes básicos =========="
sudo apt install build-essential curl wget software-properties-common apt-transport-https ca-certificates gnupg lsb-release dkms git  -y
sudo apt install lm-sensors psensor openvpn -y

echo "========== Configurando sensores de temperatura =========="
sudo sensors-detect --auto
echo "Para monitorar, use o comando: psensor &"
echo "Para o monitoramento na barra, abra o Extension Manager e instale a extensão 'Vitals' (CPU, RAM, Temperatura, etc)"



echo "========== Instalando Burp Suite Community =========="
wget -O ~/burp.sh "https://portswigger.net/burp/releases/download?product=community&version=latest&type=linux" \
  || { echo "Erro ao baixar o Burp"; exit 1; }
chmod +x ~/burp.sh
sudo ~/burp.sh --quiet --user-install
ln -s ~/.BurpSuiteCommunity/burpsuite_community /usr/local/bin/burpsuite || true
rm ~/burp.sh

echo "========== Instalando SEToolkit =========="
sudo apt install setoolkit -y

echo "========== Instalando Ferramentas de Pentest Web/API =========="
sudo apt install nmap sqlmap john nikto dirb gobuster ffuf wafw00f hydra -y
sudo apt install wapiti -y
sudo snap install amass
sudo snap install zaproxy --classic

echo "========== Clonando SecLists manualmente =========="
git clone https://github.com/danielmiessler/SecLists.git ~/SecLists

echo "========== Limpando pacotes órfãos =========="
sudo apt autoremove -y
sudo apt autoclean -y

# ProxMox ajuste de tamanho

###lvremove: Apaga a partição de dados vazia do Proxmox
###lvextend: Estende a partição principal para usar 100% do espaço livre
###resize2fs: Avisa o Linux que o tamanho do disco mudou "ao vivo"
lvremove /dev/pve/data
lvextend -l +100%FREE /dev/pve/root
resize2fs /dev/mapper/pve-root

# ProxMox Nome VM Substitua ID pelo número da VM 
qm set ID --name NOVO-NOME

# Comentar tudo que tem nos caminhos:
nano /etc/apt/sources.list.d/pve-enterprise.sources
nano /etc/apt/sources.list.d/ceph.sources

# Criar arquivo: nano /etc/apt/sources.list.d/pve-no-subscription.sources
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription

# proxmox acaba aqui

#### echo "\[1/6] Atualizando pacotes..."

sudo apt update \&\& sudo apt upgrade -y

#### echo "\[2/6] Instalando e ativando SSH..."

sudo apt install -y openssh-server

sudo systemctl enable ssh

sudo systemctl start ssh

#arrumar minimizar do gnome
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

#### echo "\[3/6] Instalando xrdp para acesso remoto..."

sudo apt install -y xrdp

sudo systemctl enable xrdp

sudo systemctl start xrdp



# echo "\[4/6] Instalando Unifi Controller..."

sudo apt update && sudo apt install -y openjdk-17-jre-headless curl wget gnupg
##Adiciona a chave de segurança
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
##Adiciona o repositório 'Jammy' para garantir que o pacote seja encontrado
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
##Atualiza e instala o banco
sudo apt update
sudo apt install -y mongodb-org
##Adiciona a chave de segurança da Ubiquiti
curl -fsSL https://dl.ui.com/unifi/unifi-repo.gpg | sudo gpg --dearmor -o /usr/share/keyrings/unifi.gpg
##Adiciona o repositório correto (Stable)
echo "deb [signed-by=/usr/share/keyrings/unifi.gpg] https://dl.ui.com/unifi/debian stable ubiquiti" | sudo tee /etc/apt/sources.list.d/unifi.list

sudo apt update
sudo apt install -y unifi

sudo systemctl enable mongod
sudo systemctl start mongod
sudo systemctl enable unifi
sudo systemctl status unifi
sudo reboot

#Outra forma
## Atualiza a lista e instala dependências de rede e Java 17
echo "deb http://deb.debian.org/debian bookworm main" | sudo tee /etc/apt/sources.list.d/bookworm.list
sudo apt update && sudo apt install -y curl wget gnupg2 ca-certificates apt-transport-https openjdk-17-jre-headless
sudo rm /etc/apt/sources.list.d/bookworm.list && sudo apt update
##Baixa e adiciona a chave oficial do MongoDB 7.0 ao sistema
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
##Adiciona o repositório específico do MongoDB 7.0 para Debian Bookworm
echo "deb [signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
## Adiciona a chave de segurança da Ubiquiti (UniFi)
curl -fsSL https://dl.ui.com/unifi/unifi-repo.gpg | sudo gpg --dearmor -o /usr/share/keyrings/unifi.gpg
##Adiciona o repositório estável do UniFi
echo "deb [signed-by=/usr/share/keyrings/unifi.gpg] https://dl.ui.com/unifi/debian stable ubiquiti" | sudo tee /etc/apt/sources.list.d/unifi.list
##Instala os programas e ativa os serviços para iniciarem com a VM
sudo apt update && sudo apt install -y mongodb-org unifi
sudo systemctl enable --now mongod unifi
#Acaba aqui outra op

###sudo apt update && sudo apt install ca-certificates wget -y
###wget https://get.glennr.nl/unifi/install/unifi-8.0.28.sh
###sudo bash unifi-8.0.28.sh

#Unifi acaba aqui



# echo "\[5/6] Montando HDs adicionais..."

sudo lsblk
sudo blkid
lsblk -f

sudo mkdir -p /mnt/HD1 /mnt/HD2

sudo nano /etc/fstab
echo "Insira o UUID do HD1: "; read uid1
# Adiciona a linha de montagem permanente no arquivo fstab
echo "UUID=$uid1 /mnt/HD1 ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
# Monta todos os discos listados no fstab imediatamente
sudo mount -a 

# HDs adicionais
# Montagem do HD1
UUID=1a561e8f-9e39-4155-a1b5-af5d159c90a9 /mnt/HD1 ext4 defaults,nofail 0 2

# Montagem do HD2
UUID=f410e9ad-96f1-4699-83e3-184ccde7beb7 /mnt/HD2 ext4 defaults,nofail 0 2
sudo mount -a

#Montagem de HD acaba aqui

#transmission
# 1. Instalação
        sudo apt update && sudo apt install -y transmission-daemon

        # 2. PARAR o serviço (Obrigatório para o settings.json não resetar)
        sudo systemctl stop transmission-daemon

        # 3. Configuração do JSON
        # Lembre de conferir: 
        # "rpc-authentication-required": true
        # "rpc-whitelist-enabled": false
        # "rpc-password": "sua_senha_aqui"
       # “umask”:2
        sudo nano /etc/transmission-daemon/settings.json

        # 4. Ajuste de Permissões e Grupos
        # Define o dono como o usuário do serviço
        sudo chown -R debian-transmission:debian-transmission /mnt/HD1 /mnt/HD2

        # Adiciona seu usuário ao grupo do serviço para o SFTP funcionar
        sudo usermod -aG debian-transmission mei

        # Aplica a trava de segurança (Dono tudo, Grupo lê/executa, Resto nada)
        sudo chmod -R 770 /mnt/HD1 /mnt/HD2

        # 5. Reinicia o serviço
        sudo systemctl start transmission-daemon
#Transmission acaba aqui        

 # Instala o banco de dados MariaDB
                sudo apt install -y mariadb-server
                # Altera o arquivo de configuração para permitir acesso de outros IPs além do local
                sudo sed -i 's/127.0.0.1/0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
                sudo systemctl restart mariadb 
# BD acaba aqui

sudo systemctl daemon-reload

df -h | grep /mnt


# UFW
sudo apt install ufw -y

# 1. Bloqueia tudo por padrão (Entrada) e permite tudo (Saída)
sudo ufw default deny incoming && sudo ufw default allow outgoing

# 2. Libera o SSH (ESSENCIAL para não perder o acesso!)
sudo ufw allow ssh

# 3. Libera Portas principais
# Unifi
sudo ufw allow 8443/tcp 
# Torrent
sudo ufw allow 8080/tcp
sudo ufw allow 9091/tcp
sudo ufw allow 51413/tcp && sudo ufw allow 51413/udp

# 4. Libera o MariaDB APENAS para sua rede local (mais seguro)
sudo ufw allow from 192.168.3.0/24 to any port 3306

# 5. Ativa o Firewall
sudo ufw enable

echo "✅ Tudo pronto: SSH, RDP, Unifi, Tixati instalado e HDs montados!"

apt update && apt install sudo -y
usermod -aG sudo mei
