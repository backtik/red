p = proc do |*x|
  puts x.inspect
end

p.call(true, false, 1, 2, 3)
