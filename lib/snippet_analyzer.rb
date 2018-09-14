class SnippetAnalyzer
  attr_reader :score
  def initialize( code )
    code.gsub! /\/\/.*$/, ""            # C++ Comments
    code.gsub! /\/\*.*\*\//, ""         # C Comments
    code.gsub! /[\w:]+\s*(.*)\s*{/, ""  # Function declarations
    @score = 0
    @score = 1 if code.include? "="
  end
end
