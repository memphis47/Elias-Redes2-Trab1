#-----------------------------------------------------------#
# 						server.rb
#    Script em ruby que executa o servidor no protocolo 2PC
#    Objetivo: Fazer a comunicação entre servidor e cliente
#              e salvar os dados novos que o cliente passa  
#    		   para esse servidor
#    
#    Autores: Alan Peterson Carvalho Silva
#             Rafael Rocha de Carvalho
#    Disciplina: Redes de computadores II
#    Data da ultima atualização: 05/06/2015
#-----------------------------------------------------------#

require 'socket'
require './log.rb'
require 'thread'
require 'resolv'

# Metodo para verificar se o arquivo com dado atual do servidor existe
def createFile(port)
	@log.write("Verificando se o arquivo data#{port}.txt existe")
	if !File.exists?("data#{port}.txt")
		@log.write("Arquivo data#{port}.txt nao existe, criando arquivo data.txt")
		# Caso nao exista cria um novo arquivo
		file = File.new("data#{port}.txt", File::CREAT|File::TRUNC|File::RDWR, 0644)
		@log.write("Arquivo data#{port}.txt criado com sucesso")
	end
end

# Metodo para ler o dado atual do arquivo
def readData(port)
	@log.write("Verificando se o arquivo data#{port}.txt possui dados")
	if File.zero?("data#{port}.txt")
		@log.write("Arquivo data#{port}.txt nao possui dados, escrevendo o dado: \"Dado inicial\" no arquivo")
		# Se nao houver nenhum dado escrito entao ele define o dado inicial
		writeFile("Dado Inicial",port)
	end
	# Recupera todas as linhas do arquivo
	@log.write("Recuperando o conteudo do arquivo")
	lines = IO.readlines("data#{port}.txt")
	# le o ultimo dado salvo, como o dado esta salvo no formato [%H:%M:%S] dado,
	# usa-se o split para pegar apenas o dado
	@log.write("lendo o dado atual")
	dados=lines.last.split("] ")
	@log.write("dado atual: #{dados[1]}")
	# e retorna ele para o servidor
	return dados[1]
end

# Metodo para escrever o novo dado no servidor
def writeFile(data,port)
	# Abre o arquivo em append e escreve o novo dado nele
	@log.write("Abrindo arquivo para a escrita")
	open("data#{port}.txt", 'a') do |f|
		# o dado salvo tem o formato [%H:%M:%S] dado
		@log.write("Escrevendo o dado #{data} no arquivo")
		f << Time.now.strftime("[%H:%M:%S] ") << data << "\n"
	end
end

def transferFile(client,port)
	@log.write("Recuperando o conteudo do arquivo")
	lines = IO.readlines("data#{port}.txt")
	client.print("data#{port}.txt")
	lines.each do |line|
		client.print(line)
	end
	client.print("--+EOF+--")
end

# Cria arquivo para armazenar log
@log = Log.new("Server")
@log.write("----------------------------------------------------------------------------------------")
@log.write("Inicio da execucao do servidor que mantem os dados salvos utilizando-se do protocolo 2PC")
@log.write("----------------------------------------------------------------------------------------")

# semaforo para controlar os pedidos de uso do servidor.
semaphore = Mutex.new

# puts "Digite o nome do servidor"
# name= gets.chomp

# define o nome do server usando hostname do computador.
@log.write("definindo nome do servidor atraves do Socket.gethostname")
name = Socket.gethostname
@log.write("Nome definido para o servidor: #{name}")

