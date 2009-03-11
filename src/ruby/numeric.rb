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
        if ((TYPE(ary) != T_ARRAY) || ary.ptr.length != 2) {
          if (err) { rb_raise(rb_eTypeError, "coerce must return [x, y]"); }
          return [Qfalse, x, y];
        }
        return [Qtrue, ary.ptr[0], ary.ptr[1]];
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
        ruby_frame = ruby_frame.prev; /* pop frame for "singleton_method_added" */
        /* Numerics should be values; singleton_methods should not be added to them */
        rb_raise(rb_eTypeError, "can't define singleton method '%s' for %s", rb_id2name(rb_to_id(name)), rb_obj_classname(x));
        return Qnil; /* not reached */
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
  
  # modified do_coerce to return array instead of using pointers
  def rb_num_coerce_bin
    add_function :rb_funcall, :do_coerce
    <<-END
      function rb_num_coerce_bin(x, y) {
        var tmp = do_coerce(x, y, Qtrue);
        return rb_funcall(tmp[1], ruby_frame.orig_func, tmp[2], y);
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
