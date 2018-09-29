class FunctionDefinitionMatcher
  attr_reader :name

  def initialize code
    @passes = code.match? FUNCTION_DEFINITION
    @name = code.match(FUNCTION_DEFINITION)[1] if @passes else nil
  end

  def passes?
    @passes
  end

  private
    FUNCTION_DEFINITION =
            /\b[[:word:]]+ # return type
             [[:space:]]+
             ([[:word:]]+) # function name
             [[:space:]]*
             \(.*\)        # optional parameters inside parenthesis
             [[:space:]]*
             [^;]
            /mx
end
