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
			# Se open for diferente de 1
			servers[i].socket.close
		end			
	end
end

def sendMsg(servers,msg)
	servers.each do |server|
		server.socket.puts msg
	end
end

def verifyDatas(datas,msg)
	i=0
	datas.each do |data|
		#logger.info "Checking reply from server"+i
		#logger.info "Reply from server"+i+"= "+data
		if(data!=msg)
			#logger.error "Reply receiveid is different than expected"
			#logger.error "Reply: "+data
			#logger.error "Expected reply"+msg
			return false
		end
		i+=1
	end
	#logger.error "Everything is ok with the replies from servers"
	return true
end

def waitFor(server,i)
	#logger.error "Waiting server"+i+" reply"
	data= server.recv(800)
	if(data=="ACK" || data=="OK" || data=="NOK")
		#logger.error "Reply "+data+" received from the server"+i
		return data
	end
end

def received(servers)
	datas=[]
	NSERVERS.times do|i| 
		datas[i]=waitFor(servers[i].socket,i)
		#logger.info "Server 1 reply: "+data[i]
		puts datas[i]
	end
	return datas
end

def menu
	puts "+=====================+"
	puts " Choose an option:"
	puts "   1- Change Data"
	puts "   0- Exit"
	puts "+=====================+"
	return Integer(gets.chomp)
end


servers=[]

#logger.info "Getting Port for servers"

# Solicita o nome e a porta do servidor
NSERVERS.times do |i| 
	servers[i]= Server.new
	puts "Write server name "+i.to_s
	servers[i].name=gets.chomp

	puts "Write the port of server "+servers[i].name
	servers[i].port=Integer(gets.chomp)
	#logger.info "Connecting to server"+"127.0.0.1"
	servers[i].socket=TCPSocket.open(servers[i].name,servers[i].port)
	#logger.info "Server1 has port:"+port[i]
end
#logger.info "Connection to servers sucessful"


# Solicita que o cliente informe a ação que 
# deseja através das opçoes do menu.
while menu.to_i!=0 do
	# Caso a opção tenha sido 1, ou seja enviar dados.
	connectionService(servers,1) # abre a conexão com os servidores
	puts "Type your new Data" # Solicita o dado que o cliente deseja enviar.
	line=gets.chomp # le o dado do cliente

	#logger.info "Send message \"Change\" to servers"
	# Envia a mensagem para o servidores que deseja alterar os dados
	sendMsg(servers,"change")
	# Recebe a resposta dos servidores para a solicitação do change.
	datas=received(servers)

	#logger.info "Checking if servers reply to change is OK"
	# Verifica se a reposta que recebeu é a desejada, nesse caso OK
	if(verifyDatas(datas,"OK"))
		#logger.info "Send message \"commit\" to servers"
		# Caso seja OK, envia a solicitação de commit para os servidores.
		sendMsg(servers,"commit")

		# Recebe a resposta dos servidores para a solicitação de commit.
		datas=received(servers)

		#logger.info "Checking if servers reply to commit is OK"
		# Verifica se a reposta que recebeu é a desejada, nesse caso OK
		if(verifyDatas(datas,"OK"))
			#logger.info "Sending Data "+line+" to servers"
			# Caso seja OK, envia o novo dado para os servidores.
			sendMsg(servers,"data:"+line)

			# Recebe a resposta dos servidores para o envio do novo dado.
			datas=received(servers)
			
			#logger.info "Checking if servers reply to data send is ACK"
			# Se a resposta for diferente de OK, manda um abort para o server
			if(!verifyDatas(datas,"OK"))
				#logger.info "Servers reply to data send is a NACK, sending abort to servers to cancel commit"
				sendMsg(servers,"abort")
			end
		else
			#logger.info "Servers reply to commit is a NOK,sending abort to servers to cancel commit"
			# Se a resposta for diferente de OK, manda um abort para o server
			puts("Sending Abort")
			sendMsg(servers,"abort")
		end
	else
		#logger.info "Servers reply to commit is a NOK,sending abort to servers to cancel commit"
		# Se a resposta for diferente de OK, manda um abort para o server
		sendMsg(servers,"abort")
	end
	# Após terminar todos os envios fecha a conexão com os servers.
	connectionService(servers)
end
