require 'socket'

puts "Digite a porta do servidor"
port= gets

server = TCPServer.new("127.0.0.1",Integer(port))

data="Dado1"
ok=true;

loop do
	Thread.start(server.accept) do |client|
		while line = client.gets   # Read lines from the socket
			puts line.chomp      # And print with platform line terminator
			if(((line.chomp == "change") || (line == "change")) && ok)
				puts("Receive Change")
				client.puts "OK"
				ok=false
			elsif(((line.chomp == "change") || (line == "change")) && !ok)
				puts("Receive Change but i can't change")
				client.puts "NOK"
			elsif((line.chomp == "abort") || (line == "abort"))
				puts("Receive Abort")
				client.puts "ACK"
				ok=true
			elsif((line.chomp == "commit") || (line == "commit"))
				puts("Receive commit")
				client.puts "OK"
			elsif((line.include? "data:") || (line.chomp.include? "data:"))
				puts("Receive data, change data from "+data)
				dados=line.split("data:")
				data=dados[1]
				ok=true
				client.puts "ACK"
				puts("To "+data)
			end
		end
	end
end
