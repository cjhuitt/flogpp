class SnippetAnalyzer
  attr_reader :assignments
  attr_reader :branches
  attr_reader :conditionals

  class Cleaner
    # Remove unnecessary complications, leaving the structure for analysis
    attr_reader :cleaned_code
    def initialize code
      @cleaned_code = clean_comments_from code
      @cleaned_code = clean_const_declarations_from @cleaned_code
    end

    def clean_function_declarations_from code
      code.gsub(FUNCTION_DECLARATION, "")
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
  end

  def initialize code
    @assignments = 0
    @branches = 0
    @conditionals = 0

    cleaner = Cleaner.new code

    check_conditionals_in cleaner.cleaned_code

    code = cleaner.clean_function_declarations_from cleaner.cleaned_code

    check_assignments_in code
    check_branches_in code
  end

  def score
    @assignments + @branches + @conditionals
  end

  private
    def check_assignments_in code
      @assignments = 1 if /\b\w+\s*(<<=|>>=)\s*\w+\b/.match? code
      @assignments += code.scan(/[^!=><]\s*=\s*[^!=]/).size
      @assignments = 1 if code.include? "++"
      @assignments = 1 if code.include? "--"
    end

    def check_branches_in code
      @branches = 1 if /(^|\s)(((::)?\w+)+)\s*\(\s*(([\w]+(\.|->)?)\s*,?\s*)*\s*\)/.match? code      # scoped function calls
      @branches = 1 if /(^|\s)((\w+)(\.|->)?)+\s*\(\s*(([\w]+(\.|->)?)\s*,?\s*)*\s*\)/.match? code   # pointer/instance function calls
      @branches = 2 if /\snew\s/.match? code
      @branches = 2 if /\sdelete\s/.match? code
      @branches = 3 if code.include? "goto"
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
