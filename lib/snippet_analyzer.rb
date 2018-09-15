class SnippetAnalyzer
  attr_reader :score
  def initialize( code )
    code.gsub! /\/\/.*$/, ""            # C++ Comments
    code.gsub! /\/\*.*\*\//, ""         # C Comments
    code.gsub! /[\w:]+\s*\(.*\)\s*{/, ""  # Function declarations
    code.gsub! /const\s+[\w:]+\s*[\w:]+\s*=\s*[\d.]+\s*;/, ""  # const variable assignment
    @score = 0
    @score = 1 if code.include? "="
    @score = 1 if code.include? "++"
    @score = 1 if code.include? "--"
    @score = 1 if code.include? "<"
    @score = 1 if code.include? ">"
    @score = 1 if code.include? "else"
    @score = 1 if /(^|\s)(((::)?\w+)+)\s*\(\s*(([\w]+(\.|->)?)\s*,?\s*)*\s*\)/.match? code      # scoped function calls
    @score = 1 if /(^|\s)((\w+)(\.|->)?)+\s*\(\s*(([\w]+(\.|->)?)\s*,?\s*)*\s*\)/.match? code   # pointer/instance function calls
    @score = 2 if /\snew\s/.match? code
    @score = 2 if /\sdelete\s/.match? code
    @score = 3 if code.include? "goto"
  end
end
