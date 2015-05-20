require "net/telnet"

def sendMsg(servers,msg)
	servers.each do |server|
		server.puts(msg)
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
		logger.info "Checking reply from server"+i
		logger.info "Reply from server"+i+"= "+data
		if(data!=msg && data.chomp!=msg)
			logger.error "Reply receiveid is different than expected"
			logger.error "Reply: "+data
			logger.error "Expected reply"+msg
			return false
		end
		i+=1
	end
	logger.error "Everything is ok with the replies from servers"
	return true
end

def waitFor(server,i)
	logger.error "Waiting server"+i+" reply"
	server.waitfor(/./) do |data|
		if(data=="ACK" || data=="OK" || data=="NOK")
			logger.error "Reply "+data+" received from the server"+i
			return data
		end
	end
end

fileNumber=verifyFiles()

#file= File.new('logClient'+fileNumber.to_s+'.log', 
#				"w+")
logger= Logger.new(file)
logger.datetime_format="%d-%m-%Y %H:%M:%S"
logger.formatter = proc do |severity,datetime,progname,msg|
	"[#{datetime}]#{progname}:#{severity}=>#{msg}\n"
end

logger.info "Getting Port for servers"
puts "Digite a porta do servidor 1"
port1= gets
logger.info "Server1 has port:"+port1
puts "Digite a porta do servidor 2"
port2= gets
logger.info "Server1 has port:"+port2
puts "Digite a porta do servidor 3"
port3= gets
logger.info "Server1 has port:"+port3

logger.info "Connecting to servers..."

servers=[Net::Telnet::new("Host"=>"localhost","Port" =>Integer(port1),"Telnetmode"=>false),
		Net::Telnet::new("Host"=>"localhost","Port" =>Integer(port2),"Telnetmode"=>false),
		Net::Telnet::new("Host"=>"localhost","Port" =>Integer(port3),"Telnetmode"=>false)]

logger.info "Connection to servers sucessful"


lines_to_send=['Hello!','Send a message','Bye']

lines_to_send.each do |line|

	logger.info "Send message \"Change\" to servers"
	sendMsg(servers,"change")

	data1=waitFor(servers[0],0)
	data2=waitFor(servers[1],1)
	data3=waitFor(servers[2],2)

	logger.info "Server 1 reply: "+data1
	logger.info "Server 2 reply: "+data2
	logger.info "Server 3 reply: "+data3

	datas=[data1,data2,data3]

	puts data1
	puts data2
	puts data3

	logger.info "Checking if servers reply to change is OK"
	if(verifyDatas(datas,"OK"))
		logger.info "Send message \"commit\" to servers"
		sendMsg(servers,"commit")

		data1=waitFor(servers[0],0)
		data2=waitFor(servers[1],1)
		data3=waitFor(servers[2],2)

		logger.info "Server 1 reply: "+data1
		logger.info "Server 2 reply: "+data2
		logger.info "Server 3 reply: "+data3

		datas=[data1,data2,data3]

		puts data1
		puts data2
		puts data3

		logger.info "Checking if servers reply to commit is OK"
		if(verifyDatas(datas,"OK"))
			logger.info "Sending Data "+line+" to servers"
			sendMsg(servers,"data:"+line)

			data1=waitFor(servers[0],0)
			data2=waitFor(servers[1],1)
			data3=waitFor(servers[2],2)

			logger.info "Server 1 reply: "+data1
			logger.info "Server 2 reply: "+data2
			logger.info "Server 3 reply: "+data3

			datas=[data1,data2,data3]

			puts data1
			puts data2
			puts data3
			sleep(1.0/3.0)
			logger.info "Checking if servers reply to data send is ACK"
			if(!verifyDatas(datas,"ACK"))
				logger.info "Servers reply to data send is a NACK, sending abort to servers to cancel commit"
				sendMsg(servers,"abort")
			end
		else
			logger.info "Servers reply to commit is a NOK,sending abort to servers to cancel commit"
			puts("Sending Abort")
			sendMsg(servers,"abort")
		end
	else
		logger.info "Servers reply to commit is a NOK,sending abort to servers to cancel commit"
		sendMsg(servers,"abort")
	end
end
