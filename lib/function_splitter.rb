require_relative "function"
require_relative "function_definition_matcher"

class FunctionSplitter
  attr_reader :functions

  def initialize filename, code
    @functions = Array.new
    chunks = code.split /({|})/
    name = String.new
    function = nil
    nest_level = 0
    startline = 1
    until chunks.empty?
      chunk = chunks.shift
      startline += chunk.lines.count - 1
      startline += 1 if chunk[-1] == "\n"
      if function
        if chunk == '{'
          function.contents << chunk if nest_level != 0
          nest_level += 1
        elsif chunk == '}'
          nest_level -= 1
          if nest_level == 0
            @functions << function
            function = nil
            name = String.new
          else
            function.contents << chunk
          end
        else
          function.contents << chunk
        end
      else
        if chunk != '{'
          name += chunk
        end
        if chunk == '{'
          matcher = FunctionDefinitionMatcher.new name
          if matcher.passes?
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
