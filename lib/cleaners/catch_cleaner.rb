class CatchCleaner
  def self.Clean code
    code.gsub(CATCH_BLOCK, "")
  end

  private
    CATCH_BLOCK =
            /\bcatch        # catch keyword
             [[:space:]]*   # any amount of space
             \(.*\)        # parenthesis and anything inside them
            /x
end
