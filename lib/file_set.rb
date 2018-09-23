require_relative 'compound_analyzer'
require_relative 'function_splitter'

class FileSet
  attr_reader :functions
  attr_reader :total_score
  attr_reader :analyzed
  attr_reader :scored_files

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
        analyzer = CompoundAnalyzer.new(function.contents)
        analyzed[function] = analyzer
      end
      analyzed
    end

    def score
      @total_score = 0
      @scored_files = Hash.new 0
      @analyzed.each do |function, analyzer|
        score = analyzer.score
        @total_score += score
        @scored_files[function.filename] += score
      end
    end
end
