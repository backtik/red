class Red::MethodCompiler
  # 
  def elem_find
    add_function :rb_get_element_by_id_string
    <<-END
      function elem_find(klass, str) {
        return rb_get_element_by_id_string(str.ptr);
      }
    END
  end
  
  # complete
  def elem_eq
    <<-END
      function elem_eq(elem, elem2) {
        return (elem.ptr === elem2.ptr) ? Qtrue : Qfalse;
      }
    END
  end
  
  # complete
  def elem_eql
    <<-END
      function elem_eql(elem, elem2) {
        return (elem.ptr === elem2.ptr) ? Qtrue : Qfalse;
      }
    END
  end
  
  # complete
  def elem_height
    add_function :rb_element_dimensions
    <<-END
      function elem_height(elem) {
        return INT2FIX(rb_element_dimensions(elem.ptr)[1]);
      }
    END
  end 
  
  # INCOMPLETE - add hash of attributes/properties to initialize
  def elem_initialize
    add_function :rb_id2name
    <<-END
      function elem_initialize(elem, tag) {
        var name = rb_id2name(SYM2ID(tag));
        var element = document.createElement(name);
        elem.ptr = element;
        return Qnil;
      }
    END
  end
  
  # complete
  def elem_insert
    add_function :rb_scan_args, :rb_insert_bottom_child, :rb_id2name,
                 :rb_check_type, :rb_insert_next_sibling,
                 :rb_insert_previous_sibling, :rb_insert_top_child,
                 :rb_raise
    <<-END
      function elem_insert(argc, argv, elem) {
        var tmp = rb_scan_args(argc, argv, "11");
        if (tmp[0] == 1) {
          rb_insert_bottom_child(elem.ptr, tmp[1].ptr);
        } else {
          var location = rb_to_id(tmp[2]);
          switch (location) {
            case id_after:
              rb_insert_next_sibling(elem.ptr, tmp[1].ptr);
              break;
            case id_before:
              rb_insert_previous_sibling(elem.ptr, tmp[1].ptr);
              break;
            case id_bottom:
            case id_inside:
              rb_insert_bottom_child(elem.ptr, tmp[1].ptr);
              break;
            case id_top:
              rb_insert_top_child(elem.ptr, tmp[1].ptr);
              break;
            default:
              rb_raise(rb_eArgError, "%s is not a valid element location", rb_id2name(location));
          }
        }
        return elem;
      }
    END
  end
  
  # complete
  def elem_left
    add_function :rb_element_position
    <<-END
      function elem_left(elem) {
        return INT2FIX(rb_element_position(elem.ptr)[0]);
      }
    END
  end
  
  # complete
  def elem_scroll_height
    add_function :rb_element_is_body_p, :doc_scroll_height
    <<-END
      function elem_scroll_height(elem) {
        var element = elem.ptr;
        if (rb_element_is_body_p(element)) { return doc_scroll_height(); }
        return INT2FIX(element.scrollHeight);
      }
    END
  end 
  
  # complete
  def elem_scroll_left
    add_function :rb_element_is_body_p, :doc_scroll_left
    <<-END
      function elem_scroll_left(elem) {
        var element = elem.ptr;
        if (rb_element_is_body_p(element)) { return doc_scroll_left(); }
        return INT2FIX(element.scrollLeft);
      }
    END
  end 
  
  # complete
  def elem_scroll_to
    <<-END
      function elem_scroll_to(elem, x, y) {
        var element = elem.ptr;
        element.scrollLeft = FIX2LONG(x);
        element.scrollTop = FIX2LONG(y);
        return elem;
      }
    END
  end
  
  # complete
  def elem_scroll_top
    add_function :rb_element_is_body_p, :doc_scroll_top
    <<-END
      function elem_scroll_top(elem) {
        var element = elem.ptr;
        if (rb_element_is_body_p(element)) { return doc_scroll_top(); }
        return INT2FIX(element.scrollTop);
      }
    END
  end 
  
  # complete
  def elem_scroll_width
    add_function :rb_element_is_body_p, :doc_scroll_width
    <<-END
      function elem_scroll_width(elem) {
        var element = elem.ptr;
        if (rb_element_is_body_p(element)) { return doc_scroll_width(); }
        return INT2FIX(element.scrollWidth);
      }
    END
  end 
  
  # complete
  def elem_to_s
    add_function :rb_str_new
    <<-END
      function elem_to_s(elem) {
        var element = elem.ptr;
        var tag = element.tagName.toUpperCase();
        var id = (element.id) ? (' id="' + element.id + '"') : '';
        var class = (element.className) ? (' class="' + element.className + '"') : '';
        var str = rb_str_new("#<Element: " + tag + id + class + ">");
        if (OBJ_TAINTED(elem)) { OBJ_TAINT(elem); }
        return str;
      }
    END
  end
  
  # complete
  def elem_top
    add_function :rb_element_position
    <<-END
      function elem_top(elem) {
        return INT2FIX(rb_element_position(elem.ptr)[1]);
      }
    END
  end 
  
  # complete
  def elem_width
    add_function :rb_element_dimensions
    <<-END
      function elem_width(elem) {
        return INT2FIX(rb_element_dimensions(elem.ptr)[0]);
      }
    END
  end 
  
  # complete
  def rb_element_border_box_p
    add_function :rb_element_style_string
    <<-END
      function rb_element_border_box_p(element) {
        return rb_element_style_string(element, '-moz-box-sizing') == 'border-box';
      }
    END
  end
  
  # complete
  def rb_element_border_left
    add_function :rb_element_style_string
    <<-END
      function rb_element_border_left(element) {
        return parseInt(rb_element_style_string(element, 'border-left-width')) || 0;
      }
    END
  end
  
  # complete
  def rb_element_border_top
    add_function :rb_element_style_string
    <<-END
      function rb_element_border_top(element) {
        return parseInt(rb_element_style_string(element, 'border-top-width')) || 0;
      }
    END
  end
  
  # complete
  def rb_element_is_body_p
    <<-END
      function rb_element_is_body_p(element) {
        return (/^(?:body|html)$/i).test(element.tagName);
      }
    END
  end
  
  # complete
  def rb_element_offsets
    add_function :rb_element_is_body_p, :rb_element_border_left, :rb_element_border_top, :rb_element_style_string, :rb_element_border_box_p
    <<-END
      function rb_element_offsets(element) {
        var x = 0;
        var y = 0;
        var engine = ruby_engine_name.ptr;
        var gecko_p = (engine == 'gecko');
        if (rb_element_is_body_p(element)) { return [x, y]; }
        if (engine == 'trident') {
          var bound = element.getBoundingClientRect();
          var html = document.documentElement;
          x = bound.left + html.scrollLeft - html.clientLeft;
          y = bound.top + html.scrollTop - html.clientTop;
        } else {
          var tmp = element;
          while (tmp && !rb_element_is_body_p(tmp)) {
            x += tmp.offsetLeft;
            y += tmp.offsetTop;
            if (gecko_p) {
              if (!rb_element_border_box_p(tmp)) {
                x += rb_element_border_left(tmp);
                y += rb_element_border_top(tmp);
              }
              var parent = tmp.parentNode;
              if (parent && rb_element_style_string(parent, 'overflow') != 'visible') {
                x += rb_element_border_left(parent);
                y += rb_element_border_top(parent);
              }
            } else if ((tmp != element) && (engine == 'webkit')) {
              x += rb_element_border_left(tmp);
              y += rb_element_border_top(tmp);
            }
            tmp = tmp.offsetParent;
          }
          if (gecko_p && !rb_element_border_box_p(element)) {
            x -= rb_element_border_left(element);
            y -= rb_element_border_top(element);
          }
        }
        return [x, y];
      }
    END
  end
  
  # complete
  def rb_element_position
    add_function :rb_element_is_body_p, :rb_element_offsets, :rb_element_scrolls
    <<-END
      function rb_element_position(element) {
        var x = 0;
        var y = 0;
        if (!rb_element_is_body_p(element)) {
          var relative_position = [0, 0]; // add option to ask for "left"/"top" relative to another element
          x = rb_element_offsets(element)[0] - rb_element_scrolls(element)[0] - relative_position[0];
          y = rb_element_offsets(element)[1] - rb_element_scrolls(element)[1] - relative_position[1];
        }
        return [x, y];
      }
    END
  end
  
  # complete
  def rb_element_scrolls
    add_function :rb_element_is_body_p
    <<-END
      function rb_element_scrolls(element) {
        var x = 0;
        var y = 0;
        while (element && !rb_element_is_body_p(element)) {
          x += element.scrollLeft;
          y += element.scrollTop;
          element = element.parentNode;
        }
        return [x, y];
      }
    END
  end
  
  # complete
  def rb_element_dimensions
    <<-END
      function rb_element_dimensions(element) {
        if (rb_element_is_body_p(element)) { return rb_viewport_dimensions(); }
        return [element.offsetWidth, element.offsetHeight];
      }
    END
  end
  
  # complete
  def rb_element_style_string
    <<-END
      function rb_element_style_string(element, name) {
        if (element.currentStyle) {
          return element.currentStyle[name.replace(/[_-]\\D/g, function(match) { return match.charAt(1).toUpperCase(); })];
        };
        var computed = document.defaultView.getComputedStyle(element, null);
        return (computed) ? computed.getPropertyValue([name.replace(/[A-Z]/g, function(match) { return ('-' + match.charAt(0).toLowerCase()); })]) : 0;
      }
    END
  end
  
  # complete
  def rb_get_element_by_id_string
    add_function :rb_element_wrapper
    <<-END
      function rb_get_element_by_id_string(name) {
        return rb_element_wrapper(document.getElementById(name));
      }
    END
  end
  
  # complete
  def rb_insert_bottom_child
    <<-END
      function rb_insert_bottom_child(element, inserted) {
        element.appendChild(inserted);
      }
    END
  end
  
  # complete
  def rb_insert_top_child
    <<-END
      function rb_insert_top_child(element, inserted) {
        var first = element.firstChild;
        if (first) { element.insertBefore(inserted, first); } else { element.appendChild(inserted); }
      }
    END
  end
  
  # complete
  def rb_insert_next_sibling
    <<-END
      function rb_insert_next_sibling(element, inserted) {
        var pN = element.parentNode;
        if (pN) {
          var nS = element.nextSibling;
          if (nS) { pN.insertBefore(inserted, nS); } else { pN.appendChild(inserted); }
        }
      }
    END
  end
  
  # complete
  def rb_insert_previous_sibling
    <<-END
      function rb_insert_previous_sibling(element, inserted) {
        var pN = element.parentNode;
        if (pN) { pN.insertBefore(inserted, element); }
      }
    END
  end
  
  # complete
  def rb_element_wrapper
    add_function :rb_obj_alloc
    <<-END
      function rb_element_wrapper(element) {
        if (!element) { return Qnil; }
        var elem = rb_obj_alloc(rb_cElement);
        elem.ptr = element;
        return elem;
      }
    END
  end
end
