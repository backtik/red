class Red::MethodCompiler
  # complete
  def elem_add_class
    add_function :rb_add_element_class, :rb_id2name, :rb_to_id
    <<-END
      function elem_add_class(elem, name) {
        rb_add_element_class(elem.ptr, rb_id2name(rb_to_id(name)));
        return elem;
      }
    END
  end
  
  # complete
  def elem_add_classes
    add_function :rb_scan_args, :rb_add_element_class, :rb_id2name, :rb_to_id
    <<-END
      function elem_add_classes(argc, argv, elem) {
        if ((tmp = rb_scan_args(argc, argv, '*'))[0]) {
          var element = elem.ptr;
          var classes = tmp[1].ptr;
          for (var i = 0, l = classes.length; i < l; ++i) {
            rb_add_element_class(element, rb_id2name(rb_to_id(classes[i])));
          }
        }
        return elem;
      }
    END
  end
  
  # complete
  def elem_class_get
    add_function :rb_str_new
    <<-END
      function elem_class_get(elem) {
        return rb_str_new(elem.ptr.className);
      }
    END
  end
  
  # .class= fails because attrasgn node isn't implemented
  def elem_class_set
    add_function :rb_check_type
    <<-END
      function elem_class_set(elem, str) {
        Check_Type(str);
        elem.ptr.className = str.ptr;
        return str;
      }
    END
  end
  
  # complete
  def elem_classes_get
    add_function :rb_obj_alloc
    <<-END
      function elem_classes_get(elem) {
        if (!elem.classes) {
          var classes = rb_obj_alloc(rb_cClasses);
          classes.element = elem;
          elem.classes = classes;
        }
        return elem.classes;
      }
    END
  end
  
  # .classes= fails because attrasgn node isn't implemented
  def elem_classes_set
    add_function :rb_id2name, :rb_to_id
    <<-END
      function elem_classes_set(elem, ary) {
        var src = ary.ptr;
        var dest = [];
        for (var i = 0, l = src.length; i < l; ++i) {
          dest.push(rb_id2name(rb_to_id(src[i])));
        }
        elem.ptr.className = dest.join(' ');
      }
    END
  end
  
  # complete
  def elem_clear_styles
    <<-END
      function elem_clear_styles(elem) {
        elem.ptr.style.cssText = '';
        return elem;
      }
    END
  end
  
  # complete
  def elem_get_property
    add_function :rb_id2name, :rb_to_id, :rb_boolean_property, :rb_str_new
    <<-END
      function elem_get_property(elem, name) {
        var element = elem.ptr;
        var attribute = rb_id2name(rb_to_id(name));
        var bool = rb_boolean_property(attribute);
        var key = { 'class':'className', 'for':'htmlFor' }[attribute] || bool;
        var value = (key) ? (element[key] || 0) : (element.getAttribute(attribute, 2) || 0);
        return (value) ? (bool ? Qtrue : rb_str_new(value)) : (bool ? Qfalse : Qnil);
      }
    END
  end
  
  # complete
  def elem_get_style
    add_function :rb_camelize_name, :rb_str_new
    <<-END
      function elem_get_style(elem, name) {
        return typeof(retval = elem.ptr.style[rb_camelize_name(name)]) == 'undefined' ? Qnil : rb_str_new(retval);
      }
    END
  end
  
  # complete
  def elem_has_class_p
    add_function :rb_id2name, :rb_to_id, :rb_element_has_class_p
    <<-END
      function elem_has_class_p(elem, name) {
        return (rb_element_has_class_p(elem.ptr, rb_id2name(rb_to_id(name)))) ? Qtrue : Qfalse;
      }
    END
  end
  
  # complete
  def elem_html_get
    add_function :rb_str_new
    <<-END
      function elem_html_get(elem) {
        return rb_str_new(elem.ptr.innerHtml);
      }
    END
  end
  
  # .html= fails because attrasgn node isn't implemented
  def elem_html_set
    <<-END
      function elem_html(elem, str) {
        elem.ptr.innerHtml = str.ptr;
        return str;
      }
    END
  end
  
  # complete
  def elem_id
    add_function :rb_str_new
    <<-END
      function elem_id(elem) {
        var id = elem.ptr.id;
        return id ? rb_str_new(id) : Qnil;
      }
    END
  end
  
  # complete
  def elem_properties
    add_function :rb_obj_alloc
    <<-END
      function elem_properties(elem) {
        if (!elem.properties) {
          var properties = rb_obj_alloc(rb_cProperties);
          properties.element = elem;
          elem.properties = properties;
        }
        return elem.properties;
      }
    END
  end
  
  # complete
  def elem_remove_class
    add_function :rb_id2name, :rb_to_id, :rb_remove_element_class
    <<-END
      function elem_remove_class(elem, name) {
        rb_remove_element_class(elem.ptr, rb_id2name(rb_to_id(name)));
        return elem;
      }
    END
  end
  
  # complete
  def elem_remove_classes
    add_function :rb_remove_element_class, :rb_scan_args, :rb_to_id, :rb_id2name
    <<-END
      function elem_remove_classes(argc, argv, elem) {
        if ((tmp = rb_scan_args(argc, argv, '*'))[0]) {
          var element = elem.ptr;
          var classes = tmp[1].ptr;
          for (var i = 0, l = classes.length; i < l; ++i) {
            rb_remove_element_class(element, rb_id2name(rb_to_id(classes[i])));
          }
        }
        return elem;
      }
    END
  end
  
  # complete
  def elem_remove_property
    add_function :rb_id2name, :rb_to_id, :rb_remove_element_property
    <<-END
      function elem_remove_property(elem, name) {
        rb_remove_element_property(elem.ptr, rb_id2name(rb_to_id(name)));
        return elem;
      }
    END
  end
  
  # complete
  def elem_remove_properties
    add_function :rb_id2name, :rb_to_id, :rb_remove_element_property, :rb_scan_args
    <<-END
      function elem_remove_properties(argc, argv, elem) {
        if ((tmp = rb_scan_args(argc, argv, '*'))[0]) {
          var element = elem.ptr;
          var properties = tmp[1].ptr;
          for (var i = 0, l = properties.length; i < l; ++i) {
            rb_remove_element_property(element, rb_id2name(rb_to_id(properties[i])));
          }
        }
        return elem;
      }
    END
  end
  
  # complete
  def elem_remove_style
    add_function :rb_camelize_name
    <<-END
      function elem_remove_style(elem, name) {
        elem.ptr.style[rb_camelize_name(name)] = null;
        return elem;
      }
    END
  end
  
  # complete
  def elem_remove_styles
    add_function :rb_camelize_name, :rb_scan_args
    <<-END
      function elem_remove_styles(argc, argv, elem) {
        if ((tmp = rb_scan_args(argc, argv, '*'))[0]) {
          var element = elem.ptr;
          var styles = tmp[1].ptr;
          for (var i = 0, l = styles.length; i < l; ++i) {
            element.style[rb_camelize_name(styles[i])] = null;
          }
        }
        return elem;
      }
    END
  end
  
  # complete
  def elem_set_opacity
    add_function :rb_scan_args, :rb_funcall, :rb_intern, :rb_set_element_opacity
    add_method :to_int
    <<-END
      function elem_set_opacity(argc, argv, elem) {
        var tmp = rb_scan_args(argc, argv, '11');
        var element = elem.ptr;
        var percent = FIX2LONG(rb_funcall(tmp[1], rb_intern('to_int'), 0));
        if ((tmp[0] > 1) && !RTEST(tmp[2])) {
          if (percent === 0) {
            if (element.style.visibility != 'hidden') { element.style.visibility = 'hidden'; }
          } else {
            if (element.style.visibility != 'visible') { element.style.visibility = 'visible'; }
          }
        }
        rb_set_element_opacity(element, percent);
        return elem;
      }
    END
  end
  
  # complete
  def elem_set_properties
    add_function :rb_check_type, :rb_set_element_property, :rb_id2name,
                 :rb_to_id
    <<-END
      function elem_set_properties(elem, hash) {
        Check_Type(hash, T_HASH);
        var element = elem.ptr;
        var tbl = hash.tbl;
        for (var x in tbl) {
          rb_set_element_property(element, rb_id2name(rb_to_id(x)), tbl[x]);
        }
        return elem;
      }
    END
  end
  
  # complete
  def elem_set_property
    add_function :rb_id2name, :rb_to_id, :rb_set_element_property
    <<-END
      function elem_set_property(elem, name, val) {
        rb_set_element_property(elem.ptr, rb_id2name(rb_to_id(name)), val);
        return elem;
      }
    END
  end
  
  # complete
  def elem_set_style
    add_function :rb_camelize_name, :rb_set_element_style
    <<-END
      function elem_set_style(elem, name, val) {
        rb_set_element_style(elem.ptr, rb_camelize_name(name), val);
        return elem;
      }
    END
  end
  
  # complete
  def elem_set_styles
    add_function :rb_check_type, :rb_set_element_style, :rb_camelize_name
    <<-END
      function elem_set_styles(elem, hash) {
        Check_Type(hash, T_HASH);
        var element = elem.ptr;
        var tbl = hash.tbl;
        for (var x in tbl) {
          rb_set_element_style(element, rb_camelize_name(x), tbl[x]);
        }
        return elem;
      }
    END
  end
  
  # complete
  def elem_style_get
    add_function :rb_str_new
    <<-END
      function elem_style_get(elem) {
        return rb_str_new(elem.ptr.style.cssText);
      }
    END
  end
  
  # complete
  def elem_style_set
    add_function :rb_check_type
    <<-END
      function elem_style_set(elem, str) {
        Check_Type(str, T_STRING);
        elem.ptr.style.cssText = str.ptr;
        return str;
      }
    END
  end
  
  # complete
  def elem_styles
    add_function :rb_obj_alloc
    <<-END
      function elem_styles(elem) {
        if (!elem.styles) {
          var styles = rb_obj_alloc(rb_cStyles);
          styles.element = elem;
          elem.styles = styles;
        }
        return elem.styles;
      }
    END
  end
  
  # complete
  def elem_text_get
    add_function :rb_str_new
    <<-END
      function elem_text_get(elem) {
        var text = (ruby_engine_name.ptr == 'trident') ? elem.ptr.innerText : elem.ptr.textContent;
        return rb_str_new(text);
      }
    END
  end
  
  # complete
  def elem_text_set
    add_function :rb_check_type
    <<-END
      function elem_text_set(elem, str) {
        Check_Type(str, T_STRING);
        if (ruby_engine_name.ptr == 'trident') {
          elem.ptr.innerText = str.ptr;
        } else {
          elem.ptr.textContent = str.ptr;
        }
        return str;
      }
    END
  end
  
  # complete
  def elem_toggle_class
    add_function :rb_id2name, :rb_to_id, :rb_element_has_class_p,
                 :rb_remove_element_class, :rb_add_element_class
    <<-END
      function elem_toggle_class(elem, name) {
        var element = elem.ptr;
        var classname = rb_id2name(rb_to_id(name));
        if (rb_element_has_class_p(element, classname)) {
          rb_remove_element_class(element, classname);
        } else {
          rb_add_element_class(element, classname);
        }
        return elem;
      }
    END
  end
  
  # complete
  def rb_add_element_class
    add_function :rb_element_has_class_p
    <<-END
      function rb_add_element_class(element, classname) {
        if (!rb_element_has_class_p(element, classname)) {
          var classes = element.className;
          element.className = (classes.length > 0) ? (classes + ' ' + classname) : classname;
        }
      }
    END
  end
  
  # complete
  def rb_boolean_property
    <<-END
      function rb_boolean_property(name) {
        return { 'checked': 'checked', 'declare': 'declare', 'defer': 'defer', 'disabled': 'disabled', 'ismap': 'ismap', 'multiple': 'multiple', 'noresize': 'noresize', 'noshade': 'noshade', 'readonly': 'readonly', 'selected': 'selected' }[name] || 0;
      }
    END
  end
  
  # complete
  def rb_camelize_name
    add_function :rb_id2name, :rb_to_id
    <<-END
      function rb_camelize_name(name) {
        return rb_id2name(rb_to_id(name)).replace(/[_-]\\D/g, function(match) {return match.charAt(1).toUpperCase(); });
      }
    END
  end
  
  # complete
  def rb_element_has_class_p
    <<-END
      function rb_element_has_class_p(element, classname) {
        var classes = ' ' + element.className + ' ';
        var match = ' ' + classname + ' ';
        return (classes.indexOf(match) > -1);
      }
    END
  end
  
  # complete
  def rb_remove_element_class
    <<-END
      function rb_remove_element_class(element, classname) {
        var rxp = new(RegExp)('(^|\\\\s)' + classname + '(?:\\\\s|$)');
        element.className = element.className.replace(rxp,'$1');
      }
    END
  end
  
  # complete
  def rb_remove_element_property
    add_function :rb_boolean_property
    <<-END
      function rb_remove_element_property(element, attribute) {
        var bool = rb_boolean_property(attribute);
        var key = { 'class':'className', 'for':'htmlFor' }[attribute] || bool;
        if (key) {
          element[key] = (bool) ? false : '';
        } else {
          element.removeAttribute(attribute);
        }
      }
    END
  end
  
  # complete
  def rb_set_element_opacity
    <<-END
      function rb_set_element_opacity(element, percent) {
        if (!(element.currentStyle && element.currentStyle.hasLayout)) { element.style.zoom = 1; }
        if (ruby_engine_name.ptr == 'trident') {
          element.style.filter = (percent == 100) ? '' : 'alpha(opacity=' + percent + ')';
        } else {
          element.style.opacity = (percent / 100);
        }
      }
    END
  end
  
  # complete
  def rb_set_element_property
    add_function :rb_intern, :rb_funcall, :rb_boolean_property
    add_method :to_s
    <<-END
      function rb_set_element_property(element, attribute, val) {
        var string_value = rb_funcall(val, rb_intern('to_s'), 0).ptr;
        var bool = rb_boolean_property(attribute);
        var key = { 'class':'className', 'for':'htmlFor' }[attribute] || bool;
        if (key) {
          element[key] = (bool) ? RTEST(val) : string_value;
        } else {
          element.setAttribute(attribute, string_value);
        }
      }
    END
  end
  
  # CHECK ROUNDING OF NUMERIC VALUES
  def rb_set_element_style
    add_function :rb_set_element_opacity, :rb_funcall, :rb_intern
    add_method :to_s, :to_int
    <<-END
      function rb_set_element_style(element, attribute, val) {
        if (attribute == 'float') { attribute = (ruby_engine_name == 'trident') ? 'styleFloat' : 'cssFloat'; }
        if (attribute == 'opacity') { return rb_set_element_opacity(element, FIX2LONG(rb_funcall(val, rb_intern('to_int'), 0))); }
        var string_value = rb_funcall(val, rb_intern('to_s'), 0).ptr;
        element.style[attribute] = string_value;
      }
    END
  end
end
