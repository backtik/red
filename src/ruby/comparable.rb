class Red::MethodCompiler
  # CHECK
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
  
  # CHECK
  def cmp_equal
    add_function :rb_rescue, :cmp_failed
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
  
  # CHECK
  def cmp_ge
    add_function :rb_funcall, :rb_cmpint, :cmperr
    add_method :'<=>'
    <<-END
      function cmp_ge(x, y) {
        var c = rb_funcall(x, cmp, 1, y);
        if (NIL_P(c)) { return cmperr(); }
        return (rb_cmpint(c, x, y) >= 0) ? Qtrue : Qfalse;
      }
    END
  end
  
  # CHECK
  def cmp_gt
    add_function :rb_funcall, :rb_cmpint, :cmperr
    add_method :'<=>'
    <<-END
      function cmp_gt(x, y) {
        var c = rb_funcall(x, cmp, 1, y);
        if (NIL_P(c)) { return cmperr(); }
        return (rb_cmpint(c, x, y) > 0) ? Qtrue : Qfalse;
      }
    END
  end
  
  # CHECK
  def cmp_le
    add_function :rb_funcall, :rb_cmpint, :cmperr
    add_method :'<=>'
    <<-END
      function cmp_le(x, y) {
        var c = rb_funcall(x, cmp, 1, y);
        if (NIL_P(c)) { return cmperr(); }
        return (rb_cmpint(c, x, y) <= 0) ? Qtrue : Qfalse;
      }
    END
  end
  
  # CHECK
  def cmp_lt
    add_function :rb_funcall, :rb_cmpint, :cmperr
    add_method :'<=>'
    <<-END
      function cmp_lt(x, y) {
        var c = rb_funcall(x, cmp, 1, y);
        if (NIL_P(c)) { return cmperr(); }
        return (rb_cmpint(c, x, y) < 0) ? Qtrue : Qfalse;
      }
    END
  end
end
