#!/usr/bin/env ruby
## chmod a+x u.rb

## Para ejecutar desde mi ordenador
## !/usr/bin/ruby

require 'net/ping'
require 'net/ssh'
require 'net/scp'

#####################################
#        Funciones auxiliares       #
#####################################

def ping(direccion)
  result = ""
  check = Net::Ping::External.new(direccion, 22, 0.1).ping6
  if check
    result = direccion + ": FUNCIONA\n"
  else
    result =  direccion + ": falla\n"
  end
  return result
end

def ssh(direccion, command)
  result = ""
  # Para evitar timeouts y excepciones se hace PING antes de ssh.
  check = Net::Ping::External.new(direccion, 22, 0.1).ping6
  if check
    Net::SSH.start(direccion, 'a757024', password: "Egdxwa") do |ssh|
      # Enviar comando @command
      output = ssh.exec!(command)
      result = direccion + ": exito\n"  + output
    end
  else
    result = direccion + ": falla\n"
  end
  return result
end


def aplicar_manifiesto(direccion, manifiesto)
  puts ">> Aplicar manifiesto ##{manifiesto} en #{direccion}"
  puts
  # Copiar archivo #[manifiesto] en maquina remota
  output = ""
  check = Net::Ping::External.new(direccion, 22, 0.1).ping6
  if check
    # Comprobar que no existe ya el fichero
    Net::SSH.start(direccion, 'a757024', password: "Egdxwa") do |ssh|
      output = ssh.exec!("ls | grep #{manifiesto}")
    end
    if output == ""
      # Si aun no se ha creado el manifiesto, crearlo
      Net::SCP.upload!(direccion, "a757024",
          "#{ENV['HOME']}/.u/manifiestos/#{manifiesto}", "/home/a757024",
            :ssh => { :password => "Egdxwa" })
            # Copiar PLANTILLA resolv.conf si el MANIFIESTO ES "DNS_CLIENTE.PP"
            if manifiesto == "dns_cliente.pp"
              Net::SCP.upload!(direccion, "a757024",
                "#{ENV['HOME']}/.u/manifiestos/resolv.conf.erb", "/home/a757024",
                  :ssh => { :password => "Egdxwa" })
            end
            # Aplicar manifiesto
            # OJO, MAQUINAS OPENBSD O UBUNTU
            puts "MAQUINA A CAGAR: #{manifiesto[-1,1]}"
            if (manifiesto.slice(-1,1) == "5" || manifiesto.slice(-1,1) == "6")
              puts ssh(direccion, "sudo puppet apply #{manifiesto}")
            else
              puts ssh(direccion, "doas puppet apply #{manifiesto}") # Mandar por ssh el comando.
            end
    end
  else
    puts direccion + ": falla"
    puts
  end
end

def rm_temp_manifiesto(direccion, manifiesto)
  ssh(direccion, "rm /home/a757024/#{manifiesto}")
  ssh(direccion, "rm /home/a757024/resolv.conf.erb")
end

#####################################
#   Funcion recorrer ~/.u/hosts     #
#####################################

# @who = a quien mandar el comando @comando
# @comando = puede ser "p", "s" o "c"
# @command6 = comando pasado cuando @comando es "s" O manifiesto cuando @comando es "c"
def who(who, comando, command)
  result = ""
  if who == "all"
    # Recorrer todas las maquinas
    File.foreach(ENV['HOME'] + '/.u/hosts') do |direccion|
      direccion = direccion.chop #QUITAR SALTO DE LINEA
      # Pasar a siguiente iteracion si es linea en blanco o nombre de grupo.
      next if direccion.match(/^-.*$/m) || direccion.match(/^$/m) || direccion.match(/^\+.*$/m)
      if comando == "p"
        result = result + ping(direccion)
      elsif comando == "s"
        result = result + ssh(direccion, command)
      elsif comando == "c"
        aplicar_manifiesto(direccion, command)
      elsif comando == "c_clean"
        rm_temp_manifiesto(direccion, command)
      end
    end
  else
    # Hay que recorrer un grupo o una maquina en concreto
    if (File.read(ENV['HOME'] + '/.u/hosts').include?("-"+who))
      # Caso de que exista un grupo con ese nombre.
      leer = false
      File.foreach(ENV['HOME'] + '/.u/hosts') do |direccion|
        direccion = direccion.chop #QUITAR SALTO DE LINEA
        if direccion == "-"+who
          # Si la linea es el nombre del grupo
          # Indicar que las siguientes direcciones son las que hay que leer
          leer = true;
        else
          break if leer && direccion == ""
          if leer
            # Si estamos en una maquina del grupo
            if direccion.match(/^\+.*$/m)
              # Si hay llamadas a otros grupos
              who(direccion.sub(/^\+/, ""), comando, command)
            else
              if (comando == "p")
                result  = result + ping(direccion)
              elsif comando == "s"
                result = result + ssh(direccion, command)
              elsif comando == "c"
                aplicar_manifiesto(direccion, command)
              elsif comando == "c_clean"
                rm_temp_manifiesto(direccion, command)
              end
            end
            # Si hay llamadas a otros grupos
          end
        end
      end
    else
      # Caso de que sea una máquina en concreto
      if comando == "p"
        result = result + ping(who)
      elsif comando == "s"
        result = result + ssh(who, command)
      elsif comando == "c"
        aplicar_manifiesto(who, command)
      elsif comando == "c_clean"
        rm_temp_manifiesto(who, command)
      end
    end
  end
  return result
end

#####################################
#   Funciones COMANDOS principales  #
#####################################

# COMANDO P
def p(maquinas)
  return who(maquinas, "p", "")
end

# COMANDO S
def s(maquinas, comando)
  #ejecutar comando remoto mediante ssh en todo el conjunto de máquinas
  return who(maquinas, "s", comando)
end

# COMANDO C
def c(maquinas, manifiesto)
  puts "> Creando arhivos temporales..."
  who(maquinas, "c", manifiesto)
  puts "> Borrando archivos temporales..."
  who(maquinas, "c_clean", manifiesto)
end

#####################################
#        Funcion principal          #
#####################################

#Primero cojer las opciones posibles
option = ARGV[0]

if option == "s" || option == "p" || option == "c"
  # Comando para todas las maquinas.
  if option == "p"
    # Comando p
    puts p("all")
  elsif option == "s"
    # Comando s
    # Tomar el comando a realizar mediante ssh del 2º parametro
    puts s("all", ARGV[1])
  else
    # Comando c
    c("all", ARGV[1])
  end
else
  # Comando para un GRUPO o una maquina en concreto
  option_1 = ARGV[1]
  if option_1 == "p"
    p(option)
  elsif option_1 == "s"
    s(option, ARGV[2])
  elsif option_1 == "c"
    c(option, ARGV[2])
  end
end
