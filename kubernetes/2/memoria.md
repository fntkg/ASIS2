# kubernetes


## [Etapa inicial] Puesta en marcha básica de Ceph en Kubernetes.

**#1** Puesta en marcha de kubernets.

Editar fichero `Vagrantfile`.

```bash
vagrant up
```

**#2** Puesta en marcha de `rook-ceph`.

El manifiesto `common.yaml` se encarga de crear los recursos necesarios para, posteriormente, desplegar `ceph` y el operador `rook`. También crea el espacio de nombres `rook-ceph`.

> Como operador entiendo que se refiere al recurso que se encarga de gestionar `ceph` en este caso.

El manifiesto `operator.yaml` se encarga de poner en marcha `rook`.

El manifiesto `cluster.yaml` se encarga de desplegar ceph en los nodos (como mínimo requiere 3 nodos):

```bash
dataDirHostPath: /var/lib/rook # Establece donde se almacenarán los ficheros de configuración de ceph

mon: # Establece el numero de monitores, en este caso uno por nodo
    count: 3
    allowMultiplePerNode: false

storage: # cluster level storage configuration and selection
  useAllNodes: true
  useAllDevices: true
```

Comprobación de `ceph`, en el siguiente fragmento de codigo se ven los 3 `OSD`, el manager, los 3 monitores y el `quorum`

```bash
> ceph status
  ...
  services:
    mon: 3 daemons, quorum a,b,c (age 24m)
    mgr: a(active, since 23m)
    osd: 3 osds: 3 up (since 22m), 3 in (since 22m)
  ...
```
