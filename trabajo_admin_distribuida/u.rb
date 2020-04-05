#!/usr/bin/ruby

# Para los ordenadores del laboratorio:
## #!/usr/bin/env ruby
## chmod a+x u.rb

require 'net/ping'
require 'net/ssh'
require 'net/scp'

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


def aplicar_manifiesto(direccion, manifiesto)
  puts ">> Aplicar manifiesto ##{manifiesto} en #{direccion}"
  puts
  # Copiar archivo #[manifiesto] en maquina remota
  output = ""
  check = Net::Ping::External.new(direccion, 22, 0.1)
  if check.ping?
    # Comprobar que no existe ya el fichero
    Net::SSH.start(direccion, 'a757024', password: "Egdxwa") do |ssh|
      output = ssh.exec!("ls | grep #{manifiesto}")
    end
    if output == ""
      # Si aun no se ha creado el manifiesto, crearlo
      Net::SCP.upload!(direccion, "a757024",
          "#{ENV['HOME']}/.u/manifiestos/#{manifiesto}", "/home/a757024",
            :ssh => { :password => "Egdxwa" })
    end
  else
    puts direccion + ": falla"
    puts
  end
end

def check_manifiesto(direccion, manifiesto)
  ssh(direccion, "rm /home/a757024/#{manifiesto}")
end


# @who = a quien mandar el comando @comando
# @comando = puede ser "p", "s" o "c"
# @command = comando pasado cuando @comando es "s" O manifiesto cuando @comando es "c"
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
      elsif comando == "c"
        aplicar_manifiesto(direccion, command)
      elsif comando == "c_clean"
        check_manifiesto(direccion, command)
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
              elsif comando == "c"
                aplicar_manifiesto(direccion, command)
              elsif comando == "c_clean"
                check_manifiesto(direccion, command)
              end
            end
            # Si hay llamadas a otros grupos
          end
        end
      end
    else
      # Caso de que sea una máquina en concreto
      if comando == "p"
        ping(who)
      elsif comando == "s"
        ssh(who, command)
      elsif comando == "c"
        aplicar_manifiesto(who, command)
      elsif comando == "c_clean"
        check_manifiesto(who, command)
      end
    end
  end
end


# COMANDO P
def p(maquinas)
  who(maquinas, "p", "")
end

# COMANDO S
def s(maquinas, comando)
  #ejecutar comando remoto mediante ssh en todo el conjunto de máquinas
  who(maquinas, "s", comando)
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
    p("all")
  elsif option == "s"
    # Comando s
    # Tomar el comando a realizar mediante ssh del 2º parametro
    s("all", ARGV[1])
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
