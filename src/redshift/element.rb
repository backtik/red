class Red::MethodCompiler
  # 
  module Element
    # 
    def elem_alloc
      <<-END
        function elem_alloc(klass) {
          var elem = NEWOBJ();
          OBJSETUP(elem, klass, T_DATA);
          elem.ptr = 0;
          return elem;
        }
      END
    end
    
    def elem_children
      add_function :rb_dom_walk
      <<-END
        function elem_children(elem) {
          return rb_dom_walk(elem.ptr, 'nextSibling', 'firstChild', true);
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
    
    def elem_find
      add_function :rb_get_element_by_id_string, :rb_get_elements_array
      <<-END
        function elem_find(elem, str) {
          var element = elem.ptr;
          var string  = str.ptr;
          if (string.match(/^#[0-9a-zA-z_\\-]+$/)) { return rb_get_element_by_id_string(string, element); }
          return rb_get_elements_array(string, element);
        }
      END
    end
    
    # complete
    def elem_first_child
      add_function :rb_dom_walk
      <<-END
        function elem_first_child(elem) {
          return rb_dom_walk(elem.ptr, 'nextSibling', 'firstChild', false);
        }
      END
    end
    
    # INCOMPLETE
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
    def elem_last_child
      add_function :rb_dom_walk
      <<-END
        function elem_last_child(elem) {
          return rb_dom_walk(elem.ptr, 'previousSibling', 'lastChild', false);
        }
      END
    end
    
    # complete
    def elem_next_element
      add_function :rb_dom_walk
      <<-END
        function elem_next_element(elem) {
          return rb_dom_walk(elem.ptr, 'nextSibling', null, false);
        }
      END
    end
    
    # complete
    def elem_next_elements
      add_function :rb_dom_walk
      <<-END
        function elem_next_elements(elem) {
          return rb_dom_walk(elem.ptr, 'nextSibling', null, true);
        }
      END
    end
    
    # complete
    def elem_parent
      add_function :rb_dom_walk
      <<-END
        function elem_parent(elem) {
          return rb_dom_walk(elem.ptr, 'parentNode', null, false);
        }
      END
    end
    
    # complete
    def elem_parents
      add_function :rb_dom_walk
      <<-END
        function elem_parents(elem) {
          return rb_dom_walk(elem.ptr, 'parentNode', null, true);
        }
      END
    end
    
    # complete
    def elem_previous_element
      add_function :rb_dom_walk
      <<-END
        function elem_previous_element(elem) {
          return rb_dom_walk(elem.ptr, 'previousSibling', null, false);
        }
      END
    end
    
    # complete
    def elem_previous_elements
      add_function :rb_dom_walk
      <<-END
        function elem_previous_elements(elem) {
          return rb_dom_walk(elem.ptr, 'previousSibling', null, true);
        }
      END
    end
    
    # complete
    def elem_s_find
      add_function :rb_get_element_by_id_string, :rb_get_elements_array
      <<-END
        function elem_s_find(klass, str) {
          var string = str.ptr;
          if (string.match(/^#[0-9a-zA-z_\\-]+$/)) { return rb_get_element_by_id_string(string); }
          return rb_get_elements_array(string);
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
    def rb_get_element_by_id_string
      add_function :rb_element_wrapper
      <<-END
        function rb_get_element_by_id_string(name, scope) {
          return rb_element_wrapper(Sizzle(name, scope)[0]);
        }
      END
    end
    
    # complete
    def rb_get_elements_array
      add_function :rb_ary_new, :rb_ary_push, :rb_element_wrapper
      <<-END
        function rb_get_elements_array(string, scope) {
          var src = Sizzle(string, scope);
          var ary = rb_ary_new();
          for (var i = 0, l = src.length; i < l; i++) {
            rb_ary_push(ary, rb_element_wrapper(src[i]));
          }
          return ary;
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
      add_function :elem_alloc
      <<-END
        function rb_element_wrapper(element) {
          if (!element) { return Qnil; }
          var elem = elem_alloc(rb_cElement);
          elem.ptr = element;
          return elem;
        }
      END
    end
  end
end
