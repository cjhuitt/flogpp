require_relative 'cleaners/cleaners'

class CleanerCollection
  def initialize cleaners
    @cleaners = cleaners
  end

  # Remove unnecessary complications, leaving the structure for analysis
  def clean code
    cleaned = code
    @cleaners.each { |c| cleaned = c.clean cleaned }
    cleaned
  end
end
