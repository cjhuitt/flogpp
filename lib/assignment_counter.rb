require_relative "assignment_counter"

class AssignmentCounter
  attr_reader :assignments

  def initialize code
    cleaner = ExtraCleaner.new
    @assignments = check_assignments_in cleaner.clean code
  end

  private
    def check_assignments_in code
      assignments  = code.scan(/\b\w+\s*(<<=|>>=)\s*\w+\b/).size
      assignments += code.scan(/[^!=><]\s*=\s*[^!=]/).size
      assignments += code.scan("++").size
      assignments +  code.scan("--").size
    end
end
