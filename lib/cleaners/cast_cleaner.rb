class CastCleaner
  def self.Clean code
    code.gsub(CAST_BLOCK, "")
  end

  private
    CAST_BLOCK =
            /(?:[=,(][[:space:]]*) #non-matching comma, parenthesis, or equals
             \([^()]+\)            #at least one non-parenthesis character
            /x
end
