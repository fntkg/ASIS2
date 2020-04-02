# Práctica 3
> Germán Garcés - 757024

## Resumen
## Arquitectura de elementos relevantes
![](https://i.imgur.com/63TJvAa.png)

Explicación de los elementos del sistema:
- La máquina `orouter` se trata de un router virtualizado permitiendo el paso de mensajes de una subred a otra y entre los elementos de las redes virtuales.
- La máquina `ntp1` posee un servicio de tiempo `NTP` para la sincronización de todas las máquinas de las subredes y un servidor `unbound` al que se le hacen las peticiones.
- La máquina `ns1` posee el servidor con autoridad primario (o master) junto a una base de datos de las zonas de la red.
- La máquina `ns2` posee el servidor con autoridad secundario (o esclavo) el cual se encarga de mantener una copia de la base de datos de nombres.
- La máquina nfsnis1 contiene el servicio `NFS` el cual se encarga de disponer para los clientes un sistema de ficheros. ERROR Poner LDPA
> [color=#ff0000] **ERROR** Poner LDPA EN NFSNIS1
- La máquina cliente1 se va a encargar de usar los diferentes servicios disponibles en la red.
- En la red virtual `799` se encuentran todos los servicios disponibles para los clientes en la red `798`.
## Comprehensión de elementos significativos de la práctica

### Creacion interfaces de red nuevas máquinas
> Maquinas con `ubuntu 16.04`

En primer lugar, para dotar a las máquinas ubuntu de una interfaz de red y un servidor dns al que hacer cuestiones, se siguieron los siguientes pasos:
1. En `/etc/network/interfaces` se han añadido las siguientes líneas:
```shell
source /etc/network/interfaces.d/*

auto lo
iface lo inet6 loopback

auto ens3
iface ens3 inet6 manual

auto ens3.798 
iface ens3.798 inet6 static
	address 2001:470:736b:7fe::6
	netmask 64
	gateway 2001:470:736b:7fe::1
	autoconf 0
	vlan-raw-device ens3
	dns-nameservers 2001:470:736b:7ff::2
```
> La dirección `address` es la adecuada para cada máquina
2. Para crear correctamente la red virtual 798, se ha ejecutado `vconfig add ens3 798`.

### Creación servidor NFS

- http://somebooks.es/10-2-como-instalar-nfs/
- http://somebooks.es/10-2-como-instalar-nfs/

### Creación cliente NFS
> En `cliente1`

- http://somebooks.es/10-4-acceder-a-la-carpeta-compartida-con-nfs-desde-un-cliente-con-ubuntu/

### Montaje servidor LDAP
> En `nfsnis1`

- http://somebooks.es/12-7-instalar-y-configurar-openldap-en-el-servidor-ubuntu/
- http://somebooks.es/12-11-perfiles-moviles-de-usuario-usando-nfs-y-ldap/


### Montaje cliente LDAP
> En `cliente1`

- http://somebooks.es/12-9-configurar-un-equipo-cliente-con-ubuntu-para-autenticarse-en-el-servidor-openldap/

## Pruebas realizadas

### Pruebas para NFS
> Desde la máquina `cliente1`


### Pruebas para LDAP
**Nota** Para entender mejor el resultado de los comandos sobre un `DIT`, entender que es un arbol en el que cada nodo contiene un `dn` que es el identificador de cada nodo y esta formado por su `rdn` y el `dn` del padre.
Aparte del `dn`, cada nodo contiene un conjunto de atributos.

## Problemas encontrados
- No salía ninguna petición de las máquinas ubuntu, faltaba la opcion `dns-nameserver` en el fichero `/etc/network/interfaces`
- Las peticiones al servidor `Unbound` no funcionaban desde el cliente. Se cambió la configuración del `unbound` para que aceptara peticiones de la red de los clientes.
