#!/usr/bin/ruby

require 'net/ping'
require 'net/ssh'


#####################################
#        Funciones auxiliares       #
#####################################
def p
  #ejecutar estilo ping al puerto 22 a todas las máquinas del conjunto
  puts ">>Leyendo direcciones de las maquinas"
  File.foreach(ENV['HOME'] + '/.u/hosts') do |direccion|
    direccion = direccion.chop #QUITAR SALTO DE LINEA
    check = Net::Ping::External.new(direccion, 22, 0.1)
    if check.ping?
      puts direccion + ": FUNCIONA"
    else
      puts direccion + ": falla"
    end
  end
end

def c(comando)
  #ejecutar comando remoto mediante ssh en todo el conjunto de máquinas
  puts ">>Leyendo direcciones de las maquinas"
  File.foreach(ENV['HOME'] + '/.u/hosts') do |direccion|
    direccion = direccion.chop #QUITAR SALTO DE LINEA
    # Para evitar timeouts y excepciones se hace PING antes de ssh.
    check = Net::Ping::External.new(direccion, 22, 0.1)
    if check.ping?
      Net::SSH.start(direccion, 'a757024', password: "Egdxwa") do |ssh|
        output = ssh.exec!(comando)
        puts direccion + ": exito"
        puts output
      end
    else
      puts direccion + ": falla"
    end
  end
end
#####################################
#        Funcion principal          #
#####################################

#Primero cojer las dos opciones posibles
option = ARGV[0]

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
