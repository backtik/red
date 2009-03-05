class Red::MethodCompiler
  # CHECK
  def rb_obj_as_string
    add_function :rb_funcall, :rb_any_to_s
    add_method :to_s
    <<-END
      function rb_obj_as_string(obj) {
        if (TYPE(obj) == T_STRING) { return obj; }
        var str = rb_funcall(obj, id_to_s, 0);
        if (TYPE(str) != T_STRING) { return rb_any_to_s(obj); }
        if (OBJ_TAINTED(obj)) OBJ_TAINT(str);
        return str;
      }
    END
  end
  
  # CHECK
  def rb_str_append
    add_function :rb_str_modify
    <<-END
      function rb_str_append(str, str2) {
      //rb_str_modify(str);
        str.ptr = str.ptr + str2.ptr;
        OBJ_INFECT(str, str2);
        return str;
      }
    END
  end
  
  # CHECK
  def rb_str_cat
    add_function :rb_str_modify
    <<-END
      function rb_str_cat(str, ptr) {
      //rb_str_modify(str);
        str.ptr = str.ptr + ptr;
        return str;
      }
    END
  end
  
  # CHECK
  def rb_str_dup
    add_function :str_alloc, :rb_obj_class, :rb_str_replace
    <<-END
      function rb_str_dup(str) {
        var dup = str_alloc(rb_obj_class(str));
        rb_str_replace(dup, str);
        return dup;
      }
    END
  end
  
  # verbatim
  def rb_str_equal
    add_function :rb_respond_to, :rb_intern, :rb_equal, :rb_str_cmp
    add_method :to_str
    <<-END
      function rb_str_equal(str1, str2) {
        if (str1 == str2) { return Qtrue; }
        if (TYPE(str2) != T_STRING) {
          if (!rb_respond_to(str2, rb_intern("to_str"))) { return Qfalse; }
          return rb_equal(str2, str1);
        }
        if ((str1.ptr.length == str2.ptr.length) && (rb_str_cmp(str1, str2) === 0)) { return Qtrue; }
        return Qfalse;
      }
    END
  end
  
  # expanded rb_scan_args
  def rb_str_init
    add_function :rb_scan_args, :rb_str_replace
    <<-END
      function rb_str_init(argc, argv, str) {
        var tmp = rb_scan_args(argc, argv, "01");
        var orig = tmp[1];
        if (tmp[0] == 1) { rb_str_replace(str, orig); }
        return str;
      }
    END
  end
  
  # EMPTY
  def rb_str_inspect
    <<-END
      function rb_str_inspect() {}
    END
  end
  
  # CHECK
  def rb_str_intern
    add_function :rb_raise, :rb_sym_interned_p, :rb_intern
    <<-END
      function rb_str_intern(s) {
        var str = s;
        if (!str.ptr || str.ptr.length === 0) { rb_raise(rb_eArgError, "interning empty string"); }
        if (OBJ_TAINTED(str) && rb_safe_level() >= 1 && !rb_sym_interned_p(str)) { rb_raise(rb_eSecurityError, "Insecure: can't intern tainted string"); }
        var id = rb_intern(str.ptr);
        return ID2SYM(id);
      }
    END
  end
  
  # CHECK
  def rb_str_new
    add_function :str_alloc
    <<-END
      function rb_str_new(ptr) {
        var str = str_alloc(rb_cString);
        str.ptr = ptr || '';
        return str;
      }
    END
  end
  
  # CHECK
  def rb_str_replace
    add_function :rb_str_modify
    <<-END
      function rb_str_replace(str, str2) {
        if (str === str2) { return str; }
      //StringValue(str2);
      //rb_str_modify(str);
        str.ptr = str2.ptr;
        return str;
      }
    END
  end
  
  # verbatim
  def rb_str_to_s
    add_function :str_alloc, :rb_str_replace, :rb_obj_class
    <<-END
      function rb_str_to_s(str) {
        if (rb_obj_class(str) != rb_cString) {
          var dup = str_alloc(rb_cString);
          rb_str_replace(dup, str);
          return dup;
        }
        return str;
      }
    END
  end
  
  # CHECK
  def str_alloc
    <<-END
      function str_alloc(klass) {
        var str = NEWOBJ();
        OBJSETUP(str, klass, T_STRING);
        str.ptr = 0;
        return str;
      }
    END
  end
  
  # verbatim
  def str_to_id
    add_function :rb_str_intern
    <<-END
      function str_to_id(str) {
        return SYM2ID(rb_str_intern(str));
      }
    END
  end
end
