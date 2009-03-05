class Red::MethodCompiler
  # complete
  def styles_aref
    add_function :elem_get_style
    <<-END
      function styles_aref(styles, name) {
        return elem_get_style(styles.element, name);
      }
    END
  end
  
  # complete
  def styles_aset
    add_function :elem_set_style
    <<-END
      function styles_aset(styles, name, value) {
        return elem_set_style(styles.element, name, value);
      }
    END
  end
  
  # complete
  def styles_clear
    add_function :elem_clear_styles
    <<-END
      function styles_clear(styles) {
        elem_clear_styles(styles.element);
        return styles;
      }
    END
  end
  
  # complete
  def styles_delete
    add_function :elem_remove_style
    <<-END
      function styles_delete(styles, name) {
        return elem_remove_style(styles.element, name);
      }
    END
  end
  
  # complete
  def styles_element
    <<-END
      function styles_element(styles) {
        return styles.element;
      }
    END
  end
  
  # complete
  def styles_set_p
    add_function :elem_get_style
    <<-END
      function styles_set_p(styles, name) {
        var style = elem_get_style(styles.element, name);
        return RTEST(style) ? Qtrue : Qfalse;
      }
    END
  end
  
  # complete
  def styles_update
    add_function :elem_set_styles
    <<-END
      function styles_update(styles, hash) {
        elem_set_styles(styles.element, hash);
        return styles;
      }
    END
  end
end