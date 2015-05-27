require 'socket'
require './log.rb'
require 'thread'

semaphore = Mutex.new

# puts "Digite o nome do servidor"
# name= gets.chomp

name = Socket.gethostname

puts "Digite a porta do servidor"
port= Integer(gets.chomp)

server = TCPServer.new(name,port)

data="Dado1"
$ok=true;
puts "#{name}:#{port.to_s}"

loop do
	Thread.start(server.accept) do |client|
		while line = client.gets   # Read lines from the socket
			puts line.chomp      # And print with platform line terminator
			if(((line.chomp == "change") || (line == "change")) && $ok)
				$ok=false
				puts("Receive Change")
				client.print "OK"
			elsif(((line.chomp == "change") || (line == "change")) && !$ok)
				puts("Receive Change but i can't change")
				client.print "NOK"
			elsif((line.chomp == "abort") || (line == "abort"))
				$ok=true
				puts("Receive Abort")
				client.print "ACK"
			elsif((line.chomp == "commit") || (line == "commit"))
				puts("Receive commit")
				client.print "OK"
			elsif((line.split(":")[0] == "data"))
				$ok=true
				client.print "OK"
				puts("Receive data, change data from "+data)
				dados=line.split("data:")
				data=dados[1]
				puts("To "+data)
			end
		end
	end
end
