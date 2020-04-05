#!/usr/bin/ruby

# Para los ordenadores del laboratorio:
## #!/usr/bin/env ruby
## chmod a+x u.rb

require 'net/ping'
require 'net/ssh'

#####################################
#        Funciones auxiliares       #
#####################################

def ping(direccion)
  check = Net::Ping::External.new(direccion, 22, 0.1)
  if check.ping?
    puts direccion + ": FUNCIONA"
  else
    puts direccion + ": falla"
  end
end

def ssh(direccion, command)
  # Para evitar timeouts y excepciones se hace PING antes de ssh.
  check = Net::Ping::External.new(direccion, 22, 0.1)
  if check.ping?
    Net::SSH.start(direccion, 'a757024', password: "Egdxwa") do |ssh|
      output = ssh.exec!(command)
      puts direccion + ": exito"
      puts output
      puts
    end
  else
    puts direccion + ": falla"
    puts
  end
end

# @who = a quien mandar el comando @comando
def who(who, comando, command)
  if who == "all"
    # Recorrer todas las maquinas
    File.foreach(ENV['HOME'] + '/.u/hosts') do |direccion|
      direccion = direccion.chop #QUITAR SALTO DE LINEA
      # Pasar a siguiente iteracion si es linea en blanco o nombre de grupo.
      next if direccion.match(/^-.*$/m) || direccion.match(/^$/m) || direccion.match(/^\+.*$/m)
      if comando == "p"
        ping(direccion)
      elsif comando == "s"
        ssh(direccion, command)
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
                ping(direccion)
              elsif comando == "s"
                ssh(direccion, command)
              end
            end
            # Si hay llamadas a otros grupos
          end
        end
      end
    else
      # Caso de que sea una máquina en concreto
      if (comando == "p")
        ping(who)
      elsif comando == "s"
        ssh(who, command)
      end
    end
  end
end


# COMANDO P
def p(maquinas)
  who(maquinas, "p", "")
end

def s(maquinas, comando)
  #ejecutar comando remoto mediante ssh en todo el conjunto de máquinas
  who(maquinas, "s", comando)
end

#####################################
#        Funcion principal          #
#####################################

#Primero cojer las opciones posibles
option = ARGV[0]

if option == "s" || option == "p"
  # Comando para todas las maquinas.
  if option == "p"
    # Comando p
    p("all")
  elsif option == "s"
    # Comando case
    # Tomar el comando a realizar mediante ssh del 2º parametro
    s("all", ARGV[1])
  end
else
  # Comando para un GRUPO o una maquina en concreto
  option_1 = ARGV[1]
  if option_1 == "p"
    p(option)
  elsif option_1 == "s"
    s(option, ARGV[2])
  end
end

=begin
if option != "p" && option != "s"
  #Comandos no validos
  puts "Opcion no valida."
  puts "Uso: ./u.rb [p|c SHELL_COMMAND]"
elsif option == "s" && ARGV.length != 2
  # Comando "c" pero sin SHELL_COMMAND
    puts "Argument missing"
    puts "Uso: ./u.rb c SHELL_COMMAND"
else
  #Caso que todo esta bien
  if File.exists?(ENV['HOME'] + '/.u/hosts')
    if option == "p"
      p
    else
      comando = ARGV[1]
      c comando
    end
  else
    puts "Archivo ~/.u/hosts no encontrado"
  end
end
=end
