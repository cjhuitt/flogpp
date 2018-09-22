require_relative "cleaner"

class BranchCounter
  attr_reader :branches

  def initialize code
    cleaner = ExtraCleaner.new
    @branches = check_branches_in cleaner.clean code
  end

  private
    def check_branches_in code
      branches  = code.scan(/\b[[:word:]]+[[:space:]]*\([^()]*\)/).size
      branches += code.scan(/\snew\s/).size * 2
      branches += code.scan(/\sdelete\s/).size * 2
      branches +  code.scan("goto").size * 3
    end
end
