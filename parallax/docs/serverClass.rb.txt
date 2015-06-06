class Server
	def name=(value)
		@name=value
	end
	
	def port=(value)
		@port=value
	end

	def name
		return @name
	end
	
	def port
		return @port
	end

	def socket=(value)
		@socket=value
	end
	
	def socket
		return @socket
	end
end