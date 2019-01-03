require 'json'

class NdjsonFile
  def initialize output, mode = 'w'
    @output = if output.is_a? String
      open(output, mode)
    else
      output
    end
  end
  
  def write obj
    @output.puts JSON.generate(obj)
  end  
end