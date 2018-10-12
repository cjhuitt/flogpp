class WhileZeroCleaner
  def self.Clean code
    code.gsub(WHILE_ZERO_BLOCK, "")
  end

  private
    WHILE_ZERO_BLOCK =
            /\bwhile\b
             [[:space:]]*\([[:space:]]*0[[:space:]]*\)
            /mx
end
