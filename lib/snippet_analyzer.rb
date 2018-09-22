require_relative "assignment_counter"
require_relative "branch_counter"
require_relative "conditional_counter"

class SnippetAnalyzer
  attr_reader :score

  def initialize code
    @score = AssignmentCounter.new(code).assignments
    @score += BranchCounter.new(code).branches
    @score += ConditionalCounter.new(code).conditionals
  end
end
