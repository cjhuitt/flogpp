class Range
  def initialize(full: false, percent: nil, number: nil)
    @full = full
    @percent = percent
    @number = number
  end

  def count size
    return size if full?
    return 0 if size == 0

    possibilities = [1]
    possibilities << (size * 0.1).round if !@number and !@percent
    possibilities << (size * (@percent/100.0)).round if @percent
    possibilities << @number if @number
    [possibilities.max, size].min
  end

  private
    def full?
      @full
    end
end
