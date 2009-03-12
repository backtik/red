class Red::MethodCompiler
  def controller_alloc
    <<-END
      function controller_alloc(klass) {
        var obj = NEWOBJ();
        OBJSETUP(obj, klass, T_OBJECT);
        obj.callbacks = {};
        return obj;
      }
    END
  end
  
  def contorller_s_kvc_accessor
    add_function :rb_kvc_attr
    <<-END
      function contorller_s_kvc_accessor(argc, argv, klass) {
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
  
  def contorller_s_kvc_reader
    add_function :rb_kvc_attr
    <<-END
      function contorller_s_kvc_reader(klass, attr, dependencies) {
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
end