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
			begin
				@log.write("Abrindo conexao com o servidor #{servers[i].name}")
				servers[i].socket=TCPSocket.open(servers[i].name,servers[i].port)
				@log.write("Conexao aberta com sucesso")
			rescue Exception => e
				@log.write("Ocorreu um erro ao abrir o servidor #{servers[i].name}","error")
				@log.write("Erro: #{e.to_s}","error")
				@log.write("Terminando a execucao do programa para evitar incosistencia de dados","error")
				exit
			end

		else
		  @log.write("Fechando a comunicacao com o servidor: #{servers[i].name}")
		  # Se open for diferente de 1, fecha as conexões com os servers listados no vetor.
		  servers[i].socket.close
		end     
	end
end

# Método para enviar uma mensagem para o vetor de servers.
def sendMsg(servers,msg)
  servers.each do |server|
    # para cada server do cliente, manda a mensagem passada como parametro
    @log.write("Enviando mensagem para o servidor #{server.name}")
    @log.write("Mensagem sendo enviada: #{msg}")
    begin
    	server.socket.puts msg
    rescue Exception => e
    	@log.write("Erro ao enviar mensagem para o servidor #{server.name}")
    	@log.write("Terminando a execucao do programa para evitar incosistencia de dados","error")
    	exit
    end    
  end
end

# Método que verifica se as mensagem recebidas pelo cliente
# sao aquelas que ele esperava.
def verifyAnswer(msgsServer,msg)
  i=0
  msgsServer.each do |msgServer|
    @log.write("Checking reply from server #{i}")
    @log.write("Reply from server #{i}: #{msgServer}")
    # Para cada mensagem recebida dos servidores,
    # verifica se a mensagem do servidor eh igual a mensagem esperada
    if(msgServer!=msg)
    	@log.write("Resposta recebida do servidor #{i} eh diferente do esperado")
    	@log.write("Resposta do servidor#{i}: #{msgServer}")
    	@log.write("Resposta esperada: #{msg}")
      # Retorna falso se uma das mensagens do servidor 
      # for diferente da mensagem esperada
    	return false
    end
    i+=1
  end
  @log.write("Respostas recebidas dos servidores estao de acordo com o esperado")
  # logger.error "Everything is ok with the replies from servers"
  # Retorna True, se todas as mensagem forem iguais a mensagem esperada.
  return true
end


# Metodo que espera a resposta do servidor 
# para a mensagem enviada anteriormente no metodo sendMsg
def waitFor(server,i)
  @log.write("Esperando pela resposta do servidor #{i}")
  data= server.recv(800)
  # recebe o dado do servidor e compara se ele é um dos dois tipos:
  # OK -> Caso a mensagem tenha sido aceita pelo servidor
  # NOK -> Caso a mensagem tenha sido rejeitada pelo servidor
  if(data=="OK" || data=="NOK")
   	@log.write("Resposta recebida do servidor #{i}: #{data}")
    #logger.error "Reply "+data+" received from the server"+i
    # retorna a mensagem recebida pelo servidor.
    return data
  end
  @log.write("Resposta recebida do servidor #{i} nao esta no padrao esperado")
end

# Metodo que espera a resposta de todos os servidores.
# Utiliza o metodo waitFor para cada servidor na lista de servidores.
def received(servers)
  datas=[] # cada resposta do servidor eh adicionada na lista de dados.
  NSERVERS.times do|i|
    # Cada dado recebido por um servidor eh retornado pelo metodo waitFor
    # e esse dado eh adicionado na lista de dados.
    datas[i]=waitFor(servers[i].socket,i)
    # Mostra qual foi a resposta do servidor.
    puts datas[i]
  end
  return datas # retorna essa lista para uso posterior
end

# Metodo que mostra o historico do servidor
def showData(i)
	system "clear"
	# Mostra o historico de dados desse servidor
	@log.write("Recuperando o conteudo do arquivo")
	lines = IO.readlines("#{@servers[i].name}#{@servers[i].port}Data.txt")
	@log.write("Escrevendo dados na tela")
	lines.each do |line|
		# Escreve cada dado do servidor
		@log.write("Escrevendo dado #{line} para o cliente")
		puts (line)
	end
	# Espera ate o cliente apertar o enter.
	@log.write("Esperando o cliente pressionar a tecla enter ...")
	puts "Press \"enter\" to back"
	gets.chomp
end

