# Práctica 1
> [name= Germán Garcés - 757024]
## Resumen
Esta práctica trataba de la creación de 2 máquinas virtuales, con openBSD como sistema operativo. Una de ellas que actuará como router ipv6 y la otra para comprobar el correcto funcionamiento del encaminador.
## Arquitectura

`central.cps.unizar.es`: encaminador por defecto de `orouter7`.

`orouter7`: router virtualizado que trabaja con direcciones ipv6, conecta la subred `vlan799` con `central`.

`vlan799`: red virtualizada con dirección `2001:470:736b:7ff::/64`

`o7ff2`: máquina virtual con configuración ipv6 automática, se ha usado para comprobar el correcto funcionamiento de router.

![](https://i.imgur.com/JrLY8E0.png)

## Comprehensión de los elementos significativos

### Configuración `orouter7`

En el fichero `/etc/hostname.vio0` se escribieron las siguientes líneas:
```
inet6 alias 2001:470:736b:f000::1071 64
-autoconfprivacy
```
De esta manera, le asignamos una dirección ipv6 a la interfaz `vio0` y le pedimos que no genere otras direcciones aleatorias.

Para indicarle el encaminador por defecto se modificó `/etc/mygate` y se le escribió la siguiente línea:
```
2001:470:736b:f000::1
```
Esta dirección es la dirección de `central.cps.unizar.es`

Por último se modificó el nombre de la máquina a `orouter7` en el archivo `/etc/myname`

Para crear la red virtual se siguieron los siguientes pasos:

Se creó un fichero `/etc/hostname.vlan799` y se añadieron las siguientes líneas:
```
inet6 alias 2001:470:736b:07ff::1 64 vlan 799 vlandev vio0
-autoconfprivacy
```
Con esto se consiguió indicar la dirección ipv6 deseada, se asoció la red virtual con la tarjeta `vio0` y se señaló que no se generen otras direcciones ip.

Para que la máquina actuase como router se añadió al fichero `/etc/sysctl.conf` la línea:
```
net.inet6.ip6.forwarding=1
```

Y por último, para poner en marcha el servicio de anuncio de prefijos se añadió en `/etc/rc.conf.local` la siguiente línea:
```
rad_flags=""
```
Y en `/etc/rad.conf/` la línea:
```
interface vlan799
```
Con esto lo que se consiguió es que a la hora de asignar ips a máquinas de la subred virtual, estas tuvieran el prefijo de la red virtual 799.
Tras todos estos cambios, se reinició el sistema de red con `sh /etc/netstart`.

### Configuración `o7ff2`

En primer lugar se indica que la tarjeta de red no va a tener ninguna dirección asociada pero que va a trabajar con direcciones ipv6, para esto se escribieron las siguientes líneas en `/etc/hostname.vio0`:
```
-inet6
-autoconfprivacy
up
```
Se escribe la instrucción “up” para indicar al fichero que aplique los cambios.

Después, para añadir a la máquina a la red virtual `799` se creó un fichero `/etc/hostname.vlan799` con el contenido siguiente:
```
vlan 799 vlandev vio0 up
inet6 autoconf
-autoconfprivacy
```
Esto lo que hace es decir al sistema operativo que la red virtual `799` va a usar la tarjeta de red `vio0` y que la configuración de la dirección va a ser dinámica. Como en el resto de interfaces, se ha indicado que no se generen otras direcciones ip.

### Pregunta adicional
**¿Qué ocurre si introducimos “inet6 autoconf” en el fichero “hostname.vio0” de la máquina interna de prueba y por qué?**

Ocurrirá que estamos asignando una ip automática a esta máquina, pero esta dirección ip corresponde a la subred física de central.

## Pruebas realizadas

Para probar la conectividad del router con `central.cps.unizar.es` se hizo `ssh` desde un ordenador del laboratorio de redes a `orouter7`.
Para probar el funcionamiento de la red virtual se realizó un `ping` desde `orouter7` a `o7ff2`.
Y por último, para probar el correcto funcionamiento del router se realizó `ping` desde una máquina del laboratorio de redes a `o7ff2`, de esta manera se vería si `orouter7` redirige bien los paquetes de la red física a la red virtual.

## Problemas encontrados y su solución

No había conectividad desde un ordenador del laboratorio a `orouter7`, faltaba por añadir el encaminador por defecto al router.

A la máquina `o7ff2` no se le asignaba una ipv6, esto ocurría porque el router virtual y esta máquina virtual se encontraban en distintas máquinas físicas. La solución fue mover `o7ff2` a la misma máquina en la que se encontraba el router.

El último problema fue que el router no encaminaba correctamente ya que desde `orouter7` si se podía hacer `ping` a `o7ff2` pero desde la máquina del laboratorio no se podía hacer. Este problema se ha solucionado solo, mientras se trataba de ver donde se perdían los paquetes (`traceroute`) el router comenzó a funcionar bien sin haber cambiado nada. Se piensa que no funcionaba debido a la lentitud a la hora de aplicar cambios en las máquinas virtuales debido a la conexión por vía wifi de la universidad ya que se estaba trabajando a través de un ordenador portátil.

## Anexo

ANEXO
Para establecer la conexión con las máquinas del laboratorio y levantar las máquinas virtuales se ha creado un pequeño script que crea 2 terminal conectadas a través de `ssh` con la máquina `155.210.154.208`. En caso de que estos ordenadores no estén encendidos, el script los enciende y espera 65 segundos (lo que tarda la máquina en encenderse completamente) para conectarse vía `ssh`.
El script está hecho de tal manera que es capaz de conectarse a las máquinas `205`, `207` y `208`, pero con una pequeña modificación se puede conectar a cualquiera del laboratorio

![](https://i.imgur.com/GnPG6el.png)
