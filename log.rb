class Log
  @@writing = false
  def verifyFiles
    i=0
    while File.exist?("logClient"+i.to_s+".log") do
      i+=1
    end
    i
  end

  def initialize
    @logN = verifyFiles
    while @@writing do end
    @@writing = true
    @name = "logClient"+@logN.to_s+".log"
    open(@name, 'w') do || end
    @@writing = false
  end

  def write(text)
    open(@name, 'a') do |f|
      f << text << "\n"
    end
  end

  def name
    @name
  end

  def logN
    @logN
  end
end