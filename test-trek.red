# class CounterController < Controller
#   def initialize
#     @size = 0
#   end
# end
# 
# class CounterView# < View
#   def initialize
#     @click_count = 0
#   end
# end

Document.ready? do
  c = Controller.new
  v = View.new(Element.new(:div))
  v.add_binding(:click_count, c, :size)
end