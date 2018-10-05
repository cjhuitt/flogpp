class Function
  attr_reader :name
  attr_reader :line
  attr_reader :filename
  attr_reader :contents

  def initialize name, filename, line, contents
    @name = name
    @line = line
    @contents = contents
    @filename = filename
  end
end
