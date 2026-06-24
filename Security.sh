#!/bin/bash

sudo apt update && sudo apt full-upgrade -y
mkdir -p ~/src
mkdir -p ~/.local/share/applications
mkdir -p ~/Desktop

# Energia: Sempre Ligado (Tampa fechada e inatividade)
sudo sed -i 's/.*HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
sudo sed -i 's/.*HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' /etc/systemd/logind.conf
sudo sed -i 's/.*HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/systemd/logind.conf
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

#==============================================Acesso remoto==============================================
sudo apt install xrdp ssl-cert openssh-server -y 
sudo adduser xrdp ssl-cert
sudo systemctl enable xrdp ssh
#echo "exec mate-session" > ~/.xsession
#echo "exec startxfce4" > ~/.xsession
#echo "exec startplasma-x11" > ~/.xsession
#echo "exec gnome-session" > ~/.xsession
#echo "exec cinnamon-session" > ~/.xsession

#==============================================Python e Git==============================================
# --- 1. Python Base, Git e Go ---
# Essencial para rodar o sistema e gerenciar repositórios
sudo apt install git python3 python3-pip python3-venv python3-full golang-go python3-setuptools -y

# --- 2. Bibliotecas de Desenvolvimento e Compilação ---
# Necessário para compilar o John (Jumbo) e as bibliotecas C do SpiderFoot (lxml)
sudo apt install build-essential python3-dev libxml2-dev libxslt1-dev zlib1g-dev \
libssl-dev pkg-config libgmp-dev libbz2-dev libpcap-dev -y

# --- 3. Dependências de Sistema para Ferramentas (SET e Recon) ---
# Garante que o SEToolkit e outras ferramentas Python tenham acesso a módulos do sistema
sudo apt install python3-pexpect python3-cryptography python3-requests \
python3-openssl python3-pyte -y
 
#==============================================Recon==============================================
sudo apt install curl nmap wafw00f whatweb whois dnsutils hping3 nbtscan sslscan -y

#==============================================Amass via Snap==============================================
sudo apt install snapd -y 
sudo systemctl enable --now snapd.apparmor 
sleep 2 # Aguarda o serviço iniciar 
sudo snap install core && sudo snap install amass

#==============================================WPSCAN==============================================
sudo apt install ruby-full build-essential zlib1g-dev -y && sudo gem install wpscan

#==============================================LBD==============================================
cd ~/src && git clone https://github.com/HenriqueMei/AutoLinux.git
cd ~/src/AutoLinux/prog/lbd
chmod +x lbd
sudo cp lbd /usr/bin/lbd

#==============================================Nikto==============================================
cd ~/src
chmod +x ~/src/AutoLinux/prog/nikto/program/nikto.pl
if ! grep -q "alias nikto=" ~/.bashrc; then
	echo "alias nikto='~/src/nikto/program/nikto.pl'" >> ~/.bashrc 
fi 

#==============================================Jonh Jumbo==============================================
cd ~/src
sudo apt install git build-essential libssl-dev zlib1g-dev pkg-config libgmp-dev libbz2-dev -y
git clone https://github.com/openwall/john -b bleeding-jumbo john
cd john/src
./configure && make -s clean && make -sj$(nproc)

cd ~/src/john/run
echo “Testando John”
./john --test=0
./john --list=build-info

#Se quiser interface grafica
#cd ~/src
#sudo apt install g++ qtbase5-dev qtchooser -y
if [ ! -d "john" ]; then
	git clone https://github.com/openwall/john -b bleeding-jumbo john 
fi
#cd johnny
#export QT_SELECT=5
#qmake && make -j$(nproc)
#./johnny

# --- Criando apelido (alias) para o John --- 
# Verifica se o alias já existe para não duplicar no .bashrc 
if ! grep -q "alias john=" ~/.bashrc; then 
	echo "alias john='~/src/john/run/john'" >> ~/.bashrc 
fi 

#==============================================Tools Extras==============================================
sudo apt install hydra gobuster sqlmap proxychains4 tor -y

#Opcao 1
#go install github.com/charmbracelet/glow/v2@latest

#Opcao 2
#cd ~/src && git clone https://github.com/charmbracelet/glow.git
#cd glow && go build

#==============================================The Harvester==============================================
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

#==============================================Setoolkit==============================================
cd ~/src
if [ ! -d "setoolkit" ]; then 
	git clone https://github.com/trustedsec/social-engineer-toolkit/ setoolkit 
fi

cd setoolkit
sudo python3 setup.py install

# Alias para facilitar (precisa de sudo para rodar o SET) 
if ! grep -q "alias setoolkit=" ~/.bashrc; then 
	echo "alias setoolkit='sudo setoolkit'" >> ~/.bashrc 
fi

#==============================================Wordlists (SecLists e RockYou)============================================== 
echo "Baixando Wordlists (isso pode demorar)..."
sudo mkdir -p /usr/share/
sudo mv ~/src/AutoLinux/wordlist /usr/share/
cd /usr/share/wordlist
tar xvzf rockyou.tar.gz && tar xvzf metasploit.tar.gz
rm rockyou.tar.gz && rm metasploit.tar.gz

# SecLists (Depth 1 para ser mais rápido)
if [ ! -d "SecLists" ]; then 
	sudo git clone --depth 1 https://github.com/danielmiessler/SecLists.git 
fi

#==============================================Owasp ZAP==============================================
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
cat <<EOF > ~/.local/share/applications/zaproxy.desktop
[Desktop Entry]
Name=OWASP ZAP
Comment=Web Application Security Testing
Exec=$HOME/src/ZAP_2.17.0/zap.sh
Icon=$HOME/src/ZAP_2.17.0/zap.ico
Terminal=false
Type=Application
Categories=Development;Security;
EOF

chmod +x ~/.local/share/applications/zaproxy.desktop
cp ~/.local/share/applications/zaproxy.desktop ~/Desktop/

###================================================================================================###
echo "Configuração Finalizada!"
sleep 5
sudo reboot
