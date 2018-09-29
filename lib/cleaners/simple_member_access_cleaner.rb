class SimpleMemberAccessCleaner
  # Note this also removes decimals from constant float/doubles, but \shrug
  def self.Clean code
    code.gsub(SIMPLE_MEMBER_ACCESS, "")
  end

  private
    SIMPLE_MEMBER_ACCESS =
            /(?<=[[:word:]])             # Previous character is an identifier
             [[:space:]]*\.[[:space:]]*  # Dot with optional space
             (?=[[:word:]])              # Next character is an identifier
            /x
end
