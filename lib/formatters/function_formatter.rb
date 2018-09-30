class FunctionFormatter
  def self.Format function
    return "#{function.name} (#{function.filename}:#{function.line})"
  end
end
