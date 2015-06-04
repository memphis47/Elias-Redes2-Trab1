require 'socket'
require './log.rb'
require 'thread'
require 'resolv'

# semaforo para controlar os pedidos de uso do servidor.
semaphore = Mutex.new

# puts "Digite o nome do servidor"
# name= gets.chomp

# define o nome do server usando hostname do computador.
name = Socket.gethostname

# puts "Digite a porta do servidor"
# port= Integer(gets.chomp)
begin

# recebe a porta por parametro
port = Integer(ARGV[0])

# inicia o server usando a porta passada por parametro e o hostname
server = TCPServer.new(name,port)

# Dado inicial do servidor.
data="Dado1"
#$ok=true;
# Mostra o nome e a porta do servidor
puts "#{name}:#{port.to_s}"
clientNumber=0;

loop do
	# Para cada vez que o cliente abre uma conexao com o server,
	# eh aberto uma thread para esse cliente.
	Thread.start(server.accept) do |client|
		# ID que o cliente recebe quando se conecta com o servidor.
		idc=clientNumber

		# Le as linhas recebidas no socket.
		while line = client.gets.chomp

			# Verifica que tipo de dado eh a mensagem
			if(line == "change" && semaphore.try_lock)
				puts("Receive Change from client #{idc}")
				# Se for do tipo change 
				# e o semaforo permitir que o cliente escreva no servidor
				# entao o servidor responde com um OK para esse cliente
				client.print "OK"
			elsif(line == "change" && !semaphore.try_lock)
				puts("Receive Change from client #{idc} but i can't change")
				# Se for do tipo change 
				# e o semaforo nao permitir que o cliente use ele
				# entao o servidor responde com um NOK para esse cliente
				client.print "NOK"
			elsif(line == "abort")
				puts("Receive Abort from client #{idc}")
				# Se for do tipo abort, o servidor cancela a operação
				# e responde com um OK para esse cliente
				client.print "OK"
			elsif(line == "commit")
				# Se for do tipo commit o responde com um OK 
				# para esse cliente
				puts("Receive commit from client #{idc}")
				client.print "OK"
			elsif(line.split(":")[0] == "data")
				# Se for do tipo data, o servidor cancela a operação
				# e responde com um OK para esse cliente
				client.print "OK"
				puts("Receive data from client #{idc}, change data")
				puts("from "+data)
				# divide a mensage data:dadoRecebido, em data: e dadoRecebido
				dados=line.split("data:")
				# troca o dado atual no servidor pelo dado recebido na mensagem
				data=dados[1]
				puts("To "+data)
				# libera o servidor para novo uso.
				semaphore.unlock
			end
			# espera 1 segundo entre as mensagens
			# serve para testar o protocolo 2PC
			sleep 1.0
			
		end
	end
	clientNumber+=1
end


rescue Exception => e
	if ARGV[0]==nil
		print "You need to Write the port of server in parameter,like this\n"
		print "\t $ ruby server.rb 8000\n\n"
		print "Try again using the right way this time.\n\n"
	end
	
end