https://help.ui.com/hc/en-us/articles/34210126298775-Self-Hosting-UniFi#h_01K2Q77CWHFK6SRG8RR07SNBKQ

https://help.ui.com/hc/en-us/articles/220066768-Updating-and-Installing-Self-Hosted-UniFi-Network-Servers-Linux



sudo apt-get update && sudo apt-get install podman slirp4netns
wget "https://fw-download.ubnt.com/data/unifi-os-server/8b93-linux-x64-4.2.23-158fa00b-6b2c-4cd8-94ea-e92bc4a81369.23-x64"
curl -O "https://fw-download.ubnt.com/data/unifi-os-server/8b93-linux-x64-4.2.23-158fa00b-6b2c-4cd8-94ea-e92bc4a81369.23-x64"

chmod +x
sudo ./

Stop UniFi OS Server: sudo systemctl stop uosserver
Start UniFi OS Server: sudo systemctl start uosserver
Disable Automatic Starting at System Boot: sudo systemctl disable uosserver
Enable Automatic Starting at System Boot: sudo systemctl enable uosserver


#update

sudo apt-get update && sudo apt-get install ca-certificates apt-transport-https
echo 'deb [ arch=amd64,arm64 ] https://www.ui.com/downloads/unifi/debian stable ubiquiti' | camiseta sudo /etc/apt/sources.list.d/100-ubnt-unifi.list
sudo wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg
eco "deb [confiado=sim] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/3.6 multiverso" | camiseta sudo /etc/apt/sources.list.d/mongodb-org-3.6.list
atualização do sudo apt-get
sudo apt-get update && sudo apt-get install unifi -y


