class Red::MethodCompiler
  # INCOMPLETE
  module Document
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
      add_function :rb_check_type
      <<-END
        function doc_execute_js(doc, str) {
          Check_Type(str, T_STRING);
          if (window.execScript) {
            window.execScript(str.ptr);
          } else {
            var script = document.createElement('script');
            script.setAttribute('type','text/javascript');
            script.text = str.ptr;
            document.head.appendChild(script);
            document.head.removeChild(script);
          }
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
    def doc_html
      <<-END
        function doc_html() {
          return rb_element_wrapper(document.html);
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
    def doc_title
      add_function :rb_str_new
      <<-END
        function doc_title() {
          return rb_str_new(document.title);
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
    
    # EMPTY
    def rb_dom_walk
      add_function :rb_ary_new, :rb_ary_push, :rb_element_wrapper
      <<-END
        function rb_dom_walk(fromElement, path, startRelation, allBool) {
          var el = fromElement[startRelation || path], ary = rb_ary_new();
          while (el) {
            if (!allBool) { return rb_element_wrapper(el); }
            rb_ary_push(ary, rb_element_wrapper(el));
            el = el[path];
          }
          return allBool ? ary : Qnil;
        }
      END
    end
  end
end
