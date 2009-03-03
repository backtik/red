class Red::MethodCompiler
  # complete (simplified from original)
  module CodeEvent
    # obj.fire(sym, [arg, ...]) -> obj
    def cevent_fire
      add_function :rb_scan_args, :rb_to_id, :rb_proc_call
      <<-END
        function cevent_fire(argc, argv, obj) {
          var obj_events;
          var obj_ev_type;
          var tmp = rb_scan_args(argc, argv, "1*");
          var type_id = rb_to_id(tmp[1]);
          var args = tmp[2] || rb_ary_new();
          if ((obj_events = obj.code_events) && (obj_ev_type = obj_events[type_id])) {
            for (var i = 0, l = obj_ev_type.length; i < l; ++i) {
              rb_proc_call(obj_ev_type[i], args);
            }
          }
          return obj;
        }
      END
    end
    
    # obj.ignore(sym) -> obj
    def cevent_ignore
      add_function :rb_to_id
      <<-END
        function cevent_ignore(obj, type) {
          var obj_events;
          var obj_ev_type;
          var type_id = rb_to_id(type);
          if ((obj_events = obj.code_events) && (obj_ev_type = obj_events[type_id])) {
            for (var i = obj_ev_type.length; --i >= 0; ) {
              if (!obj_ev_type[i].permanent) { obj_ev_type.pop(); }
            }
          }
          return obj;
        }
      END
    end
    
    # obj.upon(sym, unignorable = false) { |arg,...| block } -> obj
    def cevent_upon
      add_function :rb_scan_args, :rb_block_proc, :rb_to_id
      <<-END
        function cevent_upon(argc, argv, obj) {
          var tmp = rb_scan_args(argc, argv, "11");
          var bvar = rb_block_proc();
          bvar.permanent = (tmp[0] > 1) ? RTEST(tmp[2] || 0) : false;
          var type_id = rb_to_id(tmp[1]);
          var obj_events = (obj.code_events) || (obj.code_events = {});
          var obj_ev_type = (obj_events[type_id]) || (obj_events[type_id] = []);
          obj_ev_type.push(bvar);
          return obj;
        }
      END
    end
  end
end
