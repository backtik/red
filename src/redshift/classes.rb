class Red::MethodCompiler
  # complete
  def classes_append
    add_function :elem_add_class
    <<-END
      function classes_append(classes, name) {
        elem_add_class(classes.element, name);
        return classes;
      }
    END
  end
  
  # complete
  def classes_element
    <<-END
      function classes_element(classes) {
        return classes.element;
      }
    END
  end
  
  # complete
  def classes_include_p
    add_function :elem_has_class_p
    <<-END
      function classes_include_p(classes, name) {
        return elem_has_class_p(classes.element, name);
      }
    END
  end
  
  # complete
  def classes_toggle
    add_function :elem_toggle_class
    <<-END
      function classes_toggle(classes, name) {
        return elem_toggle_class(classes.element, name);
      }
    END
  end
end
