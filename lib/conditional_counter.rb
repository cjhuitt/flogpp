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
               StringCleaner,
               ScopeCleaner,
               SimplePointerRedirectCleaner,
               SimpleMemberAccessCleaner,
               SimpleNewCleaner,
               ElseIfCleaner,
               ConstDeclarationCleaner]
      end
    end

    IF_BLOCK = /\bif\b[[:space:]]*(?<re>\((?:(?>[^()]+)|\g<re>)*\))/m
    def check_conditionals_in code
      conditionals = 0

      code.scan(IF_BLOCK) { |chunk|
        conditionals += find_conditionls_in_if_block chunk
      }
      code = code.gsub IF_BLOCK, ""

      conditionals += code.scan(/\bcatch\b/).size
      conditionals += code.scan(/[^<>-]\s*(>|<)\s*=?\s*[^<>]/).size
      conditionals += code.scan(/\belse\b/).size
      conditionals += code.scan(/\bcase\b/).size
      conditionals += code.scan(/\bdefault\b/).size
      conditionals += code.scan(/\btry\b/).size
      conditionals += code.scan("==").size
      conditionals += code.scan("!=").size
      conditionals
    end

    def find_conditionls_in_if_block code
      code.first.split(/(?:\|\||&&)/).count
    end
end
