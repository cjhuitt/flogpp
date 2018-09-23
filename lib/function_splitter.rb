class FunctionSplitter
  attr_reader :functions

  class Function
    attr_reader :name
    attr_reader :line
    attr_reader :filename
    attr        :contents

    def initialize name, filename, line=0
      @name = name.match(FUNCTION_DEFINITION)[1]
      @line = line
      @contents = String.new
      @filename = filename
    end
  end

  def initialize filename, code
    @functions = Array.new
    chunks = code.split /({|})/
    name = String.new
    function = nil
    nest_level = 0
    startline = 1
    until chunks.empty?
      chunk = chunks.shift
      if function
        if chunk == '{'
          nest_level += 1
        elsif chunk == '}'
          nest_level -= 1
          if nest_level == 0
            @functions << function
            function = nil
            name = String.new
          end
        else
          function.contents << chunk.strip
        end
      else
        if chunk != '{'
          name += chunk
        end
        if chunk == '{'
          if name.match?(FUNCTION_DEFINITION)
            startline = startline + name.lines.size - 1
            function = Function.new name, filename, startline
            nest_level = 1
          else
            chunk += name
          end
        end
      end
    end
  end

  private
    FUNCTION_DEFINITION =
            /\b[[:word:]]+ # return type
             [[:space:]]+
             ([[:word:]]+) # function name
             [[:space:]]*
             \(.*\)        # optional parameters inside parenthesis
            /mx
end
