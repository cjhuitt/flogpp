require_relative 'cleaner'

class CatchCleaner < Cleaner
  def clean code
    code.gsub(CATCH_BLOCK, "")
  end

  private
    CATCH_BLOCK =
            /\bcatch        # catch keyword
             [[:space:]]*   # any amount of space
             \(.*\)        # parenthesis and anything inside them
            /x
end
