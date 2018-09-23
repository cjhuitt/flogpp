require_relative 'stats'

class FunctionStats < Stats
  attr_reader :worst

  def initialize collection, total, options
    super collection, total
    @worst = find_worst_by worst_count options
  end

  private
    def find_worst_by count
      @collection.max_by(count) { |function, analyzer| analyzer.score }
    end
end
