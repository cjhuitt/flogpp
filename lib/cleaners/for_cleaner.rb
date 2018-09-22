require_relative 'cleaner'

# Removes for constructs from the code base
class ForCleaner < Cleaner
  def clean code
    code.gsub(FOR_CONSTRUCT, "")
  end

  private
    FOR_CONSTRUCT = /\bfor\b/
end
