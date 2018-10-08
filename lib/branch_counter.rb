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
        super [PreprocessorDirectiveCleaner,
               CommentCleaner,
               ScopeCleaner,
               SimplePointerRedirectCleaner,
               SimpleMemberAccessCleaner,
               SimpleNewCleaner,
               ConstDeclarationCleaner,
               IfCleaner,
               ForCleaner,
               CastCleaner,
               CatchCleaner]
      end
    end

    def check_branches_in code
      branches  = BranchCounter::FindFunctions code

      # malloc and free are already counted once as functions
      branches += code.scan(/\b(aligned_)?malloc\b/).size
      branches += code.scan(/\bfree\b/).size

      branches += code.scan(/\bnew\b/).size * 2
      branches += code.scan(/\bdelete\b/).size * 2

      branches +  code.scan(/\bgoto\b/).size * 3
    end

    FUNCTION = /\b[[:word:]]+[[:space:]]*\([^()]*\)/
    def self.FindFunctions code
      functions = code.scan(FUNCTION)
      return 0 if functions.empty?
      functions.size + BranchCounter::FindFunctions(code.gsub FUNCTION, "")
    end
end
