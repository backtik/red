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


class Mush
  def yell
    @foo = {:a => 1}
    @foo[:b] = @foo
    puts @foo.inspect
    puts ""
    puts @foo[:b].inspect
    puts ""
    puts @foo[:b][:b].inspect
  end
end
Enumerable::Enumerator.new(Mush.new, :yell).each { true }
