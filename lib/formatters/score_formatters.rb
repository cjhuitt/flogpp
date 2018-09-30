class ScoreFormatter
  def self.FormatWhole score
    return "%8d" % score
  end

  def self.FormatFloat score
    return "%8.1f" % score
  end
end

class AssignmentsScoreFormatter
  def self.Format score
    ScoreFormatter::FormatWhole(score.assignments) + "a"
  end

  def self.FormatAvg score
    ScoreFormatter::FormatFloat(score.assignments) + "a"
  end
end

class BranchesScoreFormatter
  def self.Format score
    ScoreFormatter::FormatWhole(score.branches) + "b"
  end

  def self.FormatAvg score
    ScoreFormatter::FormatFloat(score.branches) + "b"
  end
end

class ConditionalsScoreFormatter
  def self.Format score
    ScoreFormatter::FormatWhole(score.conditionals) + "c"
  end

  def self.FormatAvg score
    ScoreFormatter::FormatFloat(score.conditionals) + "c"
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
    ScoreFormatter::FormatFloat score.overall
  end

  def self.FormatAvg score
    ScoreFormatter::FormatFloat score.overall
  end
end
