# Aplicación administración distribuida

Como usar:

Los ficheros de configuración se encuentran en `~/.u`
> El conjunto de maquinas se especifica en `~/.u/hosts`

### Uso

Hacer ping al puerto `22` de un conjunto de maquinas:
`./u.rb p`
 
Ejecutar comandos en un conjunto de maquinas de manera remota:
`./u.rb s "COMANDO"`

> Cualquier otro comando o no poner algo en `COMANDO` aparecerá un **error**

## Funcionamiento general de la aplicación

Se ha intentado hacer una aplicación que sea capaz de añadir opciones de manera sencilla. Esto se ha hecho creando para cada opcion (en estos momentos `[ p | c COMANDO]`) una función. De tal manera que el programa principal solo lee la función, comprueba que el archivo `~/.u/hosts` existe y ya deriva a la función correspondiente.

Para el comando `p` se ha usado la biblioteca `net/ping`.
```ruby
Net::Ping::External.new(host, port, timeout)
```
> Comandos principales usados

Para el comando `c COMANDO` se ha usado la biblioteca `net/ssh` y se ha **reutilizado**  `net/ping` para comprobar si una maquina esta viva o no y evitar así errores de ssh.
```ruby
Net::SSH.start(host, 'username', password: "password")
ssh.exec!(comando)
```
> Comandos principales usados

**Ojo** Para poder usar el directorio `~/.u` se ha utilizado `ENV['HOME'] + '/.u'`.
> `ENV['HOME']`  devuelve variable de entorno `$HOME` de cada usuario.
> Para ver las posibles variables de entorno: `env`.
