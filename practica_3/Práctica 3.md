# Práctica 3
> Germán Garcés - 757024

## Índice
- [Resumen](#Resumen)
- [Arquitectura elementos relevantes](#Arquitectura-de-elementos-relevantes)
- [Comprehensión de elementos significativos de la práctica](#Comprehensión-de-elementos-significativos-de-la-práctica)
- [Pruebas realizadas](#Pruebas-realizadas)
- [Problemas encontrados](#Problemas-encontrados)
- [Anexo](#Anexo)

## Resumen

Gestionar cuentas de usuario y directorios distribuidos mediante LDAP y NFS  sobre Ubuntu, SIN Kerberos.

## Arquitectura de elementos relevantes
![](https://i.imgur.com/63TJvAa.png)

Explicación de los elementos del sistema:
- La máquina `orouter` se trata de un router virtualizado permitiendo el paso de mensajes de una subred a otra y entre los elementos de las redes virtuales.
- La máquina `ntp1` posee un servicio de tiempo `NTP` para la sincronización de todas las máquinas de las subredes y un servidor `unbound` al que se le hacen las peticiones.
- La máquina `ns1` posee el servidor con autoridad primario (o master) junto a una base de datos de las zonas de la red.
- La máquina `ns2` posee el servidor con autoridad secundario (o esclavo) el cual se encarga de mantener una copia de la base de datos de nombres.
- La máquina nfsnis1 contiene el servicio `NFS` el cual se encarga de disponer para los clientes un sistema de ficheros y el servicio `LDAP` que se encarga de disponer cuentas de usuario para las máquinas cliente.
- La máquina cliente1 se va a encargar de usar los diferentes servicios disponibles en la red. Esta ḿaquina tambien se ha usado como réplica del servicio `LDAP`.
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

**Con todo esto, el servidor LDAP ya funciona correctamente**

**Ahora se va a usar TLS y replicación para que este funcione de manera mas segura**

#### Montaje TLS

1. Instalar `gnutls-bin` y `ssl-cert`.
2. Crear una clave privada para la autoridad certificadora:
    ```shell
    sudo sh -c "certtool --generate-privkey > /etc/ssl/private/cakey.pem"
    ```
3. Crear `/etc/ssl/ca.info` para definir la CA:
    ```
    cn = nfsnis1
    ca
    cert_signing_key
    ```
4. Crear el certificado de CA auto firmado:
    ```shell
    sudo certtool --generate-self-signed \
    --load-privkey /etc/ssl/private/cakey.pem \ 
    --template /etc/ssl/ca.info \
    --outfile /etc/ssl/certs/cacert.pem
    ```
5. Crear una clave privada para el servidor:
    ```shell
    sudo certtool --generate-privkey \
    --bits 1024 \
    --outfile /etc/ssl/private/nfsnis1_slapd_key.pem
    ```
6. Crear el fichero `/etc/ssl/nfsni1.info`:
    ```
    organization = nfsnis1
    cn = nfsnis1.example.com
    tls_www_server
    encryption_key
    signing_key
    expiration_days = 3650
    ```
    > 10 años de caducidad para el certificado.
7. Crear el certificado del servidor:
    ```shell
    sudo certtool --generate-certificate \
    --load-privkey /etc/ssl/private/nfsnis1_slapd_key.pem \
    --load-ca-certificate /etc/ssl/certs/cacert.pem \
    --load-ca-privkey /etc/ssl/private/cakey.pem \
    --template /etc/ssl/nfsnis1.info \
    --outfile /etc/ssl/certs/nfsnis1_slapd_cert.pem
    ```
8. Ajustar permisos y membresías:
    ```shell
    sudo chgrp openldap /etc/ssl/private/nfsnis1_slapd_key.pem
    sudo chmod 0640 /etc/ssl/private/nfsnis1_slapd_key.pem
    sudo gpasswd -a openldap ssl-cert
    ```
9. Reiniciar `slapd` con el comando `sudo systemctl restart sladp.service`.
10. Crear el fichero `certinfo.ldif`:
    ```
    dn: cn=config
    add: olcTLSCACertificateFile
    olcTLSCACertificateFile: /etc/ssl/certs/cacert.pem
    -
    add: olcTLSCertificateKeyFile
    olcTLSCertificateKeyFile: /etc/ssl/private/nfsnis1_slapd_key.pem
    -
    add: olcTLSCertificateFile
    olcTLSCertificateFile: /etc/ssl/certs/nfsnis1_slapd_cert.pem
    ```
11. Usar `ldapmodify` para contar a `slapd` sobre TLS:
    ```shell
    sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f certinfo.ldif
    ```
#### Montaje replicación con TLS

1. Crear fichero `provider_sync.ldif':
    ```
    # Add indexes to the frontend db.
    dn: olcDatabase={1}mdb,cn=config
    changetype: modify
    add: olcDbIndex
    olcDbIndex: entryCSN eq
    -
    add: olcDbIndex
    olcDbIndex: entryUUID eq

    #Load the syncprov and accesslog modules.
    dn: cn=module{0},cn=config
    changetype: modify
    add: olcModuleLoad
    olcModuleLoad: syncprov
    -
    add: olcModuleLoad
    olcModuleLoad: accesslog

    # Accesslog database definitions
    dn: olcDatabase={2}mdb,cn=config
    objectClass: olcDatabaseConfig
    objectClass: olcMdbConfig
    olcDatabase: {2}mdb
    olcDbDirectory: /var/lib/ldap/accesslog
    olcSuffix: cn=accesslog
    olcRootDN: cn=admin,dc=7,dc=ff,dc=es,dc=eu,dc=org
    olcDbIndex: default eq
    olcDbIndex: entryCSN,objectClass,reqEnd,reqResult,reqStart

    # Accesslog db syncprov.
    dn: olcOverlay=syncprov,olcDatabase={2}mdb,cn=config
    changetype: add
    objectClass: olcOverlayConfig
    objectClass: olcSyncProvConfig
    olcOverlay: syncprov
    olcSpNoPresent: TRUE
    olcSpReloadHint: TRUE

    # syncrepl Provider for primary db
    dn: olcOverlay=syncprov,olcDatabase={1}mdb,cn=config
    changetype: add
    objectClass: olcOverlayConfig
    objectClass: olcSyncProvConfig
    olcOverlay: syncprov
    olcSpNoPresent: TRUE

    # accesslog overlay definitions for primary db
    dn: olcOverlay=accesslog,olcDatabase={1}mdb,cn=config
    objectClass: olcOverlayConfig
    objectClass: olcAccessLogConfig
    olcOverlay: accesslog
    olcAccessLogDB: cn=accesslog
    olcAccessLogOps: writes
    olcAccessLogSuccess: TRUE
    # scan the accesslog DB every day, and purge entries older than 7 days
    olcAccessLogPurge: 07+00:00 01+00:00
    ```
2. Crear directorio: `sudo -u openldap mkdir /var/lib/ldap/acesslog` y añadir el nuevo contenido: `sudo ldapadd -Q -Y EXTERNAL -H ldapi:/// -f provider_sync.ldif`.
3. Crear un directorio y crear la clave privada del consumidor:
    ```shell
    mkdir cliente1-ssl
    cd client1-ssl
    sudo certtool --generate-privkey \
    --bits 1024 \
    --outfile cliente1_slapd_key.pem
    ```
4. Crear fichero `cliente1.info`:
    ```
    organization = nfsnis1
    cn = cliente1.7.ff.es.eu.org
    tls_www_server
    encryption_key
    signing_key
    expiration_days = 3650
    ```
5. Crear el certificado del consumidor
    ```shell
    sudo certtool --generate-certificate \
    --load-privkey cliente1_slapd_key.pem \
    --load-ca-certificate /etc/ssl/certs/cacert.pem \
    --load-ca-privkey /etc/ssl/private/cakey.pem \
    --template cliente1.info \
    --outfile cliente1_slapd_cert.pem
    ```
6. Crear copia del certificado y transferir `cliente1-ssl/` al consumidor:
 ```shell
 cp /etc/ssl/certs/cacert.pem .
 cd ..
 scp -r cliente1-ssl a757024@cliente1.7.ff.es.eu.org:
 ```

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
    BASE dc=7,dc=ff,dc=es,dc=eu,dc=org
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
#### Montaje replicación y TLS en el cliente:
1. Instalar `slapd` y dejar la configuración como en el servidor.
2. Crear fichero `consumer_sync.ldif`:
    ```
    dn: cn=module{0},cn=config
    changetype: modify
    add: olcModuleLoad
    olcModuleLoad: syncprov

    dn: olcDatabase={1}mdb,cn=config
    changetype: modify
    add: olcDbIndex
    olcDbIndex: entryUUID eq
    -
    add: olcSyncRepl
    olcSyncRepl: rid=0 
    provider=ldap://nfsnis1.7.ff.es.eu.org 
    bindmethod=simple 
    binddn="cn=admin,dc=7,dc=ff,dc=es,dc=eu,dc=org"
    credentials=Egdxwa 
    searchbase="dc=7,dc=ff,dc=es,dc=eu,dc=org"
    logbase="cn=accesslog"
    logfilter="(&(objectClass=auditWriteObject)(reqResult=0))"                   schemachecking=on
    type=refreshAndPersist
    retry="60 +"
    syncdata=accesslog
    -
    add: olcUpdateRef
    olcUpdateRef: ldap://ldap01.example.com
    ```
3. Añadir el nuevo contenido: `sudo ldapadd -Q -Y EXTERNAL -H ldapi:/// -f consumer_sync.ldif`.
4. Configurar autentificacion TLS:
    ```shell
    sudo apt install ssl-cert
    sudo gpasswd -a openldap ssl-cert
    sudo cp cliente1_slapd_cert.pem cacert.pem /etc/ssl/certs
    sudo cp cliente1_slapd_key.pem /etc/ssl/private
    sudo chgrp openldap /etc/ssl/private/cliente1_slapd_key.pem
    sudo chmod 0640 /etc/ssl/private/cliente1_slapd_key.pem
    sudo systemctl restart slapd.service
    ```
5. Crear el fichero `/etc/ssl/certinfo.ldif` con el siguiente contenido:
    ```
    dn: cn=config
    add: olcTLSCACertificateFile
    olcTLSCACertificateFile: /etc/ssl/certs/cacert.pem
    -
    add: olcTLSCertificateKeyFile
    olcTLSCertificateKeyFile: /etc/ssl/private/cliente1_slapd_key.pem
    -
    add: olcTLSCertificateFile
    olcTLSCertificateFile: /etc/ssl/certs/cliente1_slapd_cert.pem
    ```
6. Configurar la bbdd de slapd con `sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f certinfo.ldif`
7. Configurar TLS para replicación desde el lado del consumidor, para ello, crear fichero `consumer_sync_tls.ldif` con el siguiente contenido:
    ```
    dn: olcDatabase={1}mdb,cn=config
    replace: olcSyncRepl
    olcSyncRepl: rid=0
    provider=ldap://nfsnis1.7.ff.es.eu.org
    bindmethod=simple
    binddn="cn=admin,dc=7,dc=ff,dc=es,dc=eu,dc=org"
    credentials=Egdxwa
    searchbase="dc=7,dc=ff,dc=es,dc=eu,dc=org"
    logbase="cn=accesslog"
    logfilter="(&(objectClass=auditWriteObject)(reqResult=0))"
    schemachecking=on 
    type=refreshAndPersist
    retry="60 +"
    syncdata=accesslog
    starttls=critical tls_reqcert=demand
    ```
    Implementar los cambios con `sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f consumer_sync_tls.ldif`.
    Reiniciar `slapd` `sudo systemctl restart slapd.service`.

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
### Pruebas replicación

- `ldapsearch -z1 -LLLQY EXTERNAL -H ldapi:/// -s base -b dc=7,d=ff,dc=es,dc=eu,dc=org contextCSN`, salida esperada:
    ```
    dn: c=7,d=ff,dc=es,dc=eu,dc=org
    contextCSN: 20120201193408.178454Z#000000#000#000000
    ```
    Tanto en cliente como en servidor tiene que salir el mismo resultado.
## Problemas encontrados
- No salía ninguna petición de las máquinas ubuntu, faltaba la opcion `dns-nameserver` en el fichero `/etc/network/interfaces`
- Las peticiones al servidor `Unbound` no funcionaban desde el cliente. Se cambió la configuración del `unbound` para que aceptara peticiones de la red de los clientes.
- No se automontaba el sistema de fichero `NFS` en el arranque del cliente, era por una opción mal escrita.
- El comando `nss_updatedb ldap` daba error, estaba mal escrita la URI en el fichero `/etc/ldap.conf`.
- Al modificar la base de datos de `LDAP` para añadir `TLS`, daba un error, esto era por el orden al modificar los elementos.

## Anexo

### Script empleado para encender las máquinas de los laboratorios:
No es muy interactivo pero hace su funcion, pasar como primer y unico parametro el numero de terminales conectadas a la máqina 206 que se quieren abrir.
```shell
#!/bin/bash

func(){
echo ">>Sending ping to  $1..."
ping=$(ping -c 1 $1 | grep bytes | wc -l)
if [ "$ping" -gt 1 ];then
        echo ">>Host up"
        echo ">>Opening ssh connection..."
        ssh a757024@$1 "./asis.sh"
        gnome-terminal  -- bash  -c  "ssh -X a757024@$1" &> /dev/null
else
        echo ">>Host down"
        echo ">>Establish connection with "central"..."
        if [ "$2" -eq 8 ] ; then
                mac=00:10:18:80:67:84
        elif [ "$2" -eq 7 ] ; then
                mac=00:10:18:80:73:38
        elif [ "$2" -eq 5 ]; then
                mac=00:10:18:80:67:94
        elif [ "$2" -eq 6 ]; then
                mac=00:10:18:80:67:f4
        fi
        ssh a757024@central.cps.unizar.es /usr/local/etc/wakeonlan $mac
        for x in {1..65} ; do
                sleep 1
                printf .
        done | pv -pt -i0.2 -s65 -w 80 > /dev/null
        func $1 $2
fi
}

i=0
while [ "$i" -lt "$1" ]
do
        func 155.210.154.206 6
        i=$(( $i + 1 ))
done

exit 0
```

### Script empleado para encender las maquinas virtuales
No requiere de ninguna interaccion.
```shell
#/bin/bash

virsh -c qemu:///system define /misc/alumnos/as2/as22019/a757024/orouter7.xml
virsh -c qemu:///system define /misc/alumnos/as2/as22019/a757024/o7ff2.xml
virsh -c qemu:///system define /misc/alumnos/as2/as22019/a757024/o7ff3.xml
virsh -c qemu:///system define /misc/alumnos/as2/as22019/a757024/o7ff4.xml
virsh -c qemu:///system define /misc/alumnos/as2/as22019/a757024/o7ff5.xml
virsh -c qemu:///system define /misc/alumnos/as2/as22019/a757024/o7fe6.xml

virsh -c qemu:///system start orouter7
virsh -c qemu:///system start o7ff2
virsh -c qemu:///system start o7ff3
virsh -c qemu:///system start o7ff4
virsh -c qemu:///system start o7ff5
virsh -c qemu:///system start o7fe6
```

### Script empleado para apagar lás maquinas
**Error** al apagar las maquinas ubuntu, el terminal se queda colgado (ya sea a mano o desde el script),por lo que esas maquinas se apagan de forma manual, no desde el script.
```shell
#/bin/bash

ssh a757024@2001:470:736b:7ff::4 'doas shutdown -h now'
ssh a757024@2001:470:736b:7ff::3 'doas shutdown -h now'
ssh a757024@2001:470:736b:7ff::2 'doas shutdown -h now'
ssh a757024@2001:470:736b:7ff::1 'doas shutdown -h now'

for i in {1..4}; do
    sleep 1 # Para dar tiempo a que se apagen correctamente.
	echo "Apagando maquinas #$i"
done

virsh -c qemu:///system destroy o7ff4
virsh -c qemu:///system destroy o7ff3
virsh -c qemu:///system destroy o7ff2
virsh -c qemu:///system destroy orouter7

virsh -c qemu:///system undefine orouter7
virsh -c qemu:///system undefine o7ff2
virsh -c qemu:///system undefine o7ff3
virsh -c qemu:///system undefine o7ff4
virsh -c qemu:///system undefine o7ff5
virsh -c qemu:///system undefine o7fe6
```
