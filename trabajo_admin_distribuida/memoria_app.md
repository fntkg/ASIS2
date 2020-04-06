# Aplicación administración distribuida

Como usar:

Los ficheros de configuración se encuentran en `~/.u`

El conjunto de maquinas se especifica en `~/.u/hosts`

Los manifiestos disponibles se encuentran en `~/.u/manifiestos/`

Estado actual de directorios:

    ~/.u
    ├── hosts
    └── manifiestos
        ├── dns_cliente.pp
        ├── ntp_cliente.pp
        └── resolv.conf.erb

> Para poder usar el directorio `~/.u` se ha utilizado `ENV['HOME'] + '/.u'`.
> `ENV['HOME']`  devuelve variable de entorno `$HOME` de cada usuario.
> Para ver las posibles variables de entorno, ejecutar en el terminal: `env`.

## Uso

Sintaxis general: 
    `./u [maquina_o_grupo_de_maquinas] subcomando_de_u [parametro de subcomando]`
    
- El `conjunto de maquinas` debe estar especificado en `~/.u/hosts` con el siguiente formato:

    Un nuevo grupo se define con el caracter `-` y la secuencia de direcciones `IP` o `DNS` que se deseen.
    Se pueden incluir grupos definidos anteriormente con el cáracter `+`.
    
    ```
    -clientes_dns
    2001:470:736b:7ff::2
    2001:470:736b:7fe::6
    
    -clientes_ntp
    2001:470:736b:7ff::1
    
    -servidores_dns
    +clientes_dns
    cps.central.unizar.es
    ```
    
    - En caso de no poner nada, el comando se ejecutará en todas las máquinas del fichero `~/.u/hosts`.

**Ping al puerto 22** -> `./u [maquina|conjunto de maquinas] p`

**Mandar comando mediante ssh** -> `./u [maquina|conjunto de maquinas] s comando`

- `comando` es la instrucción que se desea mandar a las máquinas.

**Aplicar un manifiesto puppet** -> `./u [maquina|conjunto de maquinas] c manifiesto`

- `manifiesto` debe existir en `~/.u/manifiestos/`

## Funcionamiento general de la aplicación

Esquema de la aplicación:
- Función principal
    - Se encarga de leer los parametros de la llamada al programa y llamar a las funciones correspondientes (`p(maquinas)`,`s(maquinas, comando)`,`c(maquinas, manifiesto)`)

- Funciones `p(maquinas)`,`s(maquinas, comando)`,`c(maquinas, manifiesto)`:
    - Su función es llamar a la función `who(who, comando, command)`.
    
- Función `who(who, comando, command`:
    - Recorre el archivo `~/.u/hosts` y usa las máquinas que se le indican en los parametros del programa. Para cada máquina objetivo, llama a la función necesaria (`ping(direccion)`,`ssh(direccion, command)`,`aplicar_manifiesto(direccion, manifiesto)`)
    
- El resto de funciones se encargan de ejecutar la orden adecuada para cada máquina.

Para el comando `p` se ha usado la biblioteca `net/ping`.
```ruby
Net::Ping::External.new(host, port, timeout)
```
> Comandos principales usados

Para el comando `s COMANDO` se ha usado la biblioteca `net/ssh` y se ha **reutilizado**  `net/ping` para comprobar si una maquina esta viva o no y evitar así errores de ssh.
```ruby
Net::SSH.start(host, 'username', password: "password")
ssh.exec!(comando)
```
> Comandos principales usados


Para el comando `c MANIFIESTO` se ha usado la biblioteca `net/scp` y se ha dado uso de la función creada para mandar comandos vía `ssh`.

`SCP` se ha usado para poder copiar el manifiesto de puppet en las máquinas remotas.
```ruby
Net::SCP.upload!(direccion, "a757024",
          "#{ENV['HOME']}/.u/manifiestos/#{manifiesto}", "/home/a757024",
            :ssh => { :password => "Egdxwa" })
```

> Comandos principales usados
