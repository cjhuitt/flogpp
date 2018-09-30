class Stats
  attr_reader :average
  attr_reader :worst

  def initialize collection, total, options
    @collection = collection
    @total = total
    @average = find_average
    count = worst_count options
    @worst = @collection.max_by(count) { |filename, score|
    case options[:rank]
    when :assignments
        Stats::AssignmentsScore score
    when :branches
      Stats::BranchesScore score
    when :conditionals
      Stats::ConditionalsScore score
    else
      Stats::OverallScore score
    end
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

    def worst_count options
      return @collection.size if options[:full]
      if !options[:max_percent] and !options[:max_count]
        return [@collection.size/10.round, 1].max
      end
      percent = options[:max_percent] ?
              ((options[:max_percent] / 100.0) * @collection.size).round :
              0
      count = options[:max_count] ? options[:max_count] : 0
      [percent, count].max
    end

    def self.AssignmentsScore score
      score.assignments
    end

    def self.BranchesScore score
      score.branches
    end

    def self.ConditionalsScore score
      score.conditionals
    end

    def self.OverallScore score
      score.overall
    end
end
