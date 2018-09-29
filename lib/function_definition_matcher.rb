require_relative "cleaners/comment_cleaner"

class FunctionDefinitionMatcher
  attr_reader :name

  def initialize code
    code = CommentCleaner::Clean code
    @passes = code.match? FUNCTION_DEFINITION
    @name = code.match(FUNCTION_DEFINITION)[1] if @passes
  end

  def passes?
    @passes
  end

  private
    FUNCTION_DEFINITION =
      /\b[[:word:]]+            # return type
       (?:[[:space:]]|\*)+      # some sort of break (space(s) or asterisk(s) or both)
       ([[:word:]]+)            # function name
       [[:space:]]*
       \([^;]*\)                # optional parameters inside parenthesis
       [[:space:]]*
       [^;]                     # A non-semicolon character means definition not declaration
      /mx
end
