class OutputWriter
  def write_header total_score, file_stats, function_stats
    puts "%8.1f: Flog total" % total_score
    puts "%8.1f: Flog average/file" % file_stats.average_per_file if file_stats.multiple_files?
    puts "%8.1f: Flog average/function" % function_stats.average_per_function if function_stats.multiple_functions?
  end

  def write_separator
    puts ""
  end

  def write_file_summary file_stats
    if file_stats.multiple_files?
      file_stats.worst_files.each do |entry|
        puts "%8.1f: #{entry[0]}" % entry[1]
      end
      write_separator
    end
  end

  def write_function_summary function_stats
    function_stats.worst_functions.each do |entry|
      puts "%8.1f: #{entry[0].name} (#{entry[0].filename}:#{entry[0].line})" % entry[1].score
    end
    write_separator
  end
end
