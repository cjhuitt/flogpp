require_relative 'snippet_analyzer'

class CompoundAnalyzer

  def initialize code
    @snippet = SnippetAnalyzer.new code
  end

  def score
    @snippet.score
  end
end
