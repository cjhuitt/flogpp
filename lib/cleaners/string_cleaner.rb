class StringCleaner
  def self.Clean code
    code.gsub(STRING_BLOCK, "STRING")
  end

  private
    STRING_BLOCK =
            /(^|           # Beginning of the string OR
              (?<=[^\\]))  # Non-slash (not captured)
             "
             .*?           # Lazy anything
             (?<!\\)       # Non-slash immediately proceeding end
             "
            /mx
end
