require_relative 'cleaner'

class SimpleMemberAccessCleaner < Cleaner
  # Note this also removes decimals from constant float/doubles, but \shrug
  def clean code
    code.gsub(SIMPLE_MEMBER_ACCESS, "")
  end

  private
    SIMPLE_MEMBER_ACCESS =
            /(?<=[[:word:]])             # Previous character is an identifier
             [[:space:]]*\.[[:space:]]*  # Dot with optional space
             (?=[[:word:]])              # Next character is an identifier
            /x
end
