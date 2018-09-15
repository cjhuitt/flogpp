class SnippetAnalyzer
  attr_reader :assignments
  attr_reader :branches
  attr_reader :conditionals

  def initialize code
    @assignments = 0
    @branches = 0
    @conditionals = 0

    code = clean_comments_from code
    code = clean_const_declarations_from code

    check_conditionals_in code

    code = clean_function_declarations_from code

    @assignments = 1 if /\b\w+\s*(<<=|>>=)\s*\w+\b/.match? code
    @assignments = 1 if /[^!=><]\s*=\s*[^!=]/.match? code # straight assignment
    @assignments = 1 if code.include? "++"
    @assignments = 1 if code.include? "--"

    @branches = 1 if /(^|\s)(((::)?\w+)+)\s*\(\s*(([\w]+(\.|->)?)\s*,?\s*)*\s*\)/.match? code      # scoped function calls
    @branches = 1 if /(^|\s)((\w+)(\.|->)?)+\s*\(\s*(([\w]+(\.|->)?)\s*,?\s*)*\s*\)/.match? code   # pointer/instance function calls
    @branches = 2 if /\snew\s/.match? code
    @branches = 2 if /\sdelete\s/.match? code
    @branches = 3 if code.include? "goto"
  end

  def score
    @assignments + @branches + @conditionals
  end

  private
    C_COMMENT = /\/\*.*\*\//
    CPP_COMMENT = /\/\/.*$/
    def clean_comments_from code
      code.gsub(CPP_COMMENT, "").gsub(C_COMMENT, "")
    end

    CONST_VARIABLE_DECLARATION = /const\s+[\w:]+\s*[\w:]+\s*=\s*[\d.]+\s*;/
    def clean_const_declarations_from code
      code.gsub(CONST_VARIABLE_DECLARATION, "")
    end

    FUNCTION_DECLARATION = /[\w:]+\s*\(.*\)\s*{/
    def clean_function_declarations_from code
      code.gsub(FUNCTION_DECLARATION, "")
    end

    def check_conditionals_in code
      @conditionals = 1 if code.include? "catch"
      @conditionals = 1 if /[^<>-]\s*(>|<)\s*=?\s*[^<>]/.match? code
      @conditionals = 1 if code.include? "else"
      @conditionals = 1 if code.include? "case"
      @conditionals = 1 if code.include? "default"
      @conditionals = 1 if code.include? "try"
      @conditionals = 1 if /^\s*\w+\s*$/.match? code      # unary conditions
      @conditionals = 1 if code.include? "=="
      @conditionals = 1 if code.include? "!="
    end
end
