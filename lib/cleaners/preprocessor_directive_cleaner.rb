class PreprocessorDirectiveCleaner
  def self.Clean code
    code.gsub(DIRECTIVE, "")
  end

  private
  DIRECTIVE = /#.*$/
end

