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
               WhileZeroCleaner,
               ConstDeclarationCleaner]
      end
    end

    IF_BLOCK = /\bif\b[[:space:]]*(?<re>\((?:(?>[^()]+)|\g<re>)*\))/m
    WHILE_BLOCK = /\bwhile\b[[:space:]]*(?<re>\((?:(?>[^()]+)|\g<re>)*\))/m
    TERNARY_BLOCK = /[=,\(][[:space:]]*(?<re>\((?:(?>[^()]+)|\g<re>)*\))[[:space:]]*\?/m
    def check_conditionals_in code
      conditionals = 0

      code.scan(IF_BLOCK) { |chunk|
        conditionals += find_conditionals_in_block chunk
      }
      code = code.gsub IF_BLOCK, ""

      code.scan(WHILE_BLOCK) { |chunk|
        conditionals += find_conditionals_in_block chunk
      }
      code = code.gsub WHILE_BLOCK, ""

      code.scan(TERNARY_BLOCK) { |chunk|
        conditionals += find_conditionals_in_block chunk
      }
      code = code.gsub TERNARY_BLOCK, ""

      conditionals += code.scan(/\bcatch\b/).size
      conditionals += code.scan(/[^<>-]\s*(>|<)\s*=?\s*[^<>]/).size
      conditionals += code.scan(/\belse\b/).size
      conditionals += code.scan(/\bcase\b/).size
      conditionals += code.scan(/\bdefault\b/).size
      conditionals += code.scan(/\btry\b/).size
      conditionals += code.scan("==").size
      conditionals += code.scan("!=").size
      conditionals += code.scan("?").size
      conditionals += code.scan("&&").size
      conditionals += code.scan("||").size
      conditionals
    end

    def find_conditionals_in_block code
      code.first.split(/(?:\|\||&&)/).count
    end
end
