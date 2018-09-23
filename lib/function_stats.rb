class FunctionStats
  def initialize analyzed, total_score
    @analyzed = analyzed
    @total_score = total_score
  end

  def multiple_functions?
    return @analyzed.size > 1
  end

  def average_per_function
    return 0 if @analyzed.empty?
    @total_score / @analyzed.size
  end

  def worst_functions count=5
    @analyzed.max_by(count) { |function, analyzer| analyzer.score }
  end
end
