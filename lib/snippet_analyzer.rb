class SnippetAnalyzer
  attr_reader :assignments
  attr_reader :branches
  attr_reader :conditionals

  def initialize(code)
    @assignments = 0
    @branches = 0
    @conditionals = 0

    code.gsub! /\/\/.*$/, ""            # C++ Comments
    code.gsub! /\/\*.*\*\//, ""         # C Comments
    code.gsub! /const\s+[\w:]+\s*[\w:]+\s*=\s*[\d.]+\s*;/, ""  # const variable assignment
    @conditionals = 1 if code.include? "catch"
    code.gsub! /[\w:]+\s*\(.*\)\s*{/, ""  # Function declarations
    if /\b\w+\s*(<<=|>>=)\s*\w+\b/.match? code
      @assignments = 1
      code.gsub! /\b\w+\s*(<<=|>>=)\s*\w+\b/, ""
    end
    @assignments = 1 if /[^!=><]\s*=\s*[^!=]/.match? code # straight assignment
    @assignments = 1 if code.include? "++"
    @assignments = 1 if code.include? "--"

    @branches = 1 if /(^|\s)(((::)?\w+)+)\s*\(\s*(([\w]+(\.|->)?)\s*,?\s*)*\s*\)/.match? code      # scoped function calls
    @branches = 1 if /(^|\s)((\w+)(\.|->)?)+\s*\(\s*(([\w]+(\.|->)?)\s*,?\s*)*\s*\)/.match? code   # pointer/instance function calls
    @branches = 2 if /\snew\s/.match? code
    @branches = 2 if /\sdelete\s/.match? code
    @branches = 3 if code.include? "goto"

    @conditionals = 1 if code.include? "<"
    @conditionals = 1 if /[^-]\s*>/.match? code # greater than which isn't a pointer access
    @conditionals = 1 if code.include? "else"
    @conditionals = 1 if code.include? "case"
    @conditionals = 1 if code.include? "default"
    @conditionals = 1 if code.include? "try"
    @conditionals = 1 if /^\s*\w+\s*$/.match? code      # unary conditions
    @conditionals = 1 if code.include? "=="
    @conditionals = 1 if code.include? "!="
  end

  def score
    @assignments + @branches + @conditionals
  end
end
