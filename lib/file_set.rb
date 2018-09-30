require_relative 'function_splitter'
require_relative 'snippet_analyzer'

class FileSet
  attr_reader :totals
  attr_reader :analyzed
  attr_reader :scored

  def initialize files
    @functions = get_functions_for files
    @analyzed = analyzers_for @functions

    score
  end

  private
    def get_functions_for files
      functions = Array.new
      files.each do |file|
        splitter = FunctionSplitter.new file, File.read(file)
        functions += splitter.functions
      end
      functions
    end

    def analyzers_for functions
      analyzed = Hash.new
      functions.each do |function|
        analyzer = SnippetAnalyzer.new(function.contents)
        analyzed[function] = analyzer
      end
      analyzed
    end

    def score
      @totals = Score.new
      @scored = Hash.new { |hash, key| hash[key] = Score.new }
      @analyzed.each do |function, analyzer|
        @totals += analyzer
        @scored[function.filename] += analyzer
      end
    end
end
