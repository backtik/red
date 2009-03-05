class Red::MethodCompiler
  # complete
  def prop_aref
    add_function :elem_get_property
    <<-END
      function prop_aref(prop, name) {
        return elem_get_property(prop.element, name);
      }
    END
  end
  
  # complete
  def prop_aset
    add_function :elem_set_property
    <<-END
      function prop_aset(prop, name, value) {
        return elem_set_property(prop.element, name, value);
      }
    END
  end
  
  # complete
  def prop_delete
    add_function :elem_remove_property
    <<-END
      function prop_delete(prop, name) {
        return elem_remove_property(prop.element, name, value);
      }
    END
  end
  
  # complete
  def prop_element
    <<-END
      function prop_element(prop) {
        return prop.element;
      }
    END
  end
  
  # complete
  def prop_set_p
    add_function :elem_get_property
    <<-END
      function prop_set_p(prop, name) {
        var property = elem_get_property(prop.element, name);
        return RTEST(property) ? Qtrue : Qfalse;
      }
    END
  end
  
  # complete
  def prop_update
    add_function :elem_set_properties
    <<-END
      function prop_update(prop, hash) {
        elem_set_properties(prop.element, hash);
        return prop;
      }
    END
  end
end
