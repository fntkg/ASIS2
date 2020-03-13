**Falta  por hacer**:
- Meter `router1` al servicio de nombres
- Probar la resolución de nombres con los servidores DNS de `google.com`
> No funciona la resolucion inversa, no se como sincronizar master y slave
- Explicar [Configuración servicio DNS](#configuración-servicio-nsd)
- Unbound y NTP
# Práctica 2
> Germán Garcés - 757024
## Resumen
Puesta en marcha de servicios distribuidos básicos, NTP y DNS, con la configuración de red y VMs necesarias.
## Arquitectura de elementos relevantes
**Novedad** respecto a la 1a práctica es que `orouter7` tiene un nombre en el servicio de nombres, `router1`. También se han añadido dos máquinas  `o7ff3` y `o7ff4` con direcciones ipv6 `2001:470:736b:7ff::3` y `2001:470:736b:7ff::4` respectivamente. Estas máquinas van a ser los servidores con autoridad primario y secundario y tendrán de nombre `ns1` y `ns2`.
![](https://i.imgur.com/3Q0SnMn.png)

## Comprehensión   de   elementos   significativos   de   la   práctica 
### Puesta en marcha servicio DNS y NTP
#### Clientes DNS

Para indicar a  todas las máquinas quienes son sus servidores de nombres, en la ruta `/etc/resolv.conf` añadir las siguientes líneas:
```
search 7.ff.es.eu.org
nameserver 2001:470:736b:7ff::3 ; ns1
nameserver 2001:470:736b:7ff::4 ; ns2
```
Basicamente lo que hacemos es indicar a las VM quienes son los servidores de nombres. En este caso, la dirección `2001:470:4736b:7ff::3` es el servidor primario o master y la dirección `2001:470:736b:7ff::4` es el servidor secundario o esclavo.
La línea `search W.ff.es.eu.org` lo que hace es autocompletar el nombre de los dominios cuando no se indica un dominio en concreto. Por ejemplo si hiciesemos `ssh ns1`, se autocompletaría a `ssh ns1.7.ff.es.eu.org`.

Y para poner en marcha el demonio `nsd`, en `/etc/rc.conf.local` se ha añadido la siguiente línea:
```
nsd_flags=""
```
#### Configuración servidor con autoridad primario
> En la maquina `2001:470:736b::3`.
##### Configuración servicio NSD

El archivo `/var/nsd/etc/nsd.conf` ha quedado así:
```
server:
        hide-version: yes
        database: "/var/nsd/db/nsd.db"
        username: _nsd
        verbosity: 1
        port: 53
        server-count: 1
        ip6-only: yes
        zonesdir: "/var/nsd/zones"
        logfile: "/var/log/nsd.log"
        pidfile: "/var/nsd/run/nsd.pid"

remote-control:
        control-enable: yes
        control-interface: /var/run/nsd.sock
        control-port: 8952
        server-key-file: "/var/nsd/etc/nsd_server.key"
        server-cert-file: "/var/nsd/etc/nsd_server.pem"
        control-key-file: "/var/nsd/etc/nsd_control.key"
        control-cert-file: "/var/nsd/etc/nsd_control.pem"

zone:
        name: "7.ff.es.eu.org"
        zonefile: "master/7.ff.es.eu.org"
        notify: 2001:470:736b:7ff::4 NOKEY
        provide-xfr: 2001:470:736b:7ff::4 NOKEY

zone:
        name: "7.0.b.6.3.7.0.7.4.0.1.0.0.2.ip6.arpa"
        zonefile: "slave/7.ff.es.eu.org.inverso"
        notify: 2001:470:736b:7ff::4 NOKEY
        provide-xfr: 2001:470:736b:7ff::4 NOKEY

```
> Para comprobar que no existieran error sintácticos se usó `nsd-checkconf`.
##### Creación base de datos DNS

En la ruta `/var/nsd/zones/master` se ha creado un nuevo archivo de nombre `7.ff.es.eu.org` y se han incluido en el las siguientes líneas:
```
; Start of authority record for 7.ff.es.eu.org
$ORIGIN 7.ff.es.eu.org.

7.ff.es.eu.org. IN      SOA     ns1.7.ff.es.eu.org.     757024.unizar.es. (
                                2009070200 ; Serial number
                                10800      ; Refresh (3 horas)
                                1200       ; Retry (20 minutos)
                                3600000    ; Expire (40+ dias)
                                3600 )     ; Minimum (1 hora)
        NS      ns1.7.ff.es.eu.org.        ; Authority server (primary)
        NS      ns2.7.ff.es.eu.org.        ; Authority server (secondary)

; Resolucion directa

ns1     IN      AAAA    2001:470:736b:7ff::3
ns2     IN      AAAA    2001:470:736b:7ff::4

; CNAME

o7ff3   IN      CNAME   ns1
o7ff4   IN      CNAME   ns2 
```
> Para comprobar que no existieran error sintácticos se usó `nsd-checkzone`.
- En primer lugar, en la variable `$ORIGIN` se guarda el valor del dominio (`7.ff.es.eu.org`) para evitar escribir de más.
- El registro `SOA` se encarga de definir el nombre de la zona, el servidor master, una dirección de "soporte técnico" y algunos detalles.
- Las entradas `NS` definen quienes son los servidores con autoridad de la zona, en este caso `ns1.7.ff.es.eu.org` es el primario y `ns2.7.ff.es.eu.org` el secundario.
- La tercera entrada indica cual es la dirección ip de estos servidores
- El apartado `CNAME` permite usar nicknames, en este caso le indicamos que si se usan los nombres de las VM, estos se transformen en el nombre que le corresponde para el servidor de nombres.

Para la resolución inversa se ha creado otro archivo `7.ff.es.eu.org.inverso` y se ha escrito lo siguiente:
```
@       IN      SOA     ns1.7.ff.es.eu.org.     757024.unizar.es. (
                                2009070200 ; Serial number
                                10800      ; Refresh (3 horas)
                                1200       ; Retry (20 minutos)
                                3600000    ; Expire (40+ dias)
                                3600 )     ; Minimum (1 hora)
; Resolucion inversa

$ORIGIN 0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.f.f.7.0.b.6.3.7.0.7.4.0.1.0.0.2.ip6.arpa.

3       IN      PTR     ns1.7.ff.es.eu.org.
4       IN      PTR     ns2.7.ff.es.eu.org. 
```
> Para comprobar que no existieran error sintácticos se usó `nsd-checkzone`.
- `@` indica el nombre de la zona, en este caso `7.0.b.6.3.7.0.7.4.0.1.0.0.2.ip6.arpa`

### Configuración servidor con autoridad secundario
> En la maquina `2001:470:736b::4`.
## Problemas encontrados

- Se escribió la opción `ip-address: 2001:470:736b:7ff::2` sin entender que era, cuando se descubrió que era para escuchar en una interfaz se eliminó dicha línea del archivo de configuración de `nsd`.
