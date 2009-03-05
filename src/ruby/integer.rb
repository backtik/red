class Red::MethodCompiler
  # CHECK
  def int_dotimes
    add_function :rb_yield, :rb_funcall
    add_method :<, :+
    <<-END
      function int_dotimes(num) {
        RETURN_ENUMERATOR(num, 0, 0);
        if (FIXNUM_P(num)) {
          var end = FIX2LONG(num);
          for (var i = 0; i < end; i++) { rb_yield(LONG2FIX(i)); }
        } else {
          var i = INT2FIX(0);
          for (;;) {
            if (!RTEST(rb_funcall(i, '<', 1, num))) { break; }
            rb_yield(i);
            i = rb_funcall(i, '+', 1, INT2FIX(1));
          }
        }
        return num;
      }
    END
  end
  
  # verbatim
  def int_to_i
    <<-END
      function int_to_i(num) {
        return num;
      }
    END
  end
  
  # CHECK
  def rb_int_new
    add_function :rb_int2inum
    <<-END
      function rb_int_new(v) {
        return rb_int2inum(v);
      }
    END
  end
  
  # CHECK
  def rb_int2inum
    add_function :rb_int2big
    <<-END
      function rb_int2inum(n) {
        if (FIXABLE(n)) { return LONG2FIX(n); }
        return rb_int2big(n);
      }
    END
  end
end
