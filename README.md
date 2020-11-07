## Installation de l'OS
### Installation d'Ubuntu server
#### Gravure et insertion de la SD
Graver une version de l'image disque sur SD card (Balena)
* version __ubuntu-20.04-server__
* version __ubuntu-18.04-server__
Ejecter et rebrancher le lecteur/graveur USB  
Modifier le fichier
* __cmdline.txt__ sur __ubuntu-20.04-server__
* __nobtcmd.txt__ sur __ubuntu-18.04-server__
Ajouter en fin de ligne
<pre><code>cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1
</code></pre>

>Voir si d'autres config sont possibles à ce niveau (WIFI...)  

Ejecter la clé  
Insérer la clef dans le nano  
Se connecter en filaire (RJ45)  
Brancher l'alimentation

#### Première connection en SSH
Utiliser Putty (déteminer IP sur port 22)  
login : __ubuntu__  
password : __ubuntu__  
Change le mot de passe et se reconnecter  
Mettre à jour le système
<pre><code>sudo su
apt-get update
reboot # pour ubuntu 20.04
sudo su # pour ubuntu 20.04  
apt-get upgrade
timedatectl set-timezone Europe/Paris
apt-get install zip docker.io docker-compose nfs-kernel-server
# sudo systemctl enable docker
docker swarm init --advertise-addr 192.168.1.100
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
exit
mkdir /home/root
wget https://codeload.github.com/Cocooning-tech/cocooning/zip/master
unzip master
mv cocooning-master /apps
rm master
chmod 600 /apps/trafik/acme.json
</code></pre>

> https://codeload.github.com/Cocooning-tech/cocooning/zip/master à changer en fonction du repositorie
> Sous la version 20.04 il peut être nécessaire de rebooter entre update et upgrade  

#### Activer le Wifi
Configurer Netplan  
<pre><code>sudo bash -c "echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
sudo nano /etc/netplan/10-my-config.yaml
</code></pre>
Ajouter le code  

>Pas de tabulation dans ce fichier mais des "espaces"

<pre><code>network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      accept-ra: no
      addresses: [192.168.1.99/24]
      gateway4: 192.168.1.1
  wifis:
    wlan0:
      dhcp4: no
      dhcp6: no
      accept-ra: no
      addresses: [192.168.1.100/24]
      gateway4: 192.168.1.1
      access-points:
        "Livebox-2466":
          password: "S4TVJCQwaWZzknGibt"
</code></pre>  

> Changer l'adresse IP selon la box et le node

Appliquer la configuration  
<pre><code>sudo netplan generate
sudo netplan apply
</code></pre>

#### Changer le hostname
<pre><code>nano /etc/hostname
</code></pre>
Changer le hostname en fonction du type de noeud
<pre><code>cl-1-master-1
</code></pre>
<pre><code>cl-1-worker-1
</code></pre>  

>Les hostname de chaque noeud du cluster doivent être différents

<pre><code>reboot
</code></pre>

### Installation de Dietpi

#### Gravure et insertion de la SD
Graver une version de l'image disque sur SD card (Balena)
* version 32 bits __DietPi_RPi-ARMv6-Buster__
* version 64 bits __DietPi_RPi-ARMv8-Buster__
Ejecter et rebrancher le lecteur/graveur USB  

Modifier le fichier __cmdline.txt__ 
Ajouter en fin de ligne
<pre><code>cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1
</code></pre>

Modifier le fichier __dietpi.txt__ du répertoire root de la SD
<pre><code>AUTO_SETUP_LOCALE=fr_FR.UTF-8
AUTO_SETUP_KEYBOARD_LAYOUT=fr
AUTO_SETUP_TIMEZONE=Europe/Paris
AUTO_SETUP_NET_WIFI_ENABLED=1
AUTO_SETUP_NET_WIFI_COUNTRY_CODE=FR
AUTO_SETUP_NET_USESTATIC=1
AUTO_SETUP_NET_STATIC_IP=192.168.1.100
AUTO_SETUP_NET_STATIC_MASK=255.255.255.0
AUTO_SETUP_NET_STATIC_GATEWAY=192.168.1.1
AUTO_SETUP_NET_HOSTNAME=cl-1-master-1
</code></pre>

Modifier le fichier __dietpi-wifi.txt__du répertoire root de la SD
<pre><code># - WiFi SSID: required, case sensitive
aWIFI_SSID[0]='Livebox-2466'
# - WiFi key: If no key/open, leave this blank
aWIFI_KEY[0]='S4TVJCQwaWZzknGibt'
</code></pre>

Ejecter la clé  
Insérer la clef dans le nano  
Pas besoin de se connecter en filaire (RJ45)  
Brancher l'alimentation

