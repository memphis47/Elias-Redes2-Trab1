require 'socket'
require './log.rb'
require './serverClass.rb'

#Numero de servidores em que o cliente ira se conectar.
NSERVERS=1

#Metodo que controla as conexoes que o cliente faz com o server.
def connectionService(servers,open=0)
	NSERVERS.times do |i|
		if(open)
			#Se o metodo recebeu a solicitacao de abrir o server, 
			#ou seja open=1
			#Abre a conexao com todos os servidores que estao listados no vetor de servers.
			servers[i].socket=TCPSocket.open(servers[i].name,servers[i].port)
			#logger.info "Server1 has port:"+port[i]
		else
			# Se open for diferente de 1, fecha as conexões com os servers listados no vetor.
			servers[i].socket.close
		end			
	end
end

# Método para enviar uma mensagem para o vetor de servers.
def sendMsg(servers,msg)

	servers.each do |server|
		# para cada server do cliente, manda a mensagem passada como parametro
		server.socket.puts msg
	end
end

# Método que verifica se as mensagem recebidas pelo cliente
# sao aquelas que ele esperava.
def verifyAnswer(msgsServer,msg)
	i=0
	msgsServer.each do |msgServer|
		
		#logger.info "Checking reply from server"+i
		#logger.info "Reply from server"+i+"= "+msgServer
		# Para cada mensagem recebida dos servidores,
		# verifica se a mensagem do servidor eh igual a mensagem esperada
		if(msgServer!=msg)
			#logger.error "Reply receiveid is different than expected"
			#logger.error "Reply: "+msgServer
			#logger.error "Expected reply"+msg
			# Retorna falso se uma das mensagens do servidor 
			#for diferente da mensagem esperada
			return false
		end
		i+=1
	end
	#logger.error "Everything is ok with the replies from servers"
	# Retorna True, se todas as mensagem forem iguais a mensagem esperada.
	return true
end


# Metodo que espera a resposta do servidor 
# para a mensagem enviada anteriormente no metodo sendMsg
def waitFor(server,i)
	#logger.error "Waiting server"+i+" reply"
	data= server.recv(800)
	# recebe o dado do servidor e compara se ele é um dos tres tipos:
	# OK -> Caso a mensagem tenha sido aceita pelo servidor
	# NOK -> Caso a mensagem tenha sido rejeitada pelo servidor
	if(data=="OK" || data=="NOK")
		#logger.error "Reply "+data+" received from the server"+i
		# retorna a mensagem recebida pelo servidor.
		return data
	end
end

# Metodo que espera a resposta de todos os servidores.
# Utiliza o metodo waitFor para cada servidor na lista de servidores.
def received(servers)
	datas=[] # cada resposta do servidor eh adicionada na lista de dados.
	NSERVERS.times do|i| 
		# Cada dado recebido por um servidor eh retornado pelo metodo waitFor
		# e esse dado eh adicionado na lista de dados.
		datas[i]=waitFor(servers[i].socket,i)
		#logger.info "Server 1 reply: "+data[i]
		# Mostra qual foi a resposta do servidor.
		puts datas[i]
	end
	return datas # retorna essa lista para uso posterior
end

# Metodo que exibe o menu de interacao com o usuario
def menu
	puts "+=====================+"
	puts " Choose an option:"
	puts "   1- Change Data"
	puts "   0- Exit"
	puts "+=====================+"
	# O usuario tem duas opcoes, mudar os dados, ou sair do programa
	# le e retorna a opcao digitada pelo usuario
	return Integer(gets.chomp)
end

# Solicita os nomes e as portas para cada servidor
def getServersPorts
  #logger.info "Getting Port for servers"
  #Vetor de informacoes dos NSERVERS servidores
  @servers=[]
  NSERVERS.times do |i| 
    # Cada servidor eh do tipo Server que esta definido na classe serverClass.rb
    @servers[i]= Server.new
    
    # Solicita o nome do servidor
    puts "Write server name "+i.to_s
    @servers[i].name=gets.chomp

    # Solicita a porta do servidor
    puts "Write the port of server "+@servers[i].name
    @servers[i].port=Integer(gets.chomp)
    #logger.info "Connecting to server #{@servers[i].name}:#{@servers[i].port}
    if @servers[i].socket=TCPSocket.open(@servers[i].name,@servers[i].port)
      #logger.info "Connection with Server1 #{@servers[i].name}:#{@servers[i].port} completed"
    else

    end
  end
  #logger.info "Connection to servers sucessful"
end

# Executa o metodo para obter informações dos servidores
getServersPorts()

# Executa o metodo de menu enquanto a opcao selecionada nao for 0 (Exit)
while menu.to_i!=0 do
	# Caso a opção tenha sido 1, ou seja enviar dados.
	connectionService(@servers,1) # abre a conexão com os servidores
	puts "Type your new Data" # Solicita o dado que o cliente deseja enviar.
	line=gets.chomp # le o dado do cliente

	#logger.info "Send message \"Change\" to servers"
	# Envia a mensagem para o servidores que deseja alterar os dados
	sendMsg(@servers,"change")
	# Recebe a resposta dos servidores para a solicitação do change.
	datas=received(@servers)

	#logger.info "Checking if servers reply to change is OK"
	# Verifica se a reposta que recebeu é a desejada, nesse caso OK
	if(verifyAnswer(datas,"OK"))
		#logger.info "Send message \"commit\" to servers"
		# Caso seja OK, envia a solicitação de commit para os servidores.
		sendMsg(@servers,"commit")

		# Recebe a resposta dos servidores para a solicitação de commit.
		datas=received(@servers)

		#logger.info "Checking if servers reply to commit is OK"
		# Verifica se a reposta que recebeu é a desejada, nesse caso OK
		if(verifyAnswer(datas,"OK"))
			#logger.info "Sending Data "+line+" to servers"
			# Caso seja OK, envia o novo dado para os servidores.
			sendMsg(@servers,"data:"+line)

			# Recebe a resposta dos servidores para o envio do novo dado.
			datas=received(@servers)
			
			#logger.info "Checking if servers reply to data send is ACK"
			# Se a resposta for diferente de OK, manda um abort para o server
			if(!verifyAnswer(datas,"OK"))
				#logger.info "Servers reply to data send is a NACK, sending abort to servers to cancel commit"
				sendMsg(@servers,"abort")
			end
		else
			#logger.info "Servers reply to commit is a NOK,sending abort to servers to cancel commit"
			# Se a resposta for diferente de OK, manda um abort para o server
			puts("Sending Abort")
			sendMsg(@servers,"abort")
		end
	else
		#logger.info "Servers reply to commit is a NOK,sending abort to servers to cancel commit"
		# Se a resposta for diferente de OK, manda um abort para o server
		sendMsg(@servers,"abort")
	end
	# Após terminar todos os envios fecha a conexão com os servers.
	connectionService(@servers)
end
