class Score
  attr_reader :assignments
  attr_reader :branches
  attr_reader :conditionals

  def initialize a=0, b=0, c=0
    @assignments = a
    @branches = b
    @conditionals = c
  end

  def overall
    overall = @assignments**2
    overall += @branches**2
    overall += @conditionals**2
    Math.sqrt overall
  end

  def + other
    a = @assignments + other.assignments
    b = @branches + other.branches
    c = @conditionals + other.conditionals
    Score.new a, b, c
  end

  def / divisor
    a = @assignments / divisor
    b = @branches / divisor
    c = @conditionals / divisor
    Score.new a, b, c
  end

  def to_s
    "(#{@assignments}, #{@branches}, #{@conditionals})"
  end
end
