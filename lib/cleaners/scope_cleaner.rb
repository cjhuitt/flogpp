class ScopeCleaner
  def self.Clean code
    code.gsub(SCOPE, "")
  end

  private
    SCOPE = /\s*::\s*/
end

