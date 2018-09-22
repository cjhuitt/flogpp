require_relative 'cleaner'

# removes the 'else if' keywords from the code
class ElseIfCleaner < Cleaner
  def clean code
    code.gsub(ELSE_IF_CONSTRUCT, "")
  end

  private
    ELSE_IF_CONSTRUCT =
            /\b
             else[[:space:]]+
             if\b
             [[:space:]]*
            /x
end
