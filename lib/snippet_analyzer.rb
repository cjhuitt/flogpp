class SnippetAnalyzer
  attr_reader :assignments
  attr_reader :branches

  def initialize( code )
    @assignments = 0
    @branches = 0
    code.gsub! /\/\/.*$/, ""            # C++ Comments
    code.gsub! /\/\*.*\*\//, ""         # C Comments
    code.gsub! /const\s+[\w:]+\s*[\w:]+\s*=\s*[\d.]+\s*;/, ""  # const variable assignment
    @assignments = 1 if code.include? "catch"
    code.gsub! /[\w:]+\s*\(.*\)\s*{/, ""  # Function declarations
    @assignments = 1 if code.include? "="
    @assignments = 1 if code.include? "++"
    @assignments = 1 if code.include? "--"
    @assignments = 1 if code.include? "<"
    @assignments = 1 if /[^-]\s*>/.match? code
    @assignments = 1 if code.include? "else"
    @assignments = 1 if code.include? "case"
    @assignments = 1 if code.include? "default"
    @assignments = 1 if code.include? "try"
    @assignments = 1 if /^\s*\w+\s*$/.match? code      # unary conditions
    @branches = 1 if /(^|\s)(((::)?\w+)+)\s*\(\s*(([\w]+(\.|->)?)\s*,?\s*)*\s*\)/.match? code      # scoped function calls
    @branches = 1 if /(^|\s)((\w+)(\.|->)?)+\s*\(\s*(([\w]+(\.|->)?)\s*,?\s*)*\s*\)/.match? code   # pointer/instance function calls
    @branches = 2 if /\snew\s/.match? code
    @branches = 2 if /\sdelete\s/.match? code
    @branches = 3 if code.include? "goto"
  end

  def score
    @assignments + @branches
  end
end