#### Première connection en SSH
Utiliser Putty (déteminer IP sur port 22)  
login : __root__  
password : __dietpi__  
Change le mot de passe et se reconnecter  
configurer le système
<pre><code>sudo su
apt-get install zip docker-compose python3-pip
docker swarm init --advertise-addr 192.168.1.100
mkdir /home/root
wget https://codeload.github.com/Cocooning-tech/cocooning/zip/master
unzip master
mv cocooning-master /apps
rm master
chmod 600 /apps/traefik/acme.json
cd /apps/ddclient
docker stack deploy --compose-file docker-compose.yml ddclient
cd /apps/traefik
docker network create -d overlay cocooning-network
docker stack deploy --compose-file docker-compose.yml traefik
cd /apps/portainer
docker stack deploy --compose-file docker-compose.yml portainer
</code></pre>

## Installation d'un contrôleur Zigbee
### Module C2531 USB sniffer
Create a new udev rule for cc2531, idVendor and idProduct must be equal to values from lsusb command. The rule below creates device /dev/cc2531:
<pre><code>echo "SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"0451\", ATTRS{idProduct}==\"16a8\", SYMLINK+=\"cc2531\",  RUN+=\"/usr/local/bin/docker-setup-cc2531.sh\"" | sudo tee /etc/udev/rules.d/99-cc2531.rules
</code></pre>
Reload newly created rule using the following command:
<pre><code>sudo udevadm control --reload-rules
</code></pre>
Create docker-setup-cc2531.sh
<pre><code>sudo nano /usr/local/bin/docker-setup-cc2531.sh
</code></pre>
Copy the following content:
<pre><code>#!/bin/bash
USBDEV=`readlink -f /dev/cc2531`
read minor major < <(stat -c '%T %t' $USBDEV)
if [[ -z $minor || -z $major ]]; then
    echo 'Device not found'
    exit
fi
dminor=$((0x${minor}))
dmajor=$((0x${major}))
CID=`docker ps -a --no-trunc | grep koenkk/zigbee2mqtt | head -1 |  awk '{print $1}'`
if [[ -z $CID ]]; then
    echo 'CID not found'
    exit
fi
echo 'Setting permissions'
echo "c $dmajor:$dminor rwm" > /sys/fs/cgroup/devices/docker/$CID/devices.allow
</code></pre>
Set permissions:
<pre><code>sudo chmod 744 /usr/local/bin/docker-setup-cc2531.sh
</code></pre>
Create docker-event-listener.sh
<pre><code>sudo nano /usr/local/bin/docker-event-listener.sh
</code></pre>
Copy the following content:
<pre><code>#!/bin/bash
docker events --filter 'event=start'| \
while read line; do
    /usr/local/bin/docker-setup-cc2531.sh
