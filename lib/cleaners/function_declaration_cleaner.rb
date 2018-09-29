class FunctionDeclarationCleaner
  def self.Clean code
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
