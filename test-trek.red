Document.ready? do
  elem = Element.find('#div-element-1')
  puts elem.first_child
  puts elem.last_child
end