done
</code></pre>
Set permissions:
<pre><code>sudo chmod 744 /usr/local/bin/docker-event-listener.sh
</code></pre>
Create docker-event-listener.service
<pre><code>sudo nano /etc/systemd/system/docker-event-listener.service
</code></pre>
Copy the following content:
<pre><code>[Unit]
Description=Docker Event Listener for TI CC2531 device
After=network.target
StartLimitIntervalSec=0
[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=/bin/bash /usr/local/bin/docker-event-listener.sh

[Install]
WantedBy=multi-user.target
</code></pre>
Set permissions:
<pre><code>sudo chmod 744 /etc/systemd/system/docker-event-listener.service
</code></pre>
Reload daemon
<pre><code>sudo systemctl daemon-reload
</code></pre>
Start Docker event listener
<pre><code>sudo systemctl start docker-event-listener.service
</code></pre>
Status Docker event listener
<pre><code>sudo systemctl status docker-event-listener.service
</code></pre>
Enable Docker event listener
<pre><code>sudo systemctl enable docker-event-listener.service
</code></pre>
Verify Zigbee2MQTT
Reconect USB sniffer
<pre><code>ls -al /dev/cc2531
</code></pre>
<pre><code>lrwxrwxrwx 1 root root 7 Sep 28 21:14 /dev/cc2531 -> ttyACM0
</code></pre>

### Installation du contôleur zig-a-zig-ah! (Bâton CC2652)
Create a new udev rule for cc2652, idVendor and idProduct must be equal to values from lsusb command. The rule below creates device /dev/cc2652:
<pre><code>echo "SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"1a86\", ATTRS{idProduct}==\"7523\", SYMLINK+=\"cc2652\",  RUN+=\"/usr/local/bin/docker-setup-cc2652.sh\"" | sudo tee /etc/udev/rules.d/98-cc2652.rules
</code></pre>
Reload newly created rule using the following command:
<pre><code>sudo udevadm control --reload-rules
</code></pre>
Create docker-setup-cc2652.sh
<pre><code>sudo nano /usr/local/bin/docker-setup-cc2652.sh
</code></pre>
Copy the following content:
<pre><code>#!/bin/bash
USBDEV=`readlink -f /dev/cc2652`
read minor major < <(stat -c '%T %t' $USBDEV)
if [[ -z $minor || -z $major ]]; then
    echo 'Device not found'
    exit
fi
dminor=$((0x${minor}))
dmajor=$((0x${major}))
CID=`docker ps -a --no-trunc | grep koenkk/zigbee2mqtt | head -1 |  awk '{print $1}'`
if [[ -z $CID ]]; then
    echo 'CID not found'
    exit
fi
echo 'Setting permissions'
echo "c $dmajor:$dminor rwm" > /sys/fs/cgroup/devices/docker/$CID/devices.allow
</code></pre>
Set permissions:
<pre><code>sudo chmod 744 /usr/local/bin/docker-setup-cc2652.sh
</code></pre>
Create docker-event-listener.sh
<pre><code>sudo nano /usr/local/bin/docker-event-listener.sh
</code></pre>
Copy the following content:
<pre><code>#!/bin/bash
docker events --filter 'event=start'| \
while read line; do
    /usr/local/bin/docker-setup-cc2652.sh
done
</code></pre>
Set permissions:
<pre><code>sudo chmod 744 /usr/local/bin/docker-event-listener.sh
</code></pre>
Create docker-event-listener.service
<pre><code>sudo nano /etc/systemd/system/docker-event-listener.service
</code></pre>
Copy the following content:
<pre><code>[Unit]
Description=Docker Event Listener for TI cc2652 device
After=network.target
StartLimitIntervalSec=0
[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=/bin/bash /usr/local/bin/docker-event-listener.sh

[Install]
WantedBy=multi-user.target
</code></pre>
Set permissions:
<pre><code>sudo chmod 744 /etc/systemd/system/docker-event-listener.service
</code></pre>
Reload daemon
<pre><code>sudo systemctl daemon-reload
</code></pre>
Start Docker event listener
<pre><code>sudo systemctl start docker-event-listener.service
</code></pre>
Status Docker event listener
<pre><code>sudo systemctl status docker-event-listener.service
</code></pre>
Enable Docker event listener
<pre><code>sudo systemctl enable docker-event-listener.service
</code></pre>
Verify Zigbee2MQTT
Reconect USB sniffer
<pre><code>ls -al /dev/cc2652
</code></pre>
<pre><code>lrwxrwxrwx 1 root root 7 Sep 28 21:14 /dev/cc2652 -> ttyACM0
</code></pre>

## Installation d'un server NFS
<pre><code>sudo su
apt-get install nfs-kernel-server
</code></pre>
Créez une table d'export NFS
<pre><code>nano /etc/exports
</code></pre>
Copier coller les chemins ci-dessous
<pre><code>/apps/hassio 192.168.1.100(rw,no_root_squash,aync,no_subtree_check)
</code></pre>  

> Créer autant de ligne que de répertoire à partager  

Mettre à jour la table nfs
<pre><code>exportfs -ra
</code></pre>
Ouvrez les ports utilisés par NFS.
Pour savoir quels ports NFS utilise, entrez la commande suivante:
<pre><code>rpcinfo -p | grep nfs
</code></pre>
Ouvrez les ports générés par la commande précédente.
<pre><code>sudo ufw allow 2049
</code></pre>
Relancer le service
<pre><code>sudo service nfs-kernel-server reload
</code></pre>

## Docker mode swarm
### Installation d'un master node
<pre><code>sudo su
docker swarm init --advertise-addr 192.168.1.100
</code></pre>
### Installation d'un worker node
<pre><code>sudo su
 docker swarm join --token SWMTKN-1-45plvx8voqe5zzvt5jnxdyk6xmasyxb0krzwi3dq8ccsw5nvcr-7zb99uq704i02ztexz9yl30pn 192.168.1.100:2377
</code></pre>
Créer le network de type overlay (traefik,hassio...) : cocooning-network
### Deployer les stacks de base
<pre><code>sudo su
cd /apps/ddclient
docker stack deploy --compose-file docker-compose.yml ddclient
</code></pre>
> docker service update --image homeassistant/raspberrypi3-homeassistant:0.114.0 hassio_hassio

## K3S
#### Installation du master node
<pre><code>sudo su
curl -sfL https://get.k3s.io | sh -s - --token tokendetestoauat7579
</code></pre>
#### Installation d'un worker node
<pre><code>sudo su
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.1.71:6443 K3S_TOKEN=tokendetestoauat7579 sh -
</code></pre>
### Mode High Availability with Embedded DB (Experimental) avec etcd