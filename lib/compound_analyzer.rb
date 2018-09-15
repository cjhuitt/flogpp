class CompoundAnalyzer

  def initialize _
    @snippets = []
    @assignments = 0
    @branches = 0
    @conditionals = 0
  end

  def assignments
    @assignments + @branches + @conditionals
  end

  def branches
    @assignments + @branches + @conditionals
  end

  def conditionals
    @assignments + @branches + @conditionals
  end

  def score
    assignments + branches + conditionals
  end
end
