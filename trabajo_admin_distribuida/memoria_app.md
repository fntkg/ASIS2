# Aplicación administración distribuida

Como usar:

Los ficheros de configuración se encuentran en `~/.u`
> El conjunto de maquinas se especifica en `~/.u/hosts`

Hacer ping al puerto `22` de un conjunto de maquinas:
`./u.rb p`
 
Ejecutar comandos en un conjunto de maquinas de manera remota:
`./u.rb s COMANDO`

Cualquier otro comando o no poner algo en `COMANDO` aparecerá un **error**
