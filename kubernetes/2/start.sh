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

## 3a parte
## repositorio y ceph fs
kubectl create -f /home/ger/asis2/kubernetes/2/aplicacionesCephRook/ceph/filesystem.yaml
kubectl create -f /home/ger/asis2/kubernetes/2/aplicacionesCephRook/ceph/storageclassCephFS.yaml
kubectl create -f /home/ger/asis2/kubernetes/2/aplicacionesCephRook/kube-registry.yaml
kubectl create -f /home/ger/asis2/kubernetes/2/aplicacionesCephRook/kubeRegistryService.yaml
kubectl create -f /home/ger/asis2/kubernetes/2/aplicacionesCephRook/kubeRegistryProxy.yaml

## Para poder habilitar conexion desde el host al repositorio
POD=$(kubectl get pods --namespace kube-system -l k8s-app=kube-registry -o template --template '{{range .items}}{{.metadata.name}} {{.status.phase}}{{"\n"}}{{end}}' | grep Running | head -1 | cut -f1 -d' ')
kubectl port-forward --namespace kube-system $POD 5000:5000 &

## Subir un contenedor al nuevo repositorio
sudo podman pull bash
sudo podman push --tls-verify=false 330fdabba8e4 localhost:5000/me/prueba:latest