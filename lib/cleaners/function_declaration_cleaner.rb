require_relative 'cleaner'

class FunctionDeclarationCleaner < Cleaner
  def clean code
    code.gsub(FUNCTION_DECLARATION, "{")
  end

  private
    FUNCTION_DECLARATION =
            /\b[[:word:]]+ # return type
             [[:space:]]+
             [[:word:]]+   # function name
             [[:space:]]*
             \(.*\)        # optional parameters inside parenthesis
             [[:space:]]*
             {             # open brace
            /x
end
