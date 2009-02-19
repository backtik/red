#class Foo
#  a = 1
#  def foo(&block)
#    a = 2
#    puts "two:   #{a}"
#    return block.call(3)
#  end
#  puts "one:   #{a}"
#  
#  def method_missing(name)
#    puts "you used nonexistent method :#{name}"
#  end
#end
#
#a = Foo.new.foo do |a|
#  puts "three: #{a}"
#  a = 4
#  puts "four:  #{a}"
#  Foo.new.foo do |a|
#    puts "three: #{a}"
#    a = 5
#    puts "five:  #{a}"
#  end
#  puts "five:  #{a}"
#  6
#end
#puts "six:   #{a}"

Document.ready? do
  elem1 = Element.find('div-element-1')
  elem2 = Element.find('div-element-2')
  UserEvent.define(:alt_click, :base => 'click', :condition => proc { |event| event.alt? })
  elem1.listen(:alt_click) { |x| puts x; 1 }
# elem1.insert(elem2, 'inside')
end
