require 'socket'
require './log.rb'

NSERVERS=1

def sendMsg(servers,msg)
	servers.each do |server|
		server.puts msg
	end
end

def verifyFiles()
	finding=true
	i=0
	puts "To aqui"
	while finding do
		if(File.exist?("logClient"+i.to_s+".log"))	
			i+=1
		else
			return i
		end
	end
	puts "To aqui1"
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
	print data
	if(data=="ACK" || data=="OK" || data=="NOK")
		#logger.error "Reply "+data+" received from the server"+i
		return data
	end
end

def received(servers)
	datas=[]
	NSERVERS.times do|i| 
		datas[i]=waitFor(servers[i],i)
		#logger.info "Server 1 reply: "+data[i]
		puts datas[i]
	end
	return datas
end

fileNumber=verifyFiles()

ports=[]
servers=[]
#logger.info "Getting Port for servers"
NSERVERS.times do |i| 
	puts "Digite a porta do servidor "+i.to_s
	ports[i]= gets.chomp
	#logger.info "Connecting to server"+"127.0.0.1"
	servers[i]=TCPSocket.open("127.0.0.1",Integer(ports[i]))
	#logger.info "Server1 has port:"+port[i]
end
#logger.info "Connection to servers sucessful"


lines_to_send=['Hello!','Send a message','Bye']

lines_to_send.each do |line|

	#logger.info "Send message \"Change\" to servers"
	sendMsg(servers,"change")

	datas=received(servers)

	#logger.info "Checking if servers reply to change is OK"
	if(verifyDatas(datas,"OK"))
		#logger.info "Send message \"commit\" to servers"
		sendMsg(servers,"commit")

		datas=received(servers)

		#logger.info "Checking if servers reply to commit is OK"
		if(verifyDatas(datas,"OK"))
			#logger.info "Sending Data "+line+" to servers"
			sendMsg(servers,"data:"+line)
			datas=received(servers)
			
			#logger.info "Checking if servers reply to data send is ACK"
			if(!verifyDatas(datas,"OK"))
				#logger.info "Servers reply to data send is a NACK, sending abort to servers to cancel commit"
				sendMsg(servers,"abort")
			end
		else
			#logger.info "Servers reply to commit is a NOK,sending abort to servers to cancel commit"
			puts("Sending Abort")
			sendMsg(servers,"abort")
		end
	else
		#logger.info "Servers reply to commit is a NOK,sending abort to servers to cancel commit"
		sendMsg(servers,"abort")
	end
end
