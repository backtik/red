class CounterController < Controller
  attr_accessor :increment_view, :decrement_view, :count_view # "outlets"
  
  def initialize
    @max_value = 10
    @min_value = 0
    @value = 5
  end
  
  def can_increment
    @value < @max_value
  end
  
  def can_decrement
    @value > @min_value
  end
end

class IncrementView < View
end

class DecrementView < View
end

class NumberDisplayView < View

end

Document.ready? do
  c = CounterController.new
  iv = IncrementView.new(Document['#increase'])
  dv = DecrementView.new(Document['#decrease'])
  nv = NumberDisplayView.new(Document['#current_number'])
end