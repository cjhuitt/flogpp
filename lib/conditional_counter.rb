require_relative "cleaner"

class ConditionalCounter
  attr_reader :conditionals

  def initialize code
    cleaner = Cleaner.new
    @conditionals = check_conditionals_in cleaner.clean code
  end

  private
    def check_conditionals_in code
      conditionals  = code.scan("catch").size
      conditionals += code.scan(/[^<>-]\s*(>|<)\s*=?\s*[^<>]/).size
      conditionals += code.scan("else").size
      conditionals += code.scan("case").size
      conditionals += code.scan("default").size
      conditionals += code.scan("try").size
      conditionals += code.scan(/^\s*\w+\s*$/).size      # unary conditions
      conditionals += code.scan("==").size
      conditionals +  code.scan("!=").size
    end
end
