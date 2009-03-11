class CounterController < Controller
  def initialize
    @max_value = 10
    @min_value = 0
    @value = 5      # sets initial value
  end
  
  def can_increment
    @value < @max_value
  end
  
  def can_decrement
    @value > @min_value
  end
  
  def value
    @value
  end
end

class IncrementView < View
end

class DecrementView < View
end

class NumberDisplayView < View
end

Document.ready? do
  controller = CounterController.new
  i = IncrementView.new(Document['increase'])
  d = DecrementView.new(Document['decrease'])
  n = NumberDisplayView.new(Document['current_number'])
  
  i.bind(:enabled, controller, 'can_increment')
  d.bind(:enabled, controller, 'can_decrement')
  n.bind(:count, controller, 'value')
end