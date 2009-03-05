class Red::MethodCompiler
  # verbatim
  def exc_backtrace
    add_function :rb_attr_get, :rb_intern
    <<-END
      function exc_backtrace(exc) {
        return rb_attr_get(exc, rb_intern("bt"));
      }
    END
  end
  
  # verbatim
  def exc_exception
    add_function :rb_obj_clone, :exc_initialize
    <<-END
      function exc_exception(argc, argv, self) {
        var exc;
        if (argc === 0) { return self; }
        if ((argc == 1) && (self == argv[0])) { return self; }
        exc = rb_obj_clone(self);
        exc_initialize(argc, argv, exc);
        return exc;
      }
    END
  end
  
  # expanded rb_scan_args
  def exc_initialize
    add_function :rb_scan_args, :rb_iv_set
    <<-END
      function exc_initialize(argc, argv, exc) {
        var tmp = rb_scan_args(argc, argv, "01", true);
        var arg = tmp[1];
        rb_iv_set(exc, 'mesg', arg);
        rb_iv_set(exc, 'bt', Qnil);
        return exc;
      }
    END
  end
  
  # EMPTY
  def exc_inspect
    <<-END
      function exc_inspect() {}
    END
  end
  
  # verbatim
  def exc_set_backtrace
    add_function :rb_iv_set, :rb_check_backtrace
    <<-END
      function exc_set_backtrace(exc, bt) {
        return rb_iv_set(exc, "bt", rb_check_backtrace(bt));
      }
    END
  end
  
  # verbatim
  def exc_to_s
    add_functions :rb_attr_get, :rb_class_name
    <<-END
      function exc_to_s(exc) {
        var mesg = rb_attr_get(exc, rb_intern("mesg"));
        if (NIL_P(mesg)) { return rb_class_name(CLASS_OF(exc)); }
        if (OBJ_TAINTED(exc)) { OBJ_TAINT(mesg); }
        return mesg;
      }
    END
  end
  
  # verbatim
  def exc_to_str
    add_function :rb_funcall
    add_method :to_s
    <<-END
      function exc_to_str(exc) {
        return rb_funcall(exc, rb_intern("to_s"), 0, 0);
      }
    END
  end
  
  # EMPTY
  def exit_initialize
    <<-END
      function exit_initialize() {}
    END
  end
  
  # CHECK
  def name_err_initialize
    add_function :rb_call_super, :rb_iv_set
    <<-END
      function name_err_initialize(argc, argv, self) {
        var name = argc > 1 ? argv[--argc] : Qnil;
        rb_call_super(argc, argv);
        rb_iv_set(self, 'name', name);
        return self;
      }
    END
  end
  
  # unpacked Data_Wrap_Struct
  def name_err_mesg_new
    add_function :rb_data_object_alloc
    <<-END
      function name_err_mesg_new(obj, mesg, recv, method) {
        var ptr = [mesg, recv, method];
        rb_data_object_alloc(rb_cNameErrorMesg, ptr);
      }
    END
  end
  
  # EMPTY
  def name_err_mesg_to_str
    <<-END
      function name_err_mesg_to_str() {}
    END
  end
  
  # EMPTY
  def name_err_to_s
    <<-END
      function name_err_to_s() {}
    END
  end
  
  # CHECK
  def nometh_err_initialize
    add_function :name_err_initialize, :rb_iv_set
    <<-END
      function nometh_err_initialize(argc, argv, self) {
        var args = (argc < 2) ? argv[--argc] : Qnil;
        name_err_initialize(argc, argv, self);
        rb_iv_set(self, 'args', args);
        return self;
      }
    END
  end
  
  # verbatim
  def rb_check_backtrace
    add_functions :rb_ary_new3, :rb_raise
    <<-END
      function rb_check_backtrace(bt) {
        var err = "backtrace must be Array of String";
        if (!NIL_P(bt)) {
          var t = TYPE(bt);
          if (t == T_STRING) { return rb_ary_new3(1, bt); }
          if (t != T_ARRAY) { rb_raise(rb_eTypeError, err); }
          for (var i = 0, p = bt.ptr, l = p.length; i < l; ++i) {
            if (TYPE(p[i]) != T_STRING) { rb_raise(rb_eTypeError, err); }
          }
        }
        return bt;
      }
    END
  end
  
  # verbatim
  def rb_check_frozen
    add_functions :rb_error_frozen, :rb_obj_classname
    <<-END
      function rb_check_frozen(obj) {
        if (OBJ_FROZEN(obj)) { rb_error_frozen(rb_obj_classname(obj)); }
      }
    END
  end
  
  # removed bug warning for unknown type
  def rb_check_type
    add_functions :rb_special_const_p, :rb_obj_classname, :rb_raise
    <<-END
      function rb_check_type(x, t) {
        // removed bug warning
        if (TYPE(x) != t) {
          if (builtin_types[t]) {
            var etype;
            if (NIL_P(x)) { etype = "nil"; } else
            if (FIXNUM_P(x)) { etype = "Fixnum"; } else
            if (SYMBOL_P(x)) { etype = "Symbol"; } else
            if (rb_special_const_p(x)) { etype = rb_obj_as_string(x).ptr; } else { etype = rb_obj_classname(x); }
            rb_raise(rb_eTypeError, "wrong argument type %s (expected %s)", etype, builtin_types[t]);
          }
          // removed bug warning
        }
      }
    END
  end
  
  def rb_error_frozen
    add_function :rb_raise
    <<-END
      function rb_error_frozen(what) {
        rb_raise(rb_eTypeError, "can't modify frozen %s", what);
      }
    END
  end
  
  # CHECK
  def rb_exc_new
    add_function :rb_exc_new, :rb_funcall, :rb_str_new
    add_method :new
    <<-END
      function rb_exc_new(etype, ptr) {
        return rb_funcall(etype, rb_intern('new'), 1, rb_str_new(ptr));
      }
    END
  end
  
  # CHECK CHECK CHECK
  def rb_exc_new3
    add_function :rb_funcall
    add_method :new
    <<-END
      function rb_exc_new3(etype, str) {
      //StringValue(str);
        return rb_funcall(etype, rb_intern("new"), 1, str);
      }
    END
  end
  
  # CHECK
  def rb_exc_raise
    add_function :rb_longjmp
    <<-END
      function rb_exc_raise(mesg) {
        rb_longjmp(TAG_RAISE, mesg);
      }
    END
  end
  
  # CHECK
  def rb_raise
    add_function :rb_exc_raise, :rb_exc_new, :jsprintf
    <<-END
      function rb_raise(exc, fmt) {
        for (var i = 2, ary = []; typeof(arguments[i]) != 'undefined'; ++i) { ary.push(arguments[i]); }
        var buf = jsprintf(fmt,ary);
        rb_exc_raise(rb_exc_new(exc, buf));
      }
    END
  end
  
  # EMPTY
  def syserr_initialize
    <<-END
      function syserr_initialize() {}
    END
  end
end
