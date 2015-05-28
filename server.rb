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
port = Integer(ARGV[0])
server = TCPServer.new(name,port)

data="Dado1"
$ok=true
puts "#{name}:#{port.to_s}"
$i=0
loop do
	Thread.start(server.accept) do |client|
		# clientIp=Resolv.getname(request.remote_ip)
		# puts "client data: "+client.remote_ip+" <<"
		$i+=1
		while line = client.gets.chomp  # Read lines from the socket
			# puts line    			# And print with platform line terminator
			puts "=== Request #{$i} Start ==="
			if(line == "change" && $ok)
				$ok=false
				puts("Receive Change")
				client.print "OK"
			elsif(line == "change" && !$ok)
				puts("Receive Change but i can't change")
				client.print "NOK"
			elsif(line == "abort")
				$ok=true
				puts("Receive Abort")
				client.print "ACK"
			elsif(line == "commit")
				puts("Receive commit")
				client.print "OK"
			elsif(line.split(":")[0] == "data")
				$ok=true
				client.print "OK"
				puts("Receive data, change data from:")
				puts ("  #{data}")
				data=line.split("data:")[1]
				puts("To:")
				puts ("  #{data}")
			end
			puts "=== Request #{$i} End ==="
		end
	end
end
