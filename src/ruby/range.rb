class Red::MethodCompiler
  # CHECK
  def range_check
    add_function :rb_funcall
    add_method :"<=>"
    <<-END
      function range_check(args) {
        return rb_funcall(args[0], id_cmp, 1, args[1]);
      }
    END
  end
  
  # verbatim
  def range_eq
    add_function :rb_obj_is_instance_of, :rb_obj_class, :rb_equal, :rb_ivar_get
    <<-END
      function range_eq(range, obj) {
        if (range == obj) { return Qtrue; }
        if (!rb_obj_is_instance_of(obj, rb_obj_class(range))) { return Qfalse; }
        if (!rb_equal(rb_ivar_get(range, id_beg), rb_ivar_get(obj, id_beg))) { return Qfalse; }
        if (!rb_equal(rb_ivar_get(range, id_end), rb_ivar_get(obj, id_end))) { return Qfalse; }
        if (EXCL(range) != EXCL(obj)) { return Qfalse; }
        return Qtrue;
      }
    END
  end
  
  # CHECK
  def range_failed
    add_function :rb_raise
    <<-END
      function range_failed() {
        rb_raise(rb_eArgError, "bad value for range");
      }
    END
  end
  
  # CHECK
  def range_init
    add_function :rb_rescue, :range_failed, :rb_ivar_set
    <<-END
      function range_init(range, beg, end, exclude_end) {
        var args = [beg, end];
        if (!FIXNUM_P(beg) || !FIXNUM_P(end)) {
          var v = rb_rescue(range_check, args, range_failed, 0);
          if (NIL_P(v)) { range_failed(); }
        }
        SET_EXCL(range, exclude_end);
        rb_ivar_set(range, id_beg, beg);
        rb_ivar_set(range, id_end, end);
      }
    END
  end
  
  # expanded rb_scan_args
  def range_initialize
    add_function :rb_ivar_defined, :rb_name_error, :range_init
    <<-END
      function range_initialize(argc, argv, range) {
        var tmp = rb_scan_args(argc, argv, "21");
        var beg = tmp[1];
        var end = tmp[2];
        var flags = tmp[3];
        /* Ranges are immutable, so that they should be initialized only once. */
        if (rb_ivar_defined(range, id_beg)) { rb_name_error(rb_intern("initialize"), "`initialize' called twice"); }
        range_init(range, beg, end, RTEST(flags));
        return Qnil;
      }
    END
  end
  
  # CHECK
  def range_inspect
    add_function :rb_inspect, :rb_ivar_get, :rb_str_dup, :rb_str_cat, :rb_str_append
    <<-END
      function range_inspect(range) {
        var str = rb_inspect(rb_ivar_get(range, id_beg));
        var str2 = rb_inspect(rb_ivar_get(range, id_end));
        str = rb_str_dup(str);
        rb_str_cat(str, EXCL(range) ? '...' : '..');
        rb_str_append(str, str2);
        OBJ_INFECT(str, str2);
        return str;
      }
    END
  end
  
  # EMPTY
  def range_to_s
    <<-END
      function range_to_s() {}
    END
  end
  
  # CHECK
  def rb_range_new
    add_function :rb_obj_alloc, :range_init
    <<-END
      function rb_range_new(beg, end, exclude_end) {
        var range = rb_obj_alloc(rb_cRange);
        range_init(range, beg, end, exclude_end);
        return range;
      }
    END
  end
end

