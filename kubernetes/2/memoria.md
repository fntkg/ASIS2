# kubernetes

> Germán Garcés | Duración proyecto: 3h

## [Etapa inicial] Puesta en marcha básica de Ceph en Kubernetes.

**`common.yaml`**

Sse encarga de crear los recursos necesarios para, posteriormente, desplegar `ceph` y el operador `rook`. Esto lo realiza creando `CustomResourceDefinition` es decir, recursos personalizados para la situación.

También crea el espacio de nombres `rook-ceph`.

**`operator.yaml`**

Se encarga de poner en marcha `rook`.

```ruby
apiVersion: v1
kind: Namespace
metadata:
  name: rook-ceph
```

Se ha estudiado la documentación oficial y se ha visto la utilidad de los recursos `ConfigMap`: "A ConfigMap is an API object used to store non-confidential data in key-value pairs. A ConfigMap allows you to decouple environment-specific configuration from your container images , so that your applications are easily portable.".

**`cluster.yaml`**

Se encarga de desplegar ceph en los nodos (como mínimo requiere 3 nodos):

```ruby
dataDirHostPath: /var/lib/rook # Establece donde se almacenarán los ficheros de configuración de ceph

mon: # Establece el numero de monitores, en este caso uno por nodo
    count: 3
    allowMultiplePerNode: false

storage: # cluster level storage configuration and selection
  useAllNodes: true
  useAllDevices: true
```

**Comprobar despliegue de `ceph`**

```bash
[ger@archlinux]$ kubectl   -n   rook-ceph   exec   -it   $(kubectl   -n   rook-ceph   get   pod   -l   "app=rook-ceph-tools"   -o   \jsonpath='{.items[0].metadata.name}') bash
$ ceph status
  ...
  services:
    mon: 3 daemons, quorum a,b,c (age 24m)
    mgr: a(active, since 23m)
    osd: 3 osds: 3 up (since 22m), 3 in (since 22m)
  ...
```

En el fragmento de codigo se ven los 3 `OSD`, el manager, los 3 monitores y el `quorum`

## [Etapa 2] Aplicación web y almacenamiento distribuidos de dispositivos de bloques

**`storageclassRbdBlock.yaml`**

Se crea un recurso `CephBlockPool`, es uno de los `CustomResourceDefinition` definidos anteriormente. Se establecen 3 réplicas.

Se crea un recurso `StorageClass` y se establecen los secretos que contienen las credenciales del administrador y la política del recurso `Delete`. También se establece el pool en el que se va a encontrar esta unidad de almacenamiento `replicapool`.

**`mysql.yaml`**

Se ha usado `mysql-persistent-storage` como volumen para `wordpress-mysql`.

**`wordpress.yaml`**

Se ha establecido en el `PersistentVolumeClaim` lo siguiente:

```
storageClassName: rook-ceph-block
```

---

Problema encontrado y su solución: Ambos servicios `mysql` y `wordpress` se quedaban en un estado `pending`. Se llegó a la conclusión de que era por iniciar ambos servicios a la vez ya que no conseguína resolver las dependencias. Se solucionó dejando un espacio mayor entre despliegue y despliegue de cualquier `pod`.