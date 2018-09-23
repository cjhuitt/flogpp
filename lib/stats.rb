class Stats
  attr_reader :average

  def initialize collection, total
    @collection = collection
    @total = total
    @average = find_average
  end

  def multiple?
    return @collection.size > 1
  end

  private
    def find_average
      return 0 if @collection.empty?
      @total / @collection.size
    end

    def worst_count options
      return @collection.size if options[:all]
      if !options[:max_percent] and !options[:max_count]
        return [@collection.size/10.round, 1].max
      end
      percent = options[:max_percent] ?
              ((options[:max_percent] / 100.0) * @collection.size).round :
              0
      count = options[:max_count] ? options[:max_count] : 0
      [percent, count].max
    end

end
