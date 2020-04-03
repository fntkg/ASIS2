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
- La máquina nfsnis1 contiene el servicio `NFS` el cual se encarga de disponer para los clientes un sistema de ficheros y el servicio `LDAP` que se encarga de disponer cuentas de usuario para las máquinas cliente.
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
> En máquina `nfsnis1.7.ff.es.eu.org`.

1. Instalar `nfs-kernel-server nfs-common rpcbind`.
2. Crear carpetas que se quieren compartir, en este caso `/srv/nfs4/home/`.
3. Exportar dicha carpeta añadiendo en el fichero `/etc/exports` la línea:
    ```shell
    /srv/nfs4/home cliente1.7.ff.es.eu.org(rw,sync,no_root_squash,no_subtree_check)
    ```
    - La opción `rw` da permisos de lectura y escritura a los clientes que acceden a los ficheros exportados
    - La opción `sync` hace que `NFS` evita responder peticiones antes de escribir los cambios pendientes en el disco.
    - La opción `no_root_squash` permite que los usuarios con privilegios de administrador los mantengan sobre la carpeta compartida.
    - La opción `no_subtree_check` evita que `NFS` compruebe los directorios por encima del directorio compartido para verificar sus permisos y características. Esto añade algo de velocidad al sistema.
4. Reiniciar `NFS` con `sudo /etc/init.d/nfs-kernel-server restart`.


### Creación cliente NFS
> En `cliente1`

1. Instalar `nfs-common rpcbind`.
2. Crear el punto de montaje para las carpetas compartidas con `mkdir -p /srv/nfs4/home/`
    > Se usa la misma ruta que en servidor por comodidad.
    - La opción `-p` crea los directorios que no existan por encima de `home/`.
3. Dar permisos necesarios a las carpetas usando `chmod -R 777 /srv/nfs4/home`.
    - La opción `-R` realiza el cambio de privilegios de manera recursiva.
4. Realizar el montaje de las carpetas compartidas, usar para ello el comando `mount nfsnis1.7.ff.es.eu.org:/srv/nfs4/home /srv/nfs4/home`.
5. Para que el montaje se realize en el arranque del sistema, en el fichero `/etc/fstab/` añadir:
    ```shell
    nfsnis1.7.ff.es.eu.org:/srv/nfs4/home    /srv/nfs4/home nfs default 0 0
    ```
    
### Montaje servidor LDAP
> En `nfsnis1`

1. Instalar `slapd ldap-utils`.
2. Establecer contraseña administrativa de `slapd`.
3. Instalar `libnss-ldap`
    > Esta libreria ofrece una interfaz para editar las bbdd utilizadas para almacenar cuentas de usuario.
   - Establecer la dirección del servidor, en este caso `nfsnis1.7.ff.es.eu.org`
    - Establecer el `dn`, `dc=7,d=ff,dc=es,dc=eu,dc=org`.
    - Version de `LDAP` a usar `3`.
    - Guardar contraseñas en un archivo especial -> `yes`.
    - Identificarse para hacer consultas en la bbdd de `LDAP` -> `no`.
    - Nombre de cuenta con privilegios en `LDAP` -> `cn=admin,dc=7,d=ff,dc=es,dc=eu,dc=org`.
    - Repetir contraseña establecida anteriormente.
4. Configurar autentificación clientes: `auth-client-config -t nss -p lac_ldap`.
    - `-t nss` indicamos que vamos a modificar los archivos de `nss`.
    - `-p lac_ldap` indicamos que los datos debe tomarlos del archivo `lac_dlap`.
5. Actualizar las politicas de autentificación de `PAM` con el comando `pam-auth-update`. Dejar las opciones por defecto que suelen ser `LDAP authentication` y `UNIX authentication`.
6. Modificar el fichero `/etc/ldap.conf/` para que quede algo asi:
    ```shell
    host nfsnis1.7.ff.es.eu.org
    base dc=7,d=ff,dc=es,dc=eu,dc=org
    uri ldapi://nfsni1.7.ff.es.eu.org/
    rootbinddn cn=admin,dc=7,d=ff,dc=es,dc=eu,dc=org
    ldap_version 3
    bin_policy soft
    ```
7. Configurar el demonio `SLAPD` con el comando `dpkg-reconfigure slapd`.
    - Omitir configuración servidor OpenLDAP? -> `no`.
    - Nombre de dominio -> `7.ff.es.eu.org`.
    - Nombre de la organización -> `nfsnis1`.
    - Contraseña del administrador -> La establecida anteriormente.
    - Base de datos a usar -> La que salga por defecto.
    - Borrar bbdd al purgar `slapd` -> `no`.
    - Cambiar de sitio bbdd? -> `Si`.
    - Permitir protocolo v2? -> `no`.
8. Crear estructura del directorio, crear un fichero con extension `.ldif` y añadir lo siguiente:
    ```shell
    dn: ou=usuarios,dc=7,d=ff,dc=es,dc=eu,dc=org
    objectClass: organizationalUnit
    ou: usuarios

    dn: ou=grupos,dc=7,d=ff,dc=es,dc=eu,dc=org
    objectClass: organizationalUnit
    ou: grupos
    
    dn: uid=german,ou=usuarios,dc=7,d=ff,dc=es,dc=eu,dc=org
    objectClass: inetOrgPerson
    objectClass: posixAccount
    objectClass: shadowAccount
    uid: german
    sn: Garces
    givenName: German
    cn: German Garces
    displayName: German Garces
    uidNumber: 3000
    gidNumber: 3000
    userPassword: mi_password
    gecos: German Garces
    loginShell: /bin/bash
    homeDirectory: /srv/nfs4/home/german
    shadowExpire: -1
    shadowFlag: 0
    shadowWarning: 7
    shadowMin: 8
    shadowMax: 999999
    shadowLastChange: 10877
    mail: 757024@unizar.es
    postalCode: 29000
    o: nfnis1
    initials: GG
    
    dn: cn=grupo_german,ou=grupos,dc=7,d=ff,dc=es,dc=eu,dc=org
    objectClass: posixGroup
    cn: SMR2
    gidNumber: 3000
    ```
    > El directorio `home` del nuevo usuario se encuentra en el directorio de `NFS`.

    Para añadirlo al `DIT` (`Directory Information Tree`) ejecutar `ldapadd -x -D cn=admin,dc=7,d=ff,dc=es,dc=eu,dc=org -W -f fichero.ldif`.

