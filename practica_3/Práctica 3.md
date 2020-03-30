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
3. Y por ultimo, para indicar cual es el servidor de nombres, en la ruta `/etc/resolvconf/resolv.conf.d/base` se ha añadido `nameserver 2001:470:736b:7ff::2` y se ha reiniciado el servicio con `resolvconf -u`.

### Creación servidor NFS
> En `nfsnis1`

Pasos seguidos:
1. Instalación `nfs-kernel-server` usando `apt-get install`.
2. Creación directorio `/srv/nfs4/home` que es el que se va a compartir.
3. En el fichero `/etc/idmapd.conf` añadida la línea `Domain = 7.ff.es.eu.org`
4. En el fichero `/etc/exports` se ha añadió `/srv/nfs4/home/cliente1.7.ff.es.eu.org(rw,sync,no_subtree_check)` para indicar que directorio exportar y a quién.

    - `rw` permite leer y escribir en los ficheros.
    - `sync` fuerza a NFS a escribir los cambios en el disco antes de responder, para evitar inconsistencias.
    - `no_subtree_check` hace que el host no checkee si el archivo sigue disponible en el directorio exportado para cada petición. Activar la opción podría dar problemas al renombrar archivos que el cliente tiene abiertos.
    - **Opcional** `no_root_squash` Por defecto, nfs traduce cada petición de `root` a un usuario sin privilegios en el servidor. Esta opción desactiva dicho comportamiento por defecto.
5. Reiniciar con `systemctl restart nfs-kernel-server`

### Creación cliente NFS
> En `cliente1`

1. Instalación `nfs-common`
2. En el fichero `/etc/idmapd.conf` añadida la línea `Domain = 7.ff.es.eu.org`
3. Ejecutar `mount nfsnis1.7.ff.es.eu.org:/srv/nfs4/home /home/a757024/` para montar el sistema de fichero que nos proporciona `nfsnis1`.

#### Montaje al arrancar la máquina

Añadir a `/etc/fstab/` la línea:
```shell
nfsnis1.7.ff.es.eu.org:/srv/nfs4/home    /home/a757024/    nfs    auto,nofail,noatime,nolock,tcp,actimeo=1800 0 0
```
Opciones:
- `auto` se encarga de montar el `nfs` en el arranque del sistema.
- `nofail` ignora el montaje si el `nfs` no esta disponible, esto evita errores.
- No actualiza el inode con el tiempo de acceso, para aumentar prestaciones.
- `nolock` permite que las aplicaciones puedan bloquear archivos pero solo contra otras aplicaciones en el mismo cliente.
- `tcp` establece el protocolo de comunicación.
- `actimeo=1800` pone las variables `acregmin`, `acregmax`, `acdirmin`, `acdirmax` al valor asignado, estas variables gestionan tiempos de peticiones y respuestas de `nfs`.

## Pruebas realizadas

### Pruebas para NFS
> Desde la máquina `cliente1`

Crear un **con privilegios de administrador** fichero de nombre `general.test` y comprobar su usuario y su grupo con `ls -l`.
Se comprueba que la salida es:
```shell
-rw-r--r-- 1 nobody nogroup 0 Mar 30 19:34 general.test
```

Esta salida es correcta ya que NFS por defecto cambia los ficheros con propietario `root` a ficheros con propietario `nobody` y grupo `nogroup`.

## Problemas encontrados
- No salía ninguna petición de las máquinas ubuntu, faltaba la opcion `dns-nameserver` en el fichero `/etc/network/interfaces`
- Las peticiones al servidor `Unbound` no funcionaban desde el cliente. Se cambió la configuración del `unbound` para que aceptara peticiones de la red de los clientes.
