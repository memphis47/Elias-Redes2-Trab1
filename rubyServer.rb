require 'socket'
require './log.rb'

puts "Digite a porta do servidor"
port= gets

server = TCPServer.new("h21",Integer(port))

data="Dado1"
$ok=true;

loop do
	Thread.start(server.accept) do |client|
		while line = client.gets   # Read lines from the socket
			puts line.chomp      # And print with platform line terminator
			if(((line.chomp == "change") || (line == "change")) && $ok)
				puts("Receive Change")
				client.print "OK"
				$ok=false
			elsif(((line.chomp == "change") || (line == "change")) && !$ok)
				puts("Receive Change but i can't change")
				client.print "NOK"
			elsif((line.chomp == "abort") || (line == "abort"))
				puts("Receive Abort")
				client.print "ACK"
				$ok=true
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
