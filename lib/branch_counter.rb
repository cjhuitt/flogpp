require_relative "cleaner"

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
