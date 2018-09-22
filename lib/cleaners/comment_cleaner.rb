require_relative 'cleaner'

class CommentCleaner < Cleaner
  def clean code
    code.gsub(CPP_COMMENT, "").gsub(C_COMMENT, "")
  end

  private
    C_COMMENT = /\/\*.*\*\//
    CPP_COMMENT = /\/\/.*$/
end
