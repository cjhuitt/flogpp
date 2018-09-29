class SimpleNewCleaner
  def self.Clean code
    code.gsub(SIMPLE_NEW_WITH_PARENS, "\\1")
  end

  private
    SIMPLE_NEW_WITH_PARENS =
            /(new         # new keyword
             [[:space:]]+ # required whitespace
             [[:word:]]+) # typename
             \([[:space:]]*\)         # parenthesis with nothing inside
            /x
end
