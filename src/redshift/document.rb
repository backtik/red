class Red::MethodCompiler
  # EMPTY
  def doc_aref
    <<-END
      function doc_aref(argc, argv, doc) {}
    END
  end
  
  # complete
  def doc_body
    add_function :rb_element_wrapper
    <<-END
      function doc_body() {
        return rb_element_wrapper(document.body);
      }
    END
  end
  
  # complete
  def doc_document
    <<-END
      function doc_document() {
        return rb_mDocument;
      }
    END
  end
  
  # complete
  def doc_execute_js
    add_function :rb_check_type, :rb_doc_exec_js
    <<-END
      function doc_execute_js(doc, str) {
        Check_Type(str, T_STRING);
        rb_doc_exec_js(str.ptr);
        return str;
      }
    END
  end
  
  # complete
  def doc_head
    <<-END
      function doc_head() {
        return rb_element_wrapper(document.head);
      }
    END
  end
  
  # complete
  def doc_height
    add_function :rb_viewport_dimensions
    <<-END
      function doc_height(doc) {
        return INT2FIX(rb_viewport_dimensions(doc)[1]);
      }
    END
  end
  
  # complete
  def doc_html
    <<-END
      function doc_html() {
        return rb_element_wrapper(document.html);
      }
    END
  end
  
  # complete
  def doc_left
    <<-END
      function doc_left(doc) {
        return INT2FIX(0);
      }
    END
  end
  
  # INCOMPLETE
  def doc_ready_p
    add_function :rb_block_proc, :rb_proc_call, :rb_ary_new
    <<-END
      function doc_ready_p() {
        var bvar = rb_block_proc();
        var fn = function() { rb_proc_call(bvar, rb_ary_new()); };
        document.addEventListener('DOMContentLoaded', fn, false);
        return Qnil;
      }
    END
  end
  
  # complete
  def doc_scroll_height
    add_function :rb_compatibility_element, :rb_viewport_dimensions
    <<-END
      function doc_scroll_height(doc) {
        return INT2FIX(Math.max(rb_compatibility_element().scrollHeight, rb_viewport_dimensions()[1]));
      }
    END
  end
  
  # complete
  def doc_scroll_left
    add_function :rb_compatibility_element
    <<-END
      function doc_scroll_left(doc) {
        return INT2FIX(window.pageXOffset || rb_compatibility_element().scrollLeft);
      }
    END
  end
  
  # complete
  def doc_scroll_to
    add_function :rb_compatibility_element
    <<-END
      function doc_scroll_to(doc, x, y) {
        var element = rb_compatibility_element();
        element.scrollLeft = FIX2LONG(x);
        element.scrollTop = FIX2LONG(y);
        return doc;
      }
    END
  end
  
  # complete
  def doc_scroll_top
    add_function :rb_compatibility_element
    <<-END
      function doc_scroll_top(doc) {
        return INT2FIX(window.pageYOffset || rb_compatibility_element().scrollTop);
      }
    END
  end
  
  # complete
  def doc_scroll_width
    add_function :rb_compatibility_element, :rb_viewport_dimensions
    <<-END
      function doc_scroll_width(doc) {
        return INT2FIX(Math.max(rb_compatibility_element().scrollWidth, rb_viewport_dimensions()[0]));
      }
    END
  end
  
  # complete
  def doc_title
    add_function :rb_str_new
    <<-END
      function doc_title() {
        return rb_str_new(document.title);
      }
    END
  end
  
  # complete
  def doc_top
    <<-END
      function doc_top(doc) {
        return INT2FIX(0);
      }
    END
  end
  
  # EMPTY
  def doc_walk
    <<-END
      function doc_walk() {}
    END
  end
  
  # complete
  def doc_width
    add_function :rb_viewport_dimensions
    <<-END
      function doc_width(doc) {
        return INT2FIX(rb_viewport_dimensions(doc)[0]);
      }
    END
  end
  
  # complete
  def doc_window
    <<-END
      function doc_window() {
        return rb_mWindow;
      }
    END
  end
  
  # complete
  def rb_compatibility_element
    <<-END
      function rb_compatibility_element(doc) {
        return (!document.compatMode || (document.compatMode == 'CSS1Compat')) ? document.html : document.body;
      }
    END
  end
  
  # complete
  def rb_doc_exec_js
    <<-END
      function rb_doc_exec_js(string) {
        if (window.execScript) {
          window.execScript(string);
        } else {
          var script = document.createElement('script');
          script.setAttribute('type','text/javascript');
          script.text = string;
          document.head.appendChild(script);
          document.head.removeChild(script);
        }
        return string;
      }
    END
  end
  
  def rb_dom_walk
    add_function :rb_ary_new, :rb_ary_push, :rb_element_wrapper
    <<-END
      function rb_dom_walk(fromElement, path, startRelation, allBool) {
        var el = fromElement[startRelation || path], ary = rb_ary_new();
        while (el) {
          if (el.nodeType == 1) {
            if (!allBool) { return rb_element_wrapper(el); }
            rb_ary_push(ary, rb_element_wrapper(el));
          }
          el = el[path];
        }
        return allBool ? ary : Qnil;
      }
    END
  end
  
  # complete
  def rb_viewport_dimensions
    add_function :rb_compatibility_element
    <<-END
      function rb_viewport_dimensions(doc) {
        switch (ruby_engine_name) {
          case 'presto':
          case 'webkit':
            return [window.innerWidth, window.innerHeight];
          default:
            var element = rb_compatibility_element();
            return [element.clientWidth, element.clientHeight];
        }
      }
    END
  end
end
