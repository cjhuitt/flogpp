require_relative 'cleaner'

class ConstDeclarationCleaner < Cleaner
  def clean code
    code.gsub(CONST_VARIABLE_DECLARATION, "")
  end

  private
    CONST_VARIABLE_DECLARATION =
            /\bconst[[:space:]]+       # const as its own word
             [[:word:]]+[[:space:]]+   # variable type
             [[:word:]]+               # variable name
             [[:space:]]*=[[:space:]]* # assignment operator
             [[:word:]]+[[:space:]]*;  # variable value
            /x
end
