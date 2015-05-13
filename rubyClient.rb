require "socket"

class Client
  def initialize( server )
    @server = server
    @request = nil
    @response = nil
    listen
    send
    @request.join
    @response.join
  end
 
  def listen
    @response = Thread.new do
      loop {
        msg = @server.gets.chomp
        puts "#{msg}"
      }
    end
  end
 
  def send(msg="Default Message To Socket")
    @request = Thread.new do
      loop {
        @server.puts( msg )
      }
    end
  end
end
 
server = TCPSocket.open( "localhost", 3000 )

c=Client.new( server )
c.send

while true
	puts "Send a Message to server:\n"
	msg = $stdin.read
	c.send(msg)	
end


