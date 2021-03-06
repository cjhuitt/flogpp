require_relative "cleaner_collection"

class AssignmentCounter
  attr_reader :assignments

  def initialize code
    cleaner = Cleaners.new
    @assignments = check_assignments_in cleaner.clean code
  end

  private
    class Cleaners < CleanerCollection
      # Remove unnecessary complications, leaving the structure for analysis
      def initialize
        super [CommentCleaner,
               ScopeCleaner,
               SimplePointerRedirectCleaner,
               SimpleMemberAccessCleaner,
               SimpleNewCleaner,
               ConstDeclarationCleaner,
               FunctionDeclarationCleaner,
               CatchCleaner]
      end
    end

    def check_assignments_in code
      assignments  = code.scan(/\b\w+\s*(<<=|>>=)\s*\w+\b/).size
      assignments += code.scan(/[^!=><]\s*=\s*[^!=]/).size
      assignments += code.scan("++").size
      assignments +  code.scan("--").size
    end
end
