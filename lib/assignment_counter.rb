require_relative "assignment_counter"

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
