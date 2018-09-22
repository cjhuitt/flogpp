require_relative "cleaner_collection"

class BranchCounter
  attr_reader :branches

  def initialize code
    cleaner = Cleaners.new
    @branches = check_branches_in cleaner.clean code
  end

  private
    class Cleaners < CleanerCollection
      # Remove unnecessary complications, leaving the structure for analysis
      def initialize
        super [CommentCleaner.new,
               ScopeCleaner.new,
               SimplePointerRedirectCleaner.new,
               SimpleMemberAccessCleaner.new,
               SimpleNewCleaner.new,
               ConstDeclarationCleaner.new,
               FunctionDeclarationCleaner.new,
               IfCleaner.new,
               CatchCleaner.new]
      end
    end

    def check_branches_in code
      branches  = code.scan(/\b[[:word:]]+[[:space:]]*\([^()]*\)/).size
      branches += code.scan(/\snew\s/).size * 2
      branches += code.scan(/\sdelete\s/).size * 2
      branches +  code.scan("goto").size * 3
    end
end
