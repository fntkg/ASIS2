#!/bin/bash -x

HOSTNAME=$1
NODEIP=$2
MASTERIP=$3
NODETYPE=$4

timedatectl set-timezone Europe/Madrid

cd /vagrant


echo $1 > /etc/hostname
hostname $1

{ echo 192.168.1.90 m1; echo 192.168.1.91 m2; echo 192.168.1.92 m3; cat /etc/hosts
} > /etc/hosts.new
mv /etc/hosts{.new,}

cp k3s /usr/local/bin/


if [ $NODETYPE = "master" ]; then 
  INSTALL_K3S_SKIP_DOWNLOAD=true \
  ./install.sh server \
  --token "wCdC16AlP8qpqqI53DM6ujtrfZ7qsEM7PHLxD+Sw+RNK2d1oDJQQOsBkIwy5OZ/5" \
  --flannel-iface enp0s8 \
  --bind-address $NODEIP \
  --node-ip $NODEIP --node-name $HOSTNAME \
  --disable traefik \
  --node-taint k3s-controlplane=true:NoExecute \
  --cluster-init
  #--disable servicelb
  #--advertise-address $NODEIP
  #--cluster-domain “cluster.local”
  #--cluster-dns "10.43.0.10"
  
  cp /etc/rancher/k3s/k3s.yaml /vagrant
  
elif [ $NODETYPE = "worker"]; then
  INSTALL_K3S_SKIP_DOWNLOAD=true \
  ./install.sh agent --server https://${MASTERIP}:6443 \
  --token "wCdC16AlP8qpqqI53DM6ujtrfZ7qsEM7PHLxD+Sw+RNK2d1oDJQQOsBkIwy5OZ/5" \
  --node-ip $NODEIP --node-name $HOSTNAME --flannel-iface enp0s8
else
  INSTALL_K3S_SKIP_DOWNLOAD=true \
  ./install.sh server --server https://${MASTERIP}:6443 \
  --server https://192.168.1.90:6443 \
  --token "wCdC16AlP8qpqqI53DM6ujtrfZ7qsEM7PHLxD+Sw+RNK2d1oDJQQOsBkIwy5OZ/5" \
  --node-ip $NODEIP --node-name $HOSTNAME --flannel-iface enp0s8
fi
