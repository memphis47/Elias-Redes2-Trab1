require "net/telnet"

def sendMsg(servers,msg)
	servers.each do |server|
		server.puts(msg)
	end
end

def verifyFiles()
	finding=true
	i=0;
	while finding
		if(File.exist?('logClient'+i+'.log')		
			i++
		else
			return i;
		end
	end
end

def verifyDatas(datas,msg)
	datas.each do |data|
		if(data!=msg && data.chomp!=msg)
			return false
		end
		
	end
	return true
end

def waitFor(server)
	server.waitfor(/./) do |data|
		if(data=="ACK" || data=="OK" || data=="NOK")
			return data
		end
	end
end

fileNumber=verifyFiles()

file= File.open('logClient'+fileNumber+'.log', 
				File::WRONLY | File::APPEND)
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

logger.info "Connection to servers sucessfull"


lines_to_send=['Hello!','Send a message','Bye']

lines_to_send.each do |line|


	sendMsg(servers,"change")

	data1=waitFor(servers[0])
	data2=waitFor(servers[1])
	data3=waitFor(servers[2])

	datas=[data1,data2,data3]

	puts data1
	puts data2
	puts data3

	if(verifyDatas(datas,"OK"))

		sendMsg(servers,"commit")

		data1=waitFor(servers[0])
		data2=waitFor(servers[1])
		data3=waitFor(servers[2])

		datas=[data1,data2,data3]

		puts data1
		puts data2
		puts data3

		if(verifyDatas(datas,"OK"))
			puts("Sending Data")
			sendMsg(servers,"data:"+line)

			data1=waitFor(servers[0])
			data2=waitFor(servers[1])
			data3=waitFor(servers[2])

			datas=[data1,data2,data3]

			puts data1
			puts data2
			puts data3
			sleep(1.0/3.0)
			if(verifyDatas(datas,"NACK"))
				sendMsg(servers,"abort")
			end
		else
			puts("Sending Abort")
			sendMsg(servers,"abort")
		end
	else
		sendMsg(servers,"abort")
	end
end
