# kubernetes 3/3

> Germán Garcés [757024]

## Resumen.

## Arquitectura de elementos relevantes del despliegue de aplicaciones en Kubernetes.

![](https://i.imgur.com/pqFJwh8.png)

En el nivel mas bajo se encuentra `corosync/pacemaker` que se encargan de gestionar la pertenencia al grupo de nodos para poder así utilizar una IP flotante (192.168.56.56). Esta ip flotante se asigna por defecto al master1 pero en caso de que este nodo falle, `corosync/pacemaker` se encarga de asignar la dirección a otro nodo en el grupo.

Cabe destacar que el mínimo numero de nodos necesarios es de 3 para poder tener un quorum y así tener tolerancia a un fallo.

![](https://i.imgur.com/XNmtFBY.png)

En el anterior esquema se puede ver como por encima de `corosync/pacemaker` desplegamos `k3s` y sobre él, las aplicaciones necesarias (en nuestro caso, `prometheus` y `grafena`) a las cuales se acceden mediante la IP flotante.

## Explicación de los diferentes elementos desplegados sobre Kubernetes y explicación básica de los conceptos y recursos utilizados.

**`corosync/pacemaker`**

Gestor de clusters, lo uso ya que tiene la capacidad de generar IPs flotantes, esto me es útil a la hora de gestionar fallos de nodos.

Archivo de configuración necesario para la comunicación de grupo con `corosync`: 

```bash
    totem {
      version: 2
      cluster_name: lbcluster
      transport: udpu
      interface {
        ringnumber: 0
        bindnetaddr: "direccion del propio nodo"
        broadcast: yes
        mcastport: 5405
      }
    }

    quorum {
      provider: corosync_votequorum
      two_node: 1
    }

    nodelist {
      node {
        ring0_addr: 192.168.56.2
        name: primary
        nodeid: 1
      }
      node {
        ring0_addr: 192.168.56.3
        name: secondary
        nodeid: 2
      }
      node {
        ring0_addr: 192.168.56.4
        name: terciary
        nodeid: 3
      }
    }

    logging {
      to_logfile: yes
      logfile: /var/log/corosync/corosync.log
      to_syslog: yes
      timestamp: on
    }

```

Creacion del servicio `pacemaker` para crear el clúster:

```bash
service {
  name: pacemaker
  ver: 1
}
```
Una vez creado el clúster y este se encuentra correctamente funcionando hay que asignar una IP flotante:

```bash
$ pcs resource create ClusterIP ocf:heartbeat:IPaddr2 ip=192.168.56.56 cidr_netmask=24 op monitor interval=30s
```

**k3s**

Para la instalación de `k3s` en las máquinas, se ha hecho uso de una herramienta llamada [k3sup](https://github.com/alexellis/k3sup).

Esta lo que hace es permitirte crear un clúster y añadir a este nodos worker u otros nodos master, usa `DQLite` como base de datos.

Para ello se ha creado el siguiente script y se ha ejecutado:

```bash
export SERVER_IP=192.168.56.2
export USER=root
export NODE_2=192.168.56.3
export NODE_3=192.168.56.4

k3sup install --ip $SERVER_IP --user $USER --cluster

k3sup join --ip $NODE_2 --user $USER --server-user $USER --server-ip $SERVER_IP --server

k3sup join --ip $NODE_3 --user $USER --server-user $USER --server-ip $SERVER_IP --server
```

Este script instala `k3s` en las máquinas indicadas con los datos necesarios para la creación de un cluster.

> Para validar este recurso, ir al siguiente apartado.


## Explicación de los métodos utilizados para la validación de la operativa.

Para validar que los nodos se encuentran en el grupo de `corosync`

```bash
$ corosync-cmapctl | grep members
runtime.totem.pg.mrp.srp.members.1.config_version (u64) = 0
runtime.totem.pg.mrp.srp.members.1.ip (str) = r(0) ip(192.168.56.2)
runtime.totem.pg.mrp.srp.members.1.join_count (u32) = 1
runtime.totem.pg.mrp.srp.members.1.status (str) = joined
runtime.totem.pg.mrp.srp.members.2.config_version (u64) = 0
runtime.totem.pg.mrp.srp.members.2.ip (str) = r(0) ip(192.168.56.3)
runtime.totem.pg.mrp.srp.members.2.join_count (u32) = 1
runtime.totem.pg.mrp.srp.members.2.status (str) = joined
runtime.totem.pg.mrp.srp.members.3.config_version (u64) = 0
runtime.totem.pg.mrp.srp.members.3.ip (str) = r(0) ip(s192.168.56.4)
runtime.totem.pg.mrp.srp.members.3.join_count (u32) = 1
runtime.totem.pg.mrp.srp.members.3.status (str) = joined
```

Para validar el cluster de `pacemaker`:

```bash
$ crm status
Last updated: Fri Jun 16 14:38:36 2015
Last change: Fri Jun 16 14:36:01 2015 via crmd on primary
Stack: corosync
Current DC: primary (1) - partition with quorum
Version: 1.1.10-42f2063
3 Nodes configured
0 Resources configured


Online: [ primary secondary terciary ]
```

Para validar la correcta asignación de la IP flotante:

```bash
$ pcs status
Cluster name: ha_cluster
Stack: corosync
Current DC: primary (version 1.1.18-11.el7_5.3-2b07d5c5a9) - partition with quorum
Last updated: Mon Sep 10 16:55:26 2018
Last change: Mon Sep 10 16:53:42 2018 by root via cibadmin on pcmk-1

3 nodes configured
1 resource configured

Online: [ primary secondary terciary ]

Full list of resources:

 ClusterIP      (ocf::heartbeat:IPaddr2):       Started primary

Daemon Status:
  corosync: active/disabled
  pacemaker: active/disabled
  pcsd: active/enabled
```

Se comprueba que el recurso `ClusterIP` se encuentra asignado a `primary`, es decir, el nodo master1

Para comprobar la tolerancia a fallos, se apaga `master1` y se vuelve a ejecutar el anterior comando:

```bash
$ pcs status
...

Online: [ secondary terciary]
OFFLINE: [ primary ]

Full list of resources:

 ClusterIP      (ocf::heartbeat:IPaddr2):       Started secondary

...
```

Se puede comprobar que la IP flotante se ha asignado automaticamente a `secondary`.

Validación de `k3s`:

```bash
$ kubectl get node
NAME         STATUS   ROLES    AGE     VERSION
master1 	 Ready    master   8m27s   v1.16.3-k3s.2
master2 	 Ready    master   7m12s   v1.16.3-k3s.2
master3 	 Ready    master   6m42s    1.16.3-k3s.2
```

## Problemas encontrados y su solución.

Al crear el cluster con corosync, la maquina "master1" formaba un grupo aparte sin "master2" y "master3". No se ha llegado a encontrar el motivo del error ya que era aleatorio, es decir, algunos días el cluster se iniciaba con los 3 miembros y otros días solo se iniciaba con "master2" y "master3".

Al crear el cluster k3s, la instalación de k3s se quedaba colgada.