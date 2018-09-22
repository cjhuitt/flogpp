require_relative 'cleaner'

class ScopeCleaner < Cleaner
  def clean code
    code.gsub(SCOPE, "")
  end

  private
    SCOPE = /\s*::\s*/
end

