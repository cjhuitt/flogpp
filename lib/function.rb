class Function
  attr_reader :name
  attr_reader :line
  attr_reader :filename
  attr        :contents

  def initialize name, filename, line
    @name = name
    @line = line
    @contents = String.new
    @filename = filename
  end
end
