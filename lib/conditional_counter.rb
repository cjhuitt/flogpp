require_relative "cleaner_collection"

class ConditionalCounter
  attr_reader :conditionals

  def initialize code
    cleaner = Cleaners.new
    @conditionals = check_conditionals_in cleaner.clean code
  end

  private
    class Cleaners < CleanerCollection
      def initialize
        super [CommentCleaner,
               ScopeCleaner,
               SimplePointerRedirectCleaner,
               SimpleMemberAccessCleaner,
               SimpleNewCleaner,
               ElseIfCleaner,
               ConstDeclarationCleaner]
      end
    end

    def check_conditionals_in code
      conditionals  = code.scan("catch").size
      conditionals += code.scan(/[^<>-]\s*(>|<)\s*=?\s*[^<>]/).size
      conditionals += code.scan(/\bif\b[[:space:]]*\([^=><)]+\)/).size
      conditionals += code.scan("else").size
      conditionals += code.scan("case").size
      conditionals += code.scan("default").size
      conditionals += code.scan("try").size
      conditionals += code.scan(/^\s*\w+\s*$/).size      # unary conditions
      conditionals += code.scan("==").size
      conditionals +  code.scan("!=").size
    end
end
