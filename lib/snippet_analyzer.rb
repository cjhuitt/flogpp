class SnippetAnalyzer
  attr_reader :score
  def initialize( code )
    code.gsub! /\/\/.*$/, ""            # C++ Comments
    code.gsub! /\/\*.*\*\//, ""         # C Comments
    code.gsub! /[\w:]+\s*(.*)\s*{/, ""  # Function declarations
    code.gsub! /const\s+[\w:]+\s*[\w:]+\s*=\s*[\d.]+\s*;/, ""  # const variable assignment
    @score = 0
    @score = 1 if code.include? "="
    @score = 1 if code.include? "++"
    @score = 1 if code.include? "--"
  end
end
