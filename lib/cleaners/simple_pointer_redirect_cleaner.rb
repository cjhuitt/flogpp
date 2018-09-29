class SimplePointerRedirectCleaner
  def self.Clean code
    code.gsub(SIMPLE_POINTER_REDIRECTION, "")
  end

  private
    SIMPLE_POINTER_REDIRECTION =
            /(?<=[[:word:]])             # Previous character is an identifier
             [[:space:]]*->[[:space:]]*  # Arrow with optional space
             (?=[[:word:]])              # Next character is an identifier
            /x
end
