# Installation d'un Raspberry Pi 3 et 4
## Installation de l'OS
### Installation d'ubuntu server
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
apt-get install zip
cd /
wget https://codeload.github.com/Cocooning-tech/apps/zip/master
unzip master
chown -R nobody:nogroup /apps-master
chmod -R 777 /apps-master
cd /apps-master
</code></pre>

> https://github.com/Cocooning-tech/system.git à changer en fonction du repositorie
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
      addresses: [192.168.1.99/24]
      gateway4: 192.168.1.1
  wifis:
    wlan0:
      dhcp4: no
      dhcp6: no
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

#### Mettre à jour la date
A faire
### Installation de dietpi

## Installation de k3s
### Mode single node master sans etcd
#### Installation du master node
<pre><code>sudo su
curl -sfL https://get.k3s.io | sh -s - --token tokendetestoauat7579
</code></pre>
#### Installation d'un worker node
<pre><code>sudo su
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.1.71:6443 K3S_TOKEN=tokendetestoauat7579 sh -
</code></pre>
### Mode High Availability with Embedded DB (Experimental) avec etcd

## Installation de docker mode swarm
### Installation de docker
<pre><code>sudo su
apt-get install docker.io
apt-get install docker-compose
</code></pre>
#### Installation du master node swarm
<pre><code>sudo su
docker swarm init --advertise-addr 192.168.1.100
</code></pre>
#### Installation d'un worker node swarm
<pre><code>sudo su
docker swarm join --token SWMTKN-1-4xv6rbe2tfi91irtk6iy3uflpny4zjhh4gjvr5ij0lxhg8or4f-3c6wvopb9kgwiul62p1xabj07 192.168.1.101:2377
</code></pre>

## Montage d'un volume NFS sur le master node
### Création du server NFS
<pre><code>sudo su
apt-get install nfs-kernel-server
</code></pre>
Créez une table d'export NFS
<pre><code>nano /etc/exports
</code></pre>
Copier coller les chemins ci-dessous
<pre><code>/apps-master 192.168.1.100(rw,no_root_squash,async,no_subtree_check)
/apps-master/ddclient 192.168.1.100(rw,no_root_squash,async,no_subtree_check)
/apps-master/homeassistant 192.168.1.100(rw,no_root_squash,async,no_subtree_check)
</code></pre>

> Créer autant de ligne que de répertoire à partager 
> L'option async (dangereusse ?) permet de meilleures performances et le lancement de plusieurs replicas

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