# Removes for constructs from the code base
class ForCleaner
  def self.Clean code
    code.gsub(FOR_CONSTRUCT, "")
  end

  private
    FOR_CONSTRUCT = /\bfor\b/
end
