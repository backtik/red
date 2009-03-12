Document.ready? do
  elem1 = Element.find('#div-element-1')
  elem2 = Document['#div-element-1']
  puts "match" if elem1 == elem2
  puts elem1
  puts elem2
  
  # puts elem1.find('.f').size
  
  # puts elem.parent
  # puts elem.parents
  # puts elem.next_element
  # puts elem.next_elements
  # puts elem.previous_element
  # puts elem.previous_elements
  # puts elem.first_child
  # puts elem.last_child
end