# Metodo que mostra os servidores conectados, e que permite ao usuario escolher
# qual deles ele deseja ver o historico
def showMenuServer
	# Lista para verificar se a opcao digitada pelo usuario eh valida
	validOptions = []
	validOptions << 0
	loop do
		# Limpa a tela do usuario.
		system "clear"
		i=1
		# Lista os servidores e espera a opcao desejada do cliente
		@log.write("Esperando cliente informar opcao desejada")
	    puts "What server do you want to see data history ? If you want back press 0"
	    @servers.each do |server|
	    	@log.write("Servidores disponiveis => #{server.name}:#{server.port}")
	  		puts "#{i}- servidor #{server.name}:#{server.port}"
	  		# salva esse servidor como uma opção
	  		validOptions << i
	  		i+=1
	  	end
	  	begin
	      option = Integer(gets.chomp)
	      @log.write("Opcao digitada pelo cliente: #{option.to_s}")
	    rescue
	      # Caso o cliente algo nao numerico
	      @log.write("O cliente digitou uma opcao nao numerica!","error")
	      puts "Please type only the number!"
	    else
	      unless validOptions.include?(option)
	        # Caso digite uma opcao invalida, informa o erro, e pede para digitar novamente
	        @log.write("O cliente digitou uma opcao invalida!","error")
	        puts "Invalid option"
	      else
	        # le e retorna a opcao digitada pelo usuario
	        @log.write("O cliente escolheu a opcao #{option}")
	        if(option>0)
	        	# Mostra o historico de dados desse servidor
	        	showData(option-1)
	        else
	        	@log.write("Voltando ao menu inicial")
	        	return
	        end
	      end
		end
	end
end

# Metodo que exibe o menu de interacao com o usuario
def menu
  system "clear"
  @dadosAtuais=receiveDatasFiles(@servers)
  validOptions = [0,1,2]
  loop do 
  	@log.write("Escrevendo os dados Atuais")
  	i=0
  	# Lista o dado atual de cada servidor
  	@servers.each do |server|
  		@log.write("Dado atual do servidor #{server.name}:#{server.port} => #{@dadosAtuais[i]}")
  		puts "Dado atual do servidor #{server.name}:#{server.port} => #{@dadosAtuais[i]}"
  		i+=1
  	end
    @log.write("Esperando cliente informar opcao desejada")
    puts "+============================+"
    puts " Choose an option:"
    puts "   1- Change Data"
    puts "   2- List data from servers"
    puts "   0- Exit"
    puts "+============================+"
    # O usuario tem tres opcoes, mudar os dados, listar os dados de algum server, ou sair do programa
    begin
      option = Integer(gets.chomp)
    rescue
      # Caso o cliente algo nao numerico
      @log.write("O cliente digitou uma opcao nao numerica!","error")
      puts "Please type only the number!"
    else
      unless validOptions.include?(option)
        # Caso digite uma opcao invalida, informa o erro, e pede para digitar novamente
        @log.write("O cliente digitou uma opcao invalida!","error")
        puts "Invalid option"
      else
        # le e retorna a opcao digitada pelo usuario
        @log.write("O cliente escolheu a opcao #{option}")
        return option
      end
    end
  end
end

# Solicita os nomes e as portas para cada servidor
def getServersPorts
  @log.write("Getting Names and Ports for servers")
  #Vetor de informacoes dos NSERVERS servidores
  @servers=[]
  NSERVERS.times do |i| 
    # Cada servidor eh do tipo Server que esta definido na classe serverClass.rb
    @servers[i]= Server.new
    
    # Solicita o nome do servidor
    @log.write("Solictando para o cliente o nome do servidor")
    puts "Write server name "+i.to_s
    @servers[i].name=gets.chomp
    @log.write("Nome recebido: #{@servers[i].name}")
    # Caso o cliente digite letras no lugar do numero da porta, trata a excecao
    loop do
      # Solicita a porta do servidor
      @log.write("Solictando para o cliente a porta do servidor #{@servers[i].name}")
      puts "Write the port of server "+@servers[i].name
      begin
        @servers[i].port=Integer(gets.chomp)
         @log.write("porta recebida: #{@servers[i].port}")
      rescue
        # Se o cliente digitar algo nao numerico, pede para digitar novamente
        @log.write("A porta recebida #{@servers[i].port} eh uma porta invalida, essa porta deve ser um numeral","error")
        puts "Please insert only numbers"
      else
        # Caso ele digite o numero correto, tenta estabelecer conexao
        @log.write("Connecting to server #{@servers[i].name}:#{@servers[i].port}")
        begin
          @servers[i].socket=TCPSocket.open(@servers[i].name,@servers[i].port)
        rescue Exception => e
          # Se a conexao for recusada, sair do programa
          puts "Connection with #{@servers[i].name}:#{@servers[i].port} refused! Exiting the program..."
          @log.write("Connection with Server #{@servers[i].name}:#{@servers[i].port} refused! Exiting the program...")
          exit
        else
          # Caso a conexao seja aceita, continua
          @log.write("Connection with Server #{@servers[i].name}:#{@servers[i].port} completed")
        end
        break
      end
    end
  end
  @log.write("Connection to servers sucessful")
end

# Metodo para escrever em um arquivo local no cliente os dados atuais do servidor
def writeLinesInFile(server,lines)
	@log.write("Verificando se o arquivo #{server.name}#{server.port}Data.txt existe")
	if !File.exists?("#{server.name}#{server.port}Data.txt")
		@log.write("Arquivo #{server.name}#{server.port}Data.txt nao existe, criando arquivo data.txt")
		# Caso nao exista cria um novo arquivo
		file = File.new("#{server.name}#{server.port}Data.txt", File::CREAT|File::TRUNC|File::RDWR, 0644)
		@log.write("Arquivo #{server.name}#{server.port}Data.txt criado com sucesso")
	end
	open("#{server.name}#{server.port}Data.txt", 'w') do |f|
		# o dado salvo tem o formato [%H:%M:%S] dado
		lines.each do |data|
			@log.write("Escrevendo o dado #{data} no arquivo")
			f << data << "\n"
		end
	end
