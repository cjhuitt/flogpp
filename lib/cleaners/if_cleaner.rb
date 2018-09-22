require_relative 'cleaner'

# Removes if or else if constructs from the code base
class IfCleaner < Cleaner
  def clean code
    code.gsub(IF_OR_ELSE_IF_CONSTRUCT, "")
  end

  private
    IF_OR_ELSE_IF_CONSTRUCT =
            /\b
             (else[[:space:]]+)? #optional else prior to if
             if\b
             [[:space:]]*
            /x
end
