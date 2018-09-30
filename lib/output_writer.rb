require_relative "formatters/file_formatter"
require_relative "formatters/function_formatter"
require_relative "formatters/score_formatters"

class OutputWriter
  def initialize score_fmt=OverallScoreFormatter
    @score_fmt = score_fmt
  end

  def write_header total_score, file_stats, function_stats
    puts "#{@score_fmt::Format total_score}: Total"
    puts "#{@score_fmt::Format file_stats.average}: Average/file" if file_stats.multiple?
    puts "#{@score_fmt::Format function_stats.average}: Average/function" if function_stats.multiple?
  end

  def write_separator
    puts ""
  end

  def write_file_summary stats
    write_summary stats, FileFormatter
  end

  def write_function_summary stats
    write_summary stats, FunctionFormatter
  end

  private
    def write_summary stats, id_fmt
      if stats.multiple?
        stats.worst.each do |entry|
          puts "#{@score_fmt::Format entry[1]}: #{id_fmt::Format entry[0]}"
        end
        write_separator
      end
    end
end
