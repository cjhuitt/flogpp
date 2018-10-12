class WhileCleaner
  def self.Clean code
    code.gsub(WHILE_BLOCK) { |m| $1 }
  end

  private
    WHILE_BLOCK = /\bwhile\b[[:space:]]*(?<re>\((?:(?>[^()]+)|\g<re>)*\))/m
end
