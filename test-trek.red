Document.ready? do
  elem = Element.find('#div-element-1')
  puts elem.parent
  # puts elem.parents
  puts elem.next_element
  # puts elem.next_elements
  puts elem.previous_element
  # puts elem.previous_elements
  puts elem.first_child
  puts elem.last_child
end