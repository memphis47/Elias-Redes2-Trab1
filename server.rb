require 'socket'
require './log.rb'
require 'thread'
require 'resolv'

semaphore = Mutex.new

# puts "Digite o nome do servidor"
# name= gets.chomp

name = Socket.gethostname

# puts "Digite a porta do servidor"
# port= Integer(gets.chomp)
begin
	
port = Integer(ARGV[0])
server = TCPServer.new(name,port)

data="Dado1"
#$ok=true;
puts "#{name}:#{port.to_s}"
clientNumber=0;

loop do
	Thread.start(server.accept) do |client|
		idc=clientNumber
		while line = client.gets.chomp  # Read lines from the socket
			if(line == "change" && semaphore.try_lock)
				puts("Receive Change from client #{idc}")

				client.print "OK"
			elsif(line == "change" && !semaphore.try_lock)
				puts("Receive Change from client #{idc} but i can't change")
				client.print "NOK"
			elsif(line == "abort")
				puts("Receive Abort from client #{idc}")
				client.print "ACK"
			elsif(line == "commit")
				puts("Receive commit from client #{idc}")
				client.print "OK"
			elsif(line.split(":")[0] == "data")
				client.print "OK"
				puts("Receive data from client #{idc}, change data")
				puts("from "+data)
				dados=line.split("data:")
				data=dados[1]
				puts("To "+data)
				semaphore.unlock
			end
			sleep 1.0
			
		end
		clientNumber-=1
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