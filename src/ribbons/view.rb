class Red::MethodCompiler
  def view_initialize
    <<-END
      function view_initialize(view, element) {
        rb_iv_set(view, '@element', element);
        view.callbacks = {};
      }
    END
  end
  
  def view_s_kvc_accessor
    add_function :rb_kvc_attr
    <<-END
      function view_s_kvc_accessor(argc, argv, klass) {
        var id;
        var tmp = rb_scan_args(argc, argv, '*');
        var ary = tmp[1];
        for (var i = 0, p = ary.ptr, l = p.length; i < l; i++) {
          id = rb_to_id(p[i]);
          rb_kvc_attr(klass, id, Qtrue);
        }
        return Qnil;
      }
    END
  end
  
  def view_add_binding_to_controller
    <<-END
     function view_add_binding_to_controller(view, v_attr, controller, c_attr) {
       view_fn = function(value){
         controller_update_value_for_key(controller, c_attr, value);
       };
       controller_fn = function(value){
         view_update_value_for_key(view, v_attr, value);
       };
       view.callbacks[v_attr] ? view.callbacks[v_attr].push(view_fn) : view.callbacks[v_attr] = [view_fn];
       controller.callbacks[c_attr] ? controller.callbacks[c_attr].push(controller_fn) : controller.callbacks[c_attr] = [controller_fn];
     }
    END
  end
end