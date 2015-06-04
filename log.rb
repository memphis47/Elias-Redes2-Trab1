class Log
  @@writing = false

  def initialize
    while @@writing do end
    @@writing = true
    @name = "LogClient-"+Time.now.strftime("%d%m%Y-%H%M%S")+".log"
    open(@name, 'w') do || end
    @@writing = false
  end

  def write(text, type="info")
    unless type=="info"
      type = "error"
    end
    open(@name, 'a') do |f|
      f << Time.now.strftime("%d/%m/%Y %H:%M:%S ") << type.capitalize << ": " << text << "\n"
    end
  end

  def name
    @name
  end
end