class Red::MethodCompiler
  # replaced gettimeofday with JS '+new(Date)()', removed 'rb_sys_fail' error check
  def time_init
    add_function :time_modify
    <<-END
      function time_init(time) {
        time_modify(time);
        GetTimeval(time, tobj);
        tobj.tm_got = 0;
        tobj.tv.tv_sec = +new(Date)();
        tobj.tv.tv_usec = 0;
        return time;
      }
    END
  end
  
  # verbatim
  def time_modify
    add_function :rb_check_frozen, :rb_raise
    <<-END
      function time_modify(time) {
        rb_check_frozen(time);
        if (!OBJ_TAINTED(time) && ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "Insecure: can't modify Time"); }
      }
    END
  end
  
  # expanded "Data_Make_Struct"
  def time_s_alloc
    <<-END
      function time_s_alloc(klass) {
        var tobj = {tv:{}};
        var obj = rb_data_object_alloc(klass, tobj);
        tobj.tm_got = 0;
        tobj.tv.tv_sec = 0;
        tobj.tv.tv_usec = 0;
        return obj;
      }
    END
  end
  
  # verbatim
  def time_to_f
    add_function :rb_float_new
    <<-END
      function time_to_f(time) {
        GetTimeval(time, tobj);
        return rb_float_new(tobj.tv.tv_sec + (tobj.tv.tv_usec / 1e6));
      }
    END
  end
  
  # verbatim
  def time_to_i
    <<-END
      function time_to_i(time) {
        GetTimeval(time, tobj);
        return LONG2NUM(tobj.tv.tv_sec);
      }
    END
  end
end
