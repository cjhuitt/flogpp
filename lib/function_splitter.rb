require_relative "function_definition_matcher"

class FunctionSplitter
  attr_reader :functions

  class Function
    attr_reader :name
    attr_reader :line
    attr_reader :filename
    attr        :contents

    def initialize name, filename, line=0
      @name = name
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
          matcher = FunctionDefinitionMatcher.new name
          if matcher.passes?
            startline = startline + name.lines.size - 1
            function = Function.new matcher.name, filename, startline
            nest_level = 1
          else
            chunk += name
          end
        end
      end
    end
  end
end