- http://somebooks.es/12-11-perfiles-moviles-de-usuario-usando-nfs-y-ldap/


### Montaje cliente LDAP
> En `cliente1`

1. Instalar `libpam-ldap libnss-ldap nss-updatedb libnss-db nscd ldap-utils`.
    - Dirección URI del servidor -> `ldapi://nfsni1.7.ff.es.eu.org/`.
    - Nombre global único -> `dc=7,d=ff,dc=es,dc=eu,dc=org`.
    - Version de `LDAP` a usar `3`.
    - Guardar contraseñas en un archivo especial -> `yes`.
    - Identificarse para hacer consultas en la bbdd de `LDAP` -> `no`.
    - Nombre de cuenta con privilegios en `LDAP` -> `cn=admin,dc=7,d=ff,dc=es,dc=eu,dc=org`.
    - Repetir contraseña establecida en el servidor.
2. En el fichero `/etc/ldap.conf`, modificar las lineas para que queden algo asi:
    ```
    bind_policy soft
    bind_policy soft
    uri ldap://nfsnis1.7.ff.es.eu.org
    ```
3. Editar fichero `/etc/ldap/ldap.conf` para que quede algo asi:
    ```
    BASE dc=7,d=ff,dc=es,dc=eu,dc=org
    URI ldap://nfsnis1.7.ff.es.eu.org
    SIZELIMIT 0
    TIMELIMIT 0
    DEREF never
    ```
4. Editar el fichero `/etc/nsswitch.conf` para que quede algo asi:
    ```
    passwd:    files ldap
    group:     files ldap
    shadow:    files ldap
    hosts:    files dns
    networks: files
    protocols: db files
    services: db files
    ethers: db files
    rpc: db files
    ```
5. Actualizar caché local con el comando `nss_udpatedb ldap`.
6. Actualizar las politicas de autentificación de `PAM` con el comando `pam-auth-update`. Dejar las opciones por defecto que suelen ser `LDAP authentication` y `UNIX authentication`.
7. Añadir en el fichero `/etc/pam.d/common-session` la línea:
    ```
    session required pam_mkhomedir.so skel=/etc/skel/ umask=0022
    ```
8. En el fichero `/etc/pam.d/common-password` cambiar la línea:
    ```
    password    [success=1 user_unknown=ignore default=die]	pam_ldap.so use_authtok try_first_pass
    ```
    por la línea:
    ```
    password    [success=1 user_unknown=ignore default=die] pam_ldap.so
    ```
    

- http://somebooks.es/12-9-configurar-un-equipo-cliente-con-ubuntu-para-autenticarse-en-el-servidor-openldap/

## Pruebas realizadas

### Pruebas para NFS
> Desde la máquina `cliente1`

- Comprobar correcto montaje de las carpetas `NFS` con el comando `df -h`, salida esperada:
    ```shell
    ...
    nfsnis1.7.ff.es.eu.org    25G    2G    23G    13% /srv/nfs4/home
    ```
    Otra comprobación, es crear un fichero en la carpeta compartida del servidor y comprobar si se crea en la carpeta recién montada en el cliente.
- Para comprobar el montaje en el arranque, se reinició la máquina y se repitió el comando `df -h`.

### Pruebas para LDAP
**Nota** Para entender mejor el resultado de los comandos sobre un `DIT`, entender que es un arbol en el que cada nodo contiene un `dn` que es el identificador de cada nodo y esta formado por su `rdn` y el `dn` del padre.
Aparte del `dn`, cada nodo contiene un conjunto de atributos.

- Probar correcto añadido de información al `DIT`: ejecutar `slapcat`.
- Probar correcto añadido de usuario: `ldapsearch -xLLL -b "dc=7,d=ff,dc=es,dc=eu,dc=org" uid=german sn givenName cn`. Salida esperada:
    ```shell
    dn: uid=german,ou=usuarios,dc=7,d=ff,dc=es,dc=eu,dc=org
    sn: Garces
    givenName: German
    cn: German Garces
    ```
- Probar cacheado de la bbdd de LDAP en `cliente1`, ver si se ha creado el usuario `german` con `uid=3000` con el comando `getent passwd | grep german`.
- Prueba final es comprobar que se puede iniciar sesión en la cuenta `german` desde `cliente1`. Observar que en el primer inicio de sesión aparece:
    ```
    Creating directory /srv/nfs4/home/german
    ```
    Así vemos que NFS y LDAP funcionan conjuntamente como deben.

## Problemas encontrados
- No salía ninguna petición de las máquinas ubuntu, faltaba la opcion `dns-nameserver` en el fichero `/etc/network/interfaces`
- Las peticiones al servidor `Unbound` no funcionaban desde el cliente. Se cambió la configuración del `unbound` para que aceptara peticiones de la red de los clientes.
- No se automontaba el sistema de fichero `NFS` en el arranque del cliente, era por una opción mal escrita.
- El comando `nss_updatedb ldap` daba error, estaba mal escrita la URI en el fichero `/etc/ldap.conf`.
