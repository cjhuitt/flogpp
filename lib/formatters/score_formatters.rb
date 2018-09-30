class ScoreFormatter
  def self.Format score
    return "%8d" % score
  end

  def self.FormatAvg score
    return "%8.1f" % score
  end
end

class AssignmentsScoreFormatter
  def self.Format score
    ScoreFormatter::Format(score.assignments) + "a"
  end

  def self.FormatAvg score
    ScoreFormatter::FormatAvg(score.assignments) + "a"
  end
end

class BranchesScoreFormatter
  def self.Format score
    ScoreFormatter::Format(score.branches) + "b"
  end

  def self.FormatAvg score
    ScoreFormatter::FormatAvg(score.branches) + "b"
  end
end

class ConditionalsScoreFormatter
  def self.Format score
    ScoreFormatter::Format(score.conditionals) + "c"
  end

  def self.FormatAvg score
    ScoreFormatter::FormatAvg(score.conditionals) + "c"
  end
end

class DetailsScoreFormatter
  def self.Format score
    "    (%6d, %6d, %6d)" % [score.assignments, score.branches, score.conditionals]
  end

  def self.FormatAvg score
    "    (%6.1f, %6.1f, %6.1f)" % [score.assignments, score.branches, score.conditionals]
  end
end

class OverallScoreFormatter
  def self.Format score
    ScoreFormatter::Format score.overall
  end

  def self.FormatAvg score
    ScoreFormatter::FormatAvg score.overall
  end
end
