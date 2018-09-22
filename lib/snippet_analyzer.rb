require_relative "cleaner"

class AssignmentCounter
  attr_reader :assignments

  def initialize code
    cleaner = Cleaner.new code
    code = cleaner.clean_function_declarations_from cleaner.cleaned_code
    code = cleaner.clean_catches_from code

    @assignments = check_assignments_in code
  end

  private
    def check_assignments_in code
      assignments  = code.scan(/\b\w+\s*(<<=|>>=)\s*\w+\b/).size
      assignments += code.scan(/[^!=><]\s*=\s*[^!=]/).size
      assignments += code.scan("++").size
      assignments +  code.scan("--").size
    end
end

class BranchCounter
  attr_reader :branches

  def initialize code
    cleaner = Cleaner.new code
    code = cleaner.clean_function_declarations_from cleaner.cleaned_code
    code = cleaner.clean_catches_from code

    @branches = check_branches_in code
  end

  private
    def check_branches_in code
      branches  = code.scan(/\b[[:word:]]+[[:space:]]*\([^()]*\)/).size
      branches += code.scan(/\snew\s/).size * 2
      branches += code.scan(/\sdelete\s/).size * 2
      branches +  code.scan("goto").size * 3
    end
end

class ConditionalCounter
  attr_reader :conditionals

  def initialize code
    cleaner = Cleaner.new code
    @conditionals = check_conditionals_in cleaner.cleaned_code
  end

  private
    def check_conditionals_in code
      conditionals  = code.scan("catch").size
      conditionals += code.scan(/[^<>-]\s*(>|<)\s*=?\s*[^<>]/).size
      conditionals += code.scan("else").size
      conditionals += code.scan("case").size
      conditionals += code.scan("default").size
      conditionals += code.scan("try").size
      conditionals += code.scan(/^\s*\w+\s*$/).size      # unary conditions
      conditionals += code.scan("==").size
      conditionals +  code.scan("!=").size
    end
end

class SnippetAnalyzer
  attr_reader :score

  def initialize code
    @score = AssignmentCounter.new(code).assignments
    @score += BranchCounter.new(code).branches
    @score += ConditionalCounter.new(code).conditionals
  end
end