end

# Metodo para que recebe do servidor as linhas do arquivo de dados
def readLines(server)
	lines=[]
	# lista que contem as linhas recebidas pelo cliente
	@log.write("Esperando pela resposta do servidor #{server.name}")
	while (data= server.socket.recv(800).chomp)
		# Verifica se a mensagem recebida eh EOF ou um dado
		@log.write("Mensagem recebida #{data}")
		if(data!="--+EOF+--")
			# se for um dado salava na lista
			lines << data
			@log.write("Enviando OK para o servidor")
			# e manda um ok para o servidor
			server.socket.print "OK"
			@log.write("OK enviado para o servidor")
			
		else
			@log.write("Enviando OK para o servidor")
			# Se for um EOF manda um ok para o servidor
			server.socket.print "OK"
			@log.write("OK enviado para o servidor")
			break
		end
	end
	@log.write("Mensagem EOF Recebida")
	# Salva em um arquivo as linhas recebidas com o historioco atual do servidor
	writeLinesInFile(server,lines)
	@log.write("Retornando dado atual: #{lines.last}")
	# Retorna o dado mais atual do servidor
	return lines.last
end

# Metodo para receber o arquivo com o dado atual e o historico dos dados do servidor
def receiveDatasFiles(servers)
	@log.write("Recebendo dados atuais do servidor")
	dadosAtuais=[]
	servers.each do |server|
		@log.write("Enviando refresh para o servidor #{server.name}")
		server.socket.puts "refresh"
		dadosAtuais << readLines(server)
	end
	return dadosAtuais
end

# Cria arquivo para armazenar log
@log = Log.new("Client")

@log.write("----------------------------------------------------------------------------------------")
@log.write("Inicio da execucao do cliente que se comunica com #{NSERVERS} utilizando o protocolo 2PC")
@log.write("----------------------------------------------------------------------------------------")

# Executa o metodo para obter informações dos servidores
getServersPorts()
@dadosAtuais=receiveDatasFiles(@servers)
# Executa o metodo de menu enquanto a opcao selecionada nao for 0 (Exit)
while (opc=menu.to_i)!=0 do
  	# Caso a opção tenha sido 1, ou seja enviar dados.
  	if(opc==1)
  	  system "clear"
	  connectionService(@servers,1) # abre a conexão com os servidores
	  puts "Type your new Data" # Solicita o dado que o cliente deseja enviar.
	  line=gets.chomp # le o dado do cliente
	  #recupera os dados atuais do servidor.
	  @dadosAtuais=receiveDatasFiles(@servers)

	  @log.write("Send message \"Change\" to servers")
	  # Envia a mensagem para o servidores que deseja alterar os dados
	  sendMsg(@servers,"change")
	  # Recebe a resposta dos servidores para a solicitação do change.
	  datas=received(@servers)

	  @log.write("Checking if servers reply to change is OK")
	  # Verifica se a reposta que recebeu é a desejada, nesse caso OK
	  if(verifyAnswer(datas,"OK"))
	    @log.write("Send message \"commit\" to servers")
	    # Caso seja OK, envia a solicitação de commit para os servidores.
	    sendMsg(@servers,"commit")

	    # Recebe a resposta dos servidores para a solicitação de commit.
	    datas=received(@servers)

	    @log.write("Checking if servers reply to commit is OK")
	    # Verifica se a reposta que recebeu é a desejada, nesse caso OK
	    if(verifyAnswer(datas,"OK"))
	      @log.write("Sending Data "+line+" to servers")
	      # Caso seja OK, envia o novo dado para os servidores.
	      sendMsg(@servers,"data:"+line)

	      # Recebe a resposta dos servidores para o envio do novo dado.
	      datas=received(@servers)
	      
	      @log.write("Checking if servers reply to data send is ACK")
	      # Se a resposta for diferente de OK, manda um abort para o server
	      if(!verifyAnswer(datas,"OK"))
	        @log.write("Servers reply to data send is a NOK, sending abort to servers to cancel commit")
	        sendMsg(@servers,"abort")
	      end
	    else
	      @log.write("Servers reply to commit is a NOK,sending abort to servers to cancel commit")
	      # Se a resposta for diferente de OK, manda um abort para o server
	      puts("Sending Abort")
	      sendMsg(@servers,"abort")
	    end
	  else
	    @log.write("Servers reply to commit is a NOK,sending abort to servers to cancel commit")
	    # Se a resposta for diferente de OK, manda um abort para o server
	    sendMsg(@servers,"abort")
	  end
	  # Após terminar todos os envios fecha a conexão com os servers.
	  connectionService(@servers)
	  @dadosAtuais=receiveDatasFiles(@servers)
	else
		system "clear"
		showMenuServer()
	end

end
@log.write("Encerrando programa")