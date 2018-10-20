class Stats
  attr_reader :average
  attr_reader :worst

  def initialize collection, total, range, sort=:overall
    @collection = collection
    @total = total
    @average = find_average
    count = range.count(@collection.size)
    @worst = @collection.max_by(count) { |filename, score|
      score.send(sort)
    }
  end

  def multiple?
    return @collection.size > 1
  end

  private
    def find_average
      return 0 if @collection.empty?
      @total / @collection.size
    end
end
