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
  req = Request.new(:url => 'http://localhost:9292/ruby.html')
  req.execute
  req.upon(:response) { |response| puts response.text }
end
