class FileStats
  def initialize scored_files, total_score
    @scored_files = scored_files
    @total_score = total_score
  end

  def multiple_files?
    return @scored_files.size > 1
  end

  def average_per_file
    return 0 if @scored_files.empty?
    @total_score / @scored_files.size
  end

  def worst_files count=5
    @scored_files.max_by(count) { |filename, score| score }
  end
end
