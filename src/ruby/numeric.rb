class Red::MethodCompiler
  # verbatim
  def coerce_body
    add_function :rb_funcall
    add_method :coerce
    <<-END
      function coerce_body(x) {
        return rb_funcall(x[1], id_coerce, 1, x[0]);
      }
    END
  end
  
  # verbatim
  def coerce_rescue
    add_function :rb_inspect, :rb_raise, :rb_special_const_p, :rb_obj_classname
    <<-END
      function coerce_rescue(x) {
        var v = rb_inspect(x[1]);
        rb_raise(rb_eTypeError, "%s can't be coerced into %s", rb_special_const_p(x[1]) ? v.ptr : rb_obj_classname(x[1]), rb_obj_classname(x[0]));
        return Qnil; /* dummy */
      }
    END
  end
  
  # modified to return array [retval, x, y] instead of using pointers
  def do_coerce
    add_function :rb_rescue, :coerce_body, :coerce_rescue
    <<-END
      function do_coerce(x, y, err) {
        var ary = rb_rescue(coerce_body, [x, y], err ? coerce_rescue : 0, [x, y]);
        if ((TYPE(ary) != T_ARRAY) || (ary.ptr.length != 2)) {
          if (err) { rb_raise(rb_eTypeError, "coerce must return [x, y]"); }
          return [Qfalse, x, y];
        }
        return [Qtrue, ary.ptr[0], ary.ptr[1]];
      }
    END
  end
  
  # CHECK: changed rb_funcall argument '<' to rb_intern('<')
  def num_abs
    add_function :rb_funcall, :rb_intern
    add_method :<, :-@
    <<-END
      function num_abs(num) {
        if (RTEST(rb_funcall(num, rb_intern('<'), 1, INT2FIX(0)))) { return rb_funcall(num, rb_intern('-@'), 0); }
        return num;
      }
    END
  end
  
  # verbatim
  def num_cmp
    <<-END
      function num_cmp(x, y) {
        if (x == y) { return INT2FIX(0); }
        return Qnil;
      }
    END
  end
  
  # verbatim
  def num_coerce
    add_function :rb_assoc_new, :rb_Float
    <<-END
      function num_coerce(x, y) {
        if (CLASS_OF(x) == CLASS_OF(y)) { return rb_assoc_new(y, x); }
        x = rb_Float(x);
        y = rb_Float(y);
        return rb_assoc_new(y, x);
      }
    END
  end
  
  # verbatim
  def num_divmod
    add_function :rb_assoc_new, :num_div, :rb_funcall
    add_method :%
    <<-END
      function num_divmod(x, y) {
        return rb_assoc_new(num_div(x, y), rb_funcall(x, '%', 1, y));
      }
    END
  end
  
  # verbatim
  def num_eql
    add_function :rb_equal
    <<-END
      function num_eql(x, y) {
        if (TYPE(x) != TYPE(y)) { return Qfalse; }
        return rb_equal(x, y);
      }
    END
  end
  
  # verbatim
  def num_equal
    add_function :rb_funcall
    add_method :==
    <<-END
      function num_equal(x, y) {
        if (x == y) { return Qtrue; }
        return rb_funcall(y, id_eq, 1, x);
      }
    END
  end
  
  # verbatim
  def num_init_copy
    add_function :rb_raise, :rb_obj_classname
    <<-END
      function num_init_copy(x, y) {
        /* Numerics are immutable values, which should not be copied */
        rb_raise(rb_eTypeError, "can't copy %s", rb_obj_classname(x));
        return Qnil; /* not reached */
      }
    END
  end
  
  # verbatim
  def num_sadded
    add_function :rb_raise, :rb_id2name, :rb_to_id, :rb_obj_classname
    <<-END
      function num_sadded(x, name) {
        ruby_frame = ruby_frame.prev; /* pop frame for 'singleton_method_added' */
        /* Numerics should be values; singleton_methods should not be added to them */
        rb_raise(rb_eTypeError, "can't define singleton method '%s' for %s", rb_id2name(rb_to_id(name)), rb_obj_classname(x));
        return Qnil; /* not reached */
      }
    END
  end
  
  # verbatim
  def num_remainder
    add_function :rb_funcall, :rb_equal
    add_method :<, :>, :%, :-
    <<-END
      function num_remainder(x, y) {
        var z = rb_funcall(x, '%', 1, y);
        if ((!rb_equal(z, INT2FIX(0))) && ((RTEST(rb_funcall(x, '<', 1, INT2FIX(0))) && RTEST(rb_funcall(y, '>', 1, INT2FIX(0)))) || (RTEST(rb_funcall(x, '>', 1, INT2FIX(0))) && RTEST(rb_funcall(y, '<', 1, INT2FIX(0)))))) { return rb_funcall(z, '-', 1, y); }
        return z;
      }
    END
  end
  
  # verbatim
  def num_to_int
    add_function :rb_funcall
    add_method :to_i
    <<-END
      function num_to_int(num) {
        return rb_funcall(num, id_to_i, 0, 0);
      }
    END
  end
  
  # modified 'do_coerce' to return array instead of using pointers
  def num_uminus
    add_function :do_coerce, :rb_funcall
    add_method :-
    <<-END
      function num_uminus(num) {
        var zero = INT2FIX(0);
        var tmp = do_coerce(zero, num, Qtrue);
        return rb_funcall(tmp[1], '-', 1, tmp[2]);
      }
    END
  end
  
  # verbatim
  def rb_dbl_cmp
    add_function :isnan
    <<-END
      function rb_dbl_cmp(a, b) {
        if (isnan(a) || isnan(b)) { return Qnil; }
        if (a == b) { return INT2FIX(0); }
        if (a > b) { return INT2FIX(1); }
        if (a < b) { return INT2FIX(-1); }
        return Qnil;
      }
    END
  end
  
  # verbatim
  def rb_num2dbl
    add_function :rb_raise, :rb_Float
    <<-END
      function rb_num2dbl(val) {
        switch (TYPE(val)) {
          case T_FLOAT:
            return val.value;
          case T_STRING:
            rb_raise(rb_eTypeError, "no implicit conversion to float from string");
            break;
          case T_NIL:
            rb_raise(rb_eTypeError, "no implicit conversion to float from nil");
            break;
          default:
            break;
        }
        return rb_Float(val).value;
      }
    END
  end
  
  # unwound 'goto' structure
  def rb_num2long
    add_function :rb_raise, :rb_big2long, :rb_to_int
    <<-END
      function rb_num2long(val) {
        do { // added to handle 'goto again'
          var goto_again = 0;
          if (NIL_P(val)) { rb_raise(rb_eTypeError, "no implicit conversion from nil to integer"); }
          if (FIXNUM_P(val)) { return FIX2LONG(val); }
          switch (TYPE(val)) {
            case T_FLOAT:
              if ((val.value <= LONG_MAX) && (val.value >= LONG_MIN)) {
                return val.value;
              } else {
                rb_raise(rb_eRangeError, "float out of range of integer");
              }
            case T_BIGNUM:
              return rb_big2long(val);
            default:
              val = rb_to_int(val);
              goto_again = 1;
          }
        } while (goto_again);
      }
    END
  end
  
  # modified do_coerce to return array instead of using pointers
  def rb_num_coerce_bin
    add_function :rb_funcall, :do_coerce
    <<-END
      function rb_num_coerce_bin(x, y) {
        var tmp = do_coerce(x, y, Qtrue);
        return rb_funcall(tmp[1], ruby_frame.orig_func, 1, tmp[2]);
      }
    END
  end
  
  # modified do_coerce to return array instead of using pointers
  def rb_num_coerce_cmp
    add_function :do_coerce, :rb_funcall
    <<-END
      function rb_num_coerce_cmp(x, y) {
        var tmp = do_coerce(x, y, Qfalse);
        if (tmp[0]) { return rb_funcall(tmp[1], ruby_frame.orig_func, 1, tmp[2]); }
        return Qnil;
      }
    END
  end
  
  # modified do_coerce to return array instead of using pointers
  def rb_num_coerce_relop
    add_function :do_coerce, :rb_funcall, :rb_cmperr
    <<-END
      function rb_num_coerce_relop(x, y) {
        var c;
        var tmp = do_coerce(x, y, Qfalse);
        if (!tmp[0] || NIL_P(c = rb_funcall(tmp[1], ruby_frame.orig_func, 1, tmp[2]))) {
          rb_cmperr(x, y);
          return Qnil; /* not reached */
        }
        return c;
      }
    END
  end
  
  # verbatim
  def rb_num_zerodiv
    add_function :rb_raise
    <<-END
      function rb_num_zerodiv() {
        rb_raise(rb_eZeroDivError, "divided by 0");
      }
    END
  end
end
