# kubernetes 2/3

> Germán Garcés | 757024

## Resumen

En esta 2a parte del trabajo se ha comprendido como poner en marcha un clúster de almacenamiento `CEPH` y un gestor para este, `ROOK`.

Después se estudiaron los diferentes archivos `.yaml` que se encargaban de crear un `RBD` ("RADOS Block Devices"), es decir, un almacen de dispositivos de bloques.

Tras esto se crearon unos `PersistentVolumeClaim` y sus respectives volumenes para después lanzar una bbdd MySql y un servidor web Wordpress.

También se realizaron las pruebas indicadas en el guión respecto al `RBD`.

## Arquitectura de elementos relevantes del despliegue Kubernetes/Ceph/Aplicaciones.

Para este trabajo se han desplegado 3 nodos `worker` ya que es el número mínimo de máquinas que se requieren para poder desplegar correctamente `rook-ceph`. Por supuesto, también se tiene un nodo `master`.

Los 3 nodos necesarios es debido a que, según la documentación oficial de `Rook`, se requieren 3 `OSD` corriendo en nodos diferentes por la siguiente especificación: `replicated.size: 3`.

Se han desplegado también 2 servicios `mysql-pv-claim` y `wp-pv-claim` para hacer uso de `rook-ceph`.

Para la creación de los repositorios, se ha desplegado un sistema de ficheros `ceph` con 3 réplicas para el pool de metadatos y 3 replicas para el pool de datos

## Explicación de las diferentes aplicaciones desplegadas sobre Kubernetes con la explicación de los conceptos y  los recursos Kubernetes utilizados y explicación básica de los conceptos y recursos utilizados porCeph.

**`common.yaml`**

Se encarga de crear los recursos necesarios para, posteriormente, desplegar `ceph` y el operador `rook`. Esto lo realiza creando `CustomResourceDefinition` es decir, recursos personalizados para la situación.

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

Se encarga de desplegar ceph en los nodos

```ruby
dataDirHostPath: /var/lib/rook # Establece donde se almacenarán los ficheros de configuración de ceph

mon: # Establece el numero de monitores, en este caso uno por nodo
    count: 3
    allowMultiplePerNode: false

storage: # cluster level storage configuration and selection
  useAllNodes: true
  useAllDevices: true
```

**`storageclassRbdBlock.yaml`**

Se crea un recurso `CephBlockPool`, es uno de los `CustomResourceDefinition` definidos anteriormente. Se establecen 3 réplicas.

Se crea un recurso `StorageClass` y se establecen los secretos que contienen las credenciales del administrador y la política del recurso `Delete`. También se establece el pool en el que se va a encontrar esta unidad de almacenamiento `replicapool`.

**`mysql.yaml`**

Se ha usado `mysql-persistent-storage` como volumen para `wordpress-mysql`.

**`wordpress.yaml`**

Se ha establecido en el `PersistentVolumeClaim` lo siguiente: `storageClassName: rook-ceph-block`

**`kube-registry.yaml`**

Se ha establecido el volumen `storageClassName:rook-cephfs`.

También se ha establecido su volumen con el nombre del `persistentVolumeClaim`: `cephfs-pvc`.



## Explicación de los métodos utilizados para la validación de la operativa.

Cada elemento que se creaba en kubernetes, no se pasaba al siguiente paso hasta que todos los `pods` del recurso en cuestión 	estuvieran en estado `Running`.

Para comprobar el despliegue de `rook` y `ceph` se siguieron los pasos indicados en el enunciado del trabajo y se comprobaron que estuvieran los 3 monitores, el gestor y los 3 demonios en funcionamiento:

```bash
$ ceph status
  ...
  services:
    mon: 3 daemons, quorum a,b,c (age 24m)
    mgr: a(active, since 23m)
    osd: 3 osds: 3 up (since 22m), 3 in (since 22m)
  ...
```

Para comprobar el estado de `wordpress` simplemente se usó un explorador en la máquina host y se accedió a esta.

Al desplegar el sistema de ficheros, se repitió los pasos anteriores y se vió que se había añadido un servicio a `ceph` llamado `myfs`, es decir, el sistema de fichero

```bash
$ ceph status
	...
	services:
    	mon: 3 daemons, quorum a,b,c (age 6m)
    	mgr: a(active, since 11m)
    	mds: myfs:1 {0=myfs-a=up:active} 1 up:standby-replay
    	osd: 3 osds: 3 up (since 6m), 3 in (since 11m)
    ...
```

Para comprobar el correcto despliegue del repositorio, se ha realizado el port-forwarding indicado en el enunciado y se ha comprobado que no da error al acceder al puerto 5000:

```python
[ger@archlinux aplicacionesCephRook]$ python
>>> import requests
>>> r=requests.get("http://localhost:5000")
>>> print(r.status_code)
200
```

Para comprobar el funcionamiento del repositorio, se accedió a al sistema de ficheros `ceph` y se crearon varios archivos y directorios. Tras eso, se desmontó y se volvió a montar en otra máquina distinta y se vio que se mantenían los elementos creados anteriormente.

Para probar el funcionamiento correcto de la replicación, se hizo un `vagrant destroy w3` (la máquina que no contaba con el `mgr`, ni el DNS ni el de metricas) y se trató de accecer a `localhost:5000`. Se tuvo éxito, la operación de tipo `GET` devolvió un código de estado `200`.

## Problemas encontrados y su solución.

Se creó un script para automatizar el arranque de todo pero los recursos no se desplegaban de manera correcta debido a la falta de tiempo entre instrucciones. Por falta de tiempo se decidió hacer dicho despliegue de manera manual.

Al subir la imagen al repositorio, la instrucción `podman push` no daba ningún error. Sin embargo, ninguna imagen era subida. No se ha encontrado solución.

```bash
[ger@archlinux vagrantk3s]$ sudo podman pull bash:latest
# Todo correcto
[ger@archlinux vagrantk3s]$ sudo podman push --tls-verify=false 330fdabba8e4 localhost:5000/me/prueba:latest
Getting image source signatures
Handling connection for 5000
Handling connection for 5000
Handling connection for 5000
Handling connection for 5000
Handling connection for 5000
Handling connection for 5000
Handling connection for 5000
Handling connection for 5000
Copying blob eaee9bd0a424 skipped: already exists  
Copying blob 3e207b409db3 skipped: already exists  
Copying blob 597dbfcdb2e8 [--------------------------------------] 0.0b / 0.0b
Handling connection for 5000
Writing manifest to image destination
Handling connection for 5000
Storing signatures
```

```bash
[ger@archlinux vagrantk3s]$ kubectl run --generator=run-pod/v1 -i --tty p --image=localhost:5000/user/container  -- sh
#Se queda colgado, abro otra terminal y ejecuto lo siguiente
[ger@archlinux vagrantk3s]$ kubectl describe pod p
NAME                    READY     STATUS             RESTARTS   AGE
p                        0/1    ImagePullBackOff        0       52m
```
