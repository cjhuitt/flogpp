class Cleaner
  # Remove unnecessary complications, leaving the structure for analysis
  attr_reader :cleaned_code
  def initialize code
    cleaners = [method(:clean_comments_from),
                method(:clean_scopes_from),
                method(:clean_simple_pointer_redirects_from),
                method(:clean_simple_member_access_from),
                method(:clean_simple_new_with_params_from),
                method(:clean_const_declarations_from)]
    @cleaned_code = code
    cleaners.each { |c| @cleaned_code = c.call @cleaned_code }
  end

  def clean_function_declarations_from code
    code.gsub(FUNCTION_DECLARATION, "{")
  end

  def clean_catches_from code
    code.gsub(CATCH_BLOCK, "")
  end

  private
    C_COMMENT = /\/\*.*\*\//
    CPP_COMMENT = /\/\/.*$/
    def clean_comments_from code
      code.gsub(CPP_COMMENT, "").gsub(C_COMMENT, "")
    end

    SCOPE = /\s*::\s*/
    def clean_scopes_from code
      code.gsub(SCOPE, "")
    end

    SIMPLE_POINTER_REDIRECTION =
            /(?<=[[:word:]])             # Previous character is an identifier
             [[:space:]]*->[[:space:]]*  # Arrow with optional space
             (?=[[:word:]])              # Next character is an identifier
            /x
    def clean_simple_pointer_redirects_from code
      code.gsub(SIMPLE_POINTER_REDIRECTION, "")
    end

    SIMPLE_MEMBER_ACCESS =
            /(?<=[[:word:]])             # Previous character is an identifier
             [[:space:]]*\.[[:space:]]*  # Dot with optional space
             (?=[[:word:]])              # Next character is an identifier
            /x
    # Note this also removes decimals from constant float/doubles, but \shrug
    def clean_simple_member_access_from code
      code.gsub(SIMPLE_MEMBER_ACCESS, "")
    end

    SIMPLE_NEW_WITH_PARENS =
            /(new         # new keyword
             [[:space:]]+ # required whitespace
             [[:word:]]+) # typename
             \([[:space:]]*\)         # parenthesis with nothing inside
            /x
    # Note this also removes decimals from constant float/doubles, but \shrug
    def clean_simple_new_with_params_from code
      code.gsub(SIMPLE_NEW_WITH_PARENS, "\\1")
    end

    CONST_VARIABLE_DECLARATION =
            /\bconst[[:space:]]+       # const as its own word
             [[:word:]]+[[:space:]]+   # variable type
             [[:word:]]+               # variable name
             [[:space:]]*=[[:space:]]* # assignment operator
             [[:word:]]+[[:space:]]*;  # variable value
            /x
    def clean_const_declarations_from code
      code.gsub(CONST_VARIABLE_DECLARATION, "")
    end

    FUNCTION_DECLARATION =
            /\b[[:word:]]+ # return type
             [[:space:]]+
             [[:word:]]+   # function name
             [[:space:]]*
             \(.*\)        # optional parameters inside parenthesis
             [[:space:]]*
             {             # open brace
            /x

    CATCH_BLOCK =
            /\bcatch        # catch keyword
             [[:space:]]*   # any amount of space
             \(.*\)        # parenthesis and anything inside them
            /x
end
