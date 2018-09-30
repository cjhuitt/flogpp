require_relative "assignment_counter"
require_relative "branch_counter"
require_relative "conditional_counter"
require_relative "score"

class SnippetAnalyzer < Score
  def initialize code
    super
    @assignments = AssignmentCounter.new(code).assignments
    @branches = BranchCounter.new(code).branches
    @conditionals = ConditionalCounter.new(code).conditionals
  end
end
