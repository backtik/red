class Red::MethodCompiler
  # complete
  def init_custom_events
    <<-END
      function init_custom_events() {
        ruby_custom_events = {};
      }
    END
  end
  
  # need to add special 'unload' type handler
  def uevent_add_listener
    add_function :rb_block_proc, :rb_proc_call, :rb_ary_new, :rb_id2name,
                 :rb_event_wrapper
    <<-END
      function uevent_add_listener(elem, name) {
        var bvar = rb_block_proc();
        function fn(event) { rb_proc_call(bvar, rb_event_wrapper(event)); };
        var element = elem.ptr;
        var type = rb_id2name(rb_to_id(name));
        if (element.addEventListener) {
          element.addEventListener(type, fn, false);
        } else {
          element.attachEvent('on' + type, fn);
        }
        return elem;
      }
    END
  end
  
  # 
  def rb_add_listener
    add_function :rb_id2name
    <<-END
      function rb_add_listener(element, id, func) {
        var type = rb_id2name(id);
        if (element.addEventListener) {
          element.addEventListener(type, func, false);
        } else {
          element.attachEvent('on' + type, func);
        }
      }
    END
  end
  
  # 
  def uevent_listen
    add_function :rb_scan_args, :rb_to_id, :rb_block_proc, :rb_proc_call,
                 :rb_funcall, :rb_add_listener, :rb_event_wrapper
    add_method :call
    <<-END
      function uevent_listen(argc, argv, obj) {
        var custom_type;
        var listener;
        var condition_func;
        var tmp = rb_scan_args(argc, argv, '11');
        var type_id = rb_to_id(tmp[1]);
        var real_type_id = type_id;
        var block_is_proc = (tmp[0] == 1);
        var block = (block_is_proc) ? rb_block_proc() : tmp[2]; // otherwise block is an UnboundMethod
        var obj_events = (obj.custom_events) ? obj.custom_events : (obj.custom_events = {});
        var obj_ev_type = (obj_events[type_id]) ? obj_events[type_id] : (obj_events[type_id] = {});
        if (obj_ev_type[block.rvalue]) { return obj; }
        var condition_func = function(ev) { return RTEST(rb_proc_call(block, ev)); };
        if (custom_type = ruby_custom_events[type_id]) {
          if (custom_type.listen) {
            // add handler for on_listen
          }
          if (custom_type.condition) {
            var condition_block = custom_type.condition;
            condition_func = function(ev) { var args = [ev]; return RTEST(rb_funcall2(condition_block, rb_intern('call'), 1, [ev])) ? RTEST(rb_funcall2(block, rb_intern('call'), 1, [4])) : true; };
          }
          real_type_id = custom_type.base || real_type_id;
        }
        if (block_is_proc) {
          listener = function() { rb_proc_call(block, Qnil); };
        } else {
          // add handler for method-type listeners
        }
        var native_event = 2;
        if (native_event) {
          if (native_event == 2) {
            listener = function(event) { if (!condition_func(rb_event_wrapper(event))) { event.stopPropagation; } }
          }
          rb_add_listener(obj.ptr, real_type_id, listener);
        }
        obj_ev_type[block.rvalue] = listener;
        return obj;
      }
    END
  end
  
  # 
  def uevent_s_define
    add_function :rb_check_type, :rb_to_id
    <<-END
      function uevent_s_define(mod, sym, hash) {
        Check_Type(hash, T_HASH);
        var tbl = hash.tbl;
        ruby_custom_events[rb_to_id(sym)] = {
          base: rb_to_id(tbl[sym_base]),
          condition: tbl[sym_condition] || 0,
          listen: tbl[sym_onlisten] || 0,
          unlisten: tbl[sym_onunlisten] || 0
        };
        return Qtrue;
      }
    END
  end
end