# puts "Digite a porta do servidor"
# port= Integer(gets.chomp)
begin

	# recebe a porta por parametro
	@log.write("Recebendo porta via parametro para o servidor #{name}")
	port = Integer(ARGV[0])
	@log.write("Porta recebida: #{port}")

	# inicia o server usando a porta passada por parametro e o hostname
	@log.write("Iniciando o servidor #{name} na porta #{port}")
	server = TCPServer.new(name,port)
	@log.write("Servidor aberto com sucesso")
	#verifica se o arquivo com o dado atual mantido pelo servidor exite
	createFile(port.to_s)
	# Recuperando Dado atual do servidor.
	@log.write("definindo dado atual do servidor")
	data=readData(port.to_s)
	@log.write("dado atual do servidor: #{data}")
	# Mostra o nome e a porta do servidor
	puts "#{name}:#{port.to_s}"

	clientNumber=0;

	loop do
		# Para cada vez que o cliente abre uma conexao com o server,
		# eh aberto uma thread para esse cliente.
		@log.write("Iniciando escuta de clientes")
		Thread.start(server.accept) do |client|
			transferFile(client)
			@log.write("Novo cliente aceito")
			# ID que o cliente recebe quando se conecta com o servidor.
			idc=clientNumber

			# Le as linhas recebidas no socket.
			@log.write("Esperando mensagem do cliente")
			while line = client.gets.chomp
				@log.write("Mensagem recebida do cliente #{idc}")
				@log.write("Mensagem recebida: #{line}")
				# Verifica que tipo de dado eh a mensagem
				@log.write("Verificando mensagem recebida")
				if(line == "change" && semaphore.try_lock)
					@log.write("A Mensagem recebida foi um \"change\" e o servidor esta livre para que cliente possa escrever")
					puts("Receive Change from client #{idc}")
					# Se for do tipo change 
					# e o semaforo permitir que o cliente escreva no servidor
					# entao o servidor responde com um OK para esse cliente
					@log.write("Enviando a mensagem OK para o cliente")
					client.print "OK"
				elsif(line == "change" && !semaphore.try_lock)
					@log.write("A Mensagem recebida foi um \"change\" e o servidor esta bloqueado para que cliente possa escrever")
					puts("Receive Change from client #{idc} but i can't change")
					# Se for do tipo change 
					# e o semaforo nao permitir que o cliente use ele
					# entao o servidor responde com um NOK para esse cliente
					@log.write("Enviando a mensagem NOK para o cliente")
					client.print "NOK"
				elsif(line == "abort")
					@log.write("A Mensagem recebida foi um \"abort\", o servidor ira abortar a operacao atual")
					puts("Receive Abort from client #{idc}")
					# Se for do tipo abort, o servidor cancela a operação
					# e responde com um OK para esse cliente
					@log.write("Mandando a mensagem OK para o cliente")
					client.print "OK"
				elsif(line == "commit")
					@log.write("A Mensagem recebida foi um \"commit\"")
					# Se for do tipo commit o responde com um OK 
					# para esse cliente
					puts("Receive commit from client #{idc}")
					@log.write("Mandando a mensagem OK para o cliente")
					client.print "OK"
				elsif(line.split(":")[0] == "data")
					# se for do tipo data, o servidor troca o dado atual pelo dado recebido
					@log.write("A Mensagem recebida foi o novo dado a ser mantido")

					puts("Receive data from client #{idc}, change data")
					puts("from "+data)
					@log.write("Trocando dado atual de #{data}")
					# divide a mensage data:dadoRecebido, em data: e dadoRecebido
					dados=line.split("data:")
					# troca o dado atual no servidor pelo dado recebido na mensagem
					data=dados[1]
					@log.write("para #{data}")
					puts("To "+data)
					# escreve no arquivo de dados o novo dado.
					@log.write("Escrevendo no arquivo o novo dado")
					writeFile(data,port.to_s)
					
					@log.write("Mandando a mensagem OK para o cliente")
					# Responde com um OK para esse cliente
					client.print "OK"
					@log.write("Liberando o servidor para novo uso")
					# libera o servidor para novo uso.
					semaphore.unlock
				end
				# espera 1 segundo entre as mensagens
				# serve para testar o protocolo 2PC
				sleep 1.0
				
			end
		end
		# Adiciona 1 ao contador de identificação do cliente.
		clientNumber+=1
	end

# Identifica uma exceção
rescue Exception => e
	if ARGV[0]==nil
		@log.write("parametro port nao foi recebido ou veio de forma incorreta","error")
		# Caso a exceção tenha sido por falta do parametro de portas
		# mostra uma mensagem para o usuario.
		print "You need to Write the port of server in parameter,like this\n"
		print "\t $ ruby server.rb 8000\n\n"
		print "Try again using the right way this time.\n\n"
	end
	
end