class CommentCleaner
  def self.Clean code
    code.gsub(CPP_COMMENT, "").gsub(C_COMMENT, "")
  end

  private
    C_COMMENT = /\/\*.*?\*\//m
    CPP_COMMENT = /\/\/.*$/
end
