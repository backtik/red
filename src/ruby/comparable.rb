class Red::MethodCompiler
  # verbatim
  def cmp_between
    add_function :cmp_lt, :cmp_gt
    <<-END
      function cmp_between(x, y) {
        if (RTEST(cmp_lt(x, min))) { return Qfalse; }
        if (RTEST(cmp_gt(x, max))) { return Qfalse; }
        return Qtrue;
      }
    END
  end
  
  # verbatim
  def cmp_eq
    add_function :rb_funcall, :rb_cmpint
    add_method :'<=>'
    <<-END
      function cmp_eq(a) {
        var c = rb_funcall(a[0], cmp, 1, a[1]);
        if (NIL_P(c)) { return Qnil; }
        if (rb_cmpint(c, a[0], a[1]) == 0) { return Qtrue; }
        return Qfalse;
      }
    END
  end
  
  # verbatim
  def cmp_equal
    add_function :rb_rescue, :cmp_failed, :cmp_eq
    add_method :eql?
    <<-END
      function cmp_equal(x, y) {
        if (x == y) { return Qtrue; }
        return rb_rescue(cmp_eq, [x, y], cmp_failed, 0);
      }
    END
  end
  
  # verbatim
  def cmp_failed
    <<-END
      function cmp_failed() {
        return Qnil;
      }
    END
  end
  
  # verbatim
  def cmp_ge
    add_function :rb_funcall, :rb_cmpint, :rb_cmperr
    add_method :'<=>'
    <<-END
      function cmp_ge(x, y) {
        var c = rb_funcall(x, cmp, 1, y);
        if (NIL_P(c)) { rb_cmperr(); return Qnil; }
        return (rb_cmpint(c, x, y) >= 0) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def cmp_gt
    add_function :rb_funcall, :rb_cmpint, :rb_cmperr
    add_method :'<=>'
    <<-END
      function cmp_gt(x, y) {
        var c = rb_funcall(x, cmp, 1, y);
        if (NIL_P(c)) { rb_cmperr(); return Qnil; }
        return (rb_cmpint(c, x, y) > 0) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def cmp_le
    add_function :rb_funcall, :rb_cmpint, :rb_cmperr
    add_method :'<=>'
    <<-END
      function cmp_le(x, y) {
        var c = rb_funcall(x, cmp, 1, y);
        if (NIL_P(c)) { rb_cmperr(); return Qnil; }
        return (rb_cmpint(c, x, y) <= 0) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def cmp_lt
    add_function :rb_funcall, :rb_cmpint, :rb_cmperr
    add_method :'<=>'
    <<-END
      function cmp_lt(x, y) {
        var c = rb_funcall(x, cmp, 1, y);
        if (NIL_P(c)) { rb_cmperr(); return Qnil; }
        return (rb_cmpint(c, x, y) < 0) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def rb_cmperr
    add_function :rb_inspect, :rb_obj_classname, :rb_raise, :rb_obj_classname, :rb_string_value
    <<-END
      function rb_cmperr(x, y) {
        var classname;
        if (SPECIAL_CONST_P(y)) {
          y = rb_inspect(y);
          classname = rb_string_value(y).ptr;
        } else {
          classname = rb_obj_classname(y);
        }
        rb_raise(rb_eArgError, "comparison of %s with %s failed", rb_obj_classname(x), classname);
      }
    END
  end
  
  # verbatim
  def rb_cmpint
    add_function :rb_cmperr, :rb_funcall
    add_method :<, :>
    <<-END
      function rb_cmpint(val, a, b) {
        if (NIL_P(val)) { rb_cmperr(a, b); }
        if (FIXNUM_P(val)) { return FIX2INT(val); }
        if (TYPE(val) == T_BIGNUM) { return (val.sign) ? 1 : -1; }
        if (RTEST(rb_funcall(val, '>', 1, INT2FIX(0)))) { return 1; }
        if (RTEST(rb_funcall(val, '<', 1, INT2FIX(0)))) { return -1; }
        return 0;
      }
    END
  end
end
