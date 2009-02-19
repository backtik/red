class Red::MethodCompiler
  # complete
  module Event
    # complete
    def event_alloc
      <<-END
        function event_alloc(klass) {
          var event = NEWOBJ();
          OBJSETUP(event, klass, T_DATA);
          event.ptr = 0;
          return event;
        }
      END
    end
    
    # complete
    def event_alt
      <<-END
        function event_alt(ev) {
          return ev.alt;
        }
      END
    end
    
    # complete
    def event_base_type
      add_function :rb_str_new
      <<-END
        function event_base_type(ev) {
          return rb_str_new(ev.type);
        }
      END
    end
    
    # complete
    def event_client
      add_function :rb_hash_s_create
      <<-END
        function event_client(ev) {
          return rb_hash_s_create(4, [sym_x, ev.client_x, sym_y, ev.client_y], rb_cHash);
        }
      END
    end
    
    # complete
    def event_code
      <<-END
        function event_code(ev) {
          return ev.code;
        }
      END
    end
    
    # complete
    def event_ctrl
      <<-END
        function event_ctrl(ev) {
          return ev.ctrl;
        }
      END
    end
    
    # complete
    def event_key
      <<-END
        function event_key(ev) {
          return ev.key;
        }
      END
    end
    
    # complete
    def event_kill
       <<-END
         function event_kill(ev) {
           var event = ev.ptr;
           event.stopPropagation ? event.stopPropagation() : event.cancelBubble = true;
           event.preventDefault ? event.preventDefault() : event.returnValue = false;
           return ev;
         }
       END
    end
    
    # complete
    def event_meta
      <<-END
        function event_meta(ev) {
          return ev.meta;
        }
      END
    end
    
    # complete
    def event_page
      add_function :rb_hash_s_create
      <<-END
        function event_page(ev) {
          return rb_hash_s_create(4, [sym_x, ev.page_x, sym_y, ev.page_y], rb_cHash);
        }
      END
    end
    
    # complete
    def event_prevent_default
      <<-END
        function event_prevent_default(ev) {
          var event = ev.ptr;
          event.preventDefault ? event.preventDefault() : event.returnValue = false;
          return ev;
        }
      END
    end
    
    # complete
    def event_related_target
      <<-END
        function event_related_target(ev) {
          return rb_element_wrapper(ev.related_target)
        }
      END
    end
    
    # complete
    def event_right_click
      <<-END
        function event_right_click(ev) {
          return ev.right_click;
        }
      END
    end
    
    # complete
    def event_shift
      <<-END
        function event_shift(ev) {
          return ev.shift;
        }
      END
    end
    
    # complete
    def event_stop_propagation
      <<-END
        function event_stop_propagation(ev) {
          var event = ev.ptr;
          event.stopPropagation ? event.stopPropagation() : event.cancelBubble = true;
          return ev;
        }
      END
    end
    
    # complete
    def event_target
      add_function :rb_element_wrapper
      <<-END
        function event_target(ev) {
          return rb_element_wrapper(ev.target);
        }
      END
    end
    
    # complete
    def event_wheel
      <<-END
        function event_wheel(ev) {
          return ev.wheel;
        }
      END
    end
    
    # complete
    def rb_event_wrapper
      add_function :event_alloc, :rb_f_gecko_p
      <<-END
        function rb_event_wrapper(event) {
          event = event || window.event;
          if (!event) { return Qnil; }
          var ev = event_alloc(rb_cEvent);
          var code = 0;
          var related_target = 0;
          var key = Qnil;
          var wheel = Qnil;
          var client_x = Qnil;
          var client_y = Qnil;
          var page_x = Qnil;
          var page_y = Qnil;
          var right_click = Qfalse;
          var type = event.type;
          var target = event.target || event.srcElement;
          while (target && (target.nodeType == 3)) { target = event.parentNode; }
          if (/key/.test(type)) {
            code = event.which || event.keyCode;
            var key_name = ({ 8: 'backspace', 9: 'tab', 13: 'enter', 27: 'esc', 32: 'space', 37: 'left', 38: 'up', 39: 'right', 40: 'down', 46: 'delete' })[code] || String.fromCharCode(code).toLowerCase();
            if (type == 'keydown') {
              var f_key = code - 111;
              if (f_key > 0 && f_key < 13) { key = rb_str_new('f'+f_key); }
            }
            if (NIL_P(key)) { key = rb_str_new(key_name); }
          } else if (type.match(/(click|mouse|menu)/i)) {
            var doc = (!document.compatMode || (document.compatMode == 'CSS1Compat')) ? document.html : document.body;
            page_x = INT2FIX(event.pageX || event.clientX + doc.scrollLeft);
            page_y = INT2FIX(event.pageY || event.clientY + doc.scrollTop);
            client_x = INT2FIX(event.pageX ? event.pageX - window.pageXOffset : event.clientX);
            client_y = INT2FIX(event.pageY ? event.pageY - window.pageYOffset : event.clientY);
            if (type.match(/DOMMouseScroll|mousewheel/)) { wheel = INT2FIX(event.wheelDelta ? event.wheelDelta / 40 : -(event.detail || 0)); }
            if ((event.which == 3) || (event.button == 2)) { right_click = Qtrue; }
            if (type.match(/over|out/)) {
              switch (type) {
                case 'mouseover':
                  related_target = event.relatedTarget || event.fromElement;
                  break;
                case 'mouseout':
                  related_target = event.relatedTarget || event.toElement;
                  break;
              }
              if (RTEST(rb_f_gecko_p(0,[]))) {
                try {
                  while (related_target && (related_target.nodeType == 3)) {
                    related_target = related_target.parentNode;
                  }
                } catch (e) {
                  related_target = 0;
                }
              } else {
                while (related_target && (related_target.nodeType == 3)) {
                  related_target = related_target.parentNode;
                }
              }
            }
          }
          ev.ptr = event; // event
          ev.type = type; // string
          ev.target = target; // element
          ev.related_target = related_target; // element
          ev.code = (code) ? INT2FIX(code) : Qnil; // VALUE
          ev.key = key; // VALUE
          ev.wheel = wheel; // VALUE
          ev.right_click = right_click; // VALUE
          ev.page_x = page_x; // VALUE
          ev.page_y = page_y; // VALUE
          ev.client_x = client_x; // VALUE
          ev.client_y = client_y; // VALUE
          ev.shift = (event.shiftKey) ? Qtrue : Qfalse;
          ev.ctrl = (event.ctrlKey) ? Qtrue : Qfalse;
          ev.alt = (event.altKey) ? Qtrue : Qfalse;
          ev.meta = (event.metaKey) ? Qtrue : Qfalse;
          return ev;
        }
      END
    end
  end
end