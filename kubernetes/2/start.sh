#!/bin/bash

################
##
## NO EJECUTAR
## PONER LINEA A LINEA PARA QUE SE CREEN CORRECTAMENTE LOS PODS Y SUS DEPENDENCIAS
##
################


## Primera parte
## Poner en marcha ceph-rook
kubectl create -f /home/ger/asis2/kubernetes/2/aplicacionesCephRook/ceph/common.yaml
kubectl create -f /home/ger/asis2/kubernetes/2/aplicacionesCephRook/ceph/operator.yaml
kubectl create -f /home/ger/asis2/kubernetes/2/aplicacionesCephRook/ceph/cluster.yaml
kubectl create -f /home/ger/asis2/kubernetes/2/aplicacionesCephRook/ceph/toolbox.yaml


## 2a parte
## Poner en marcha mysql y wordpress
kubectl create -f /home/ger/asis2/kubernetes/2/aplicacionesCephRook/ceph/storageclassRbdBlock.yaml 
kubectl create -f /home/ger/asis2/kubernetes/2/aplicacionesCephRook/mysql.yaml
kubectl create -f /home/ger/asis2/kubernetes/2/aplicacionesCephRook/wordpress.yaml
kubectl create -f /home/ger/asis2/kubernetes/2/aplicacionesCephRook/ceph/direct-mount.yaml