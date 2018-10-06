# removes the 'else if' keywords from the code
class ElseIfCleaner
  def self.Clean code
    code.gsub(ELSE_IF_CONSTRUCT, "if")
  end

  private
    ELSE_IF_CONSTRUCT =
            /\b
             else[[:space:]]+
             if\b
             [[:space:]]*
            /x
end
