class Red::MethodCompiler
  # CHECK
  def fix_cmp
    add_function :rb_num_coerce_cmp
    <<-END
      function fix_cmp(x, y) {
        if (x == y) return INT2FIX(0);
        if (FIXNUM_P(y)) {
          if (FIX2LONG(x) > FIX2LONG(y)) { return INT2FIX(1); }
          return INT2FIX(-1);
        } else {
          return rb_num_coerce_cmp(x, y);
        }
      }
    END
  end
  
  # CHECK
  def fix_equal
    add_function :num_equal
    <<-END
      function fix_equal(x, y) {
        if (x == y) { return Qtrue; }
        if (FIXNUM_P(y)) { return Qfalse; }
        return num_equal(x, y);
      }
    END
  end
  
  # CHECK
  def fix_even_p
    <<-END
      function fix_even_p(num) {
        return (num & 2) ? Qfalse : Qtrue;
      }
    END
  end
  
  # CHECK
  def fix_ge
    add_function :rb_num_coerce_relop
    <<-END
      function fix_ge(x, y) {
        if (FIXNUM_P(y)) {
          if (FIX2LONG(x) >= FIX2LONG(y)) { return Qtrue; }
          return Qfalse;
        } else {
          return rb_num_coerce_relop(x, y);
        }
      }
    END
  end
  
  # CHECK
  def fix_gt
    add_function :rb_num_coerce_relop
    <<-END
      function fix_gt(x, y) {
        if (FIXNUM_P(y)) {
          if (FIX2LONG(x) > FIX2LONG(y)) { return Qtrue; }
          return Qfalse;
        } else {
          return rb_num_coerce_relop(x, y);
        }
      }
    END
  end
  
  # CHECK
  def fix_le
    add_function :rb_num_coerce_relop
    <<-END
      function fix_le(x, y) {
        if (FIXNUM_P(y)) {
          if (FIX2LONG(x) <= FIX2LONG(y)) { return Qtrue; }
          return Qfalse;
        } else {
          return rb_num_coerce_relop(x, y);
        }
      }
    END
  end
  
  # CHECK
  def fix_lt
    add_function :rb_num_coerce_relop
    <<-END
      function fix_lt(x, y) {
        if (FIXNUM_P(y)) {
          if (FIX2LONG(x) < FIX2LONG(y)) { return Qtrue; }
          return Qfalse;
        } else {
          return rb_num_coerce_relop(x, y);
        }
      }
    END
  end
  
  # CHECK
  def fix_minus
    add_function :rb_float_new, :rb_num_coerce_bin
    <<-END
      function fix_minus(x, y) {
        if (FIXNUM_P(y)) { return LONG2NUM(FIX2LONG(x) - FIX2LONG(y)); }
        if (TYPE(y) == T_FLOAT) { return rb_float_new(FIX2LONG(x) - y.value); }
        return rb_num_coerce_bin(x, y);
      }
    END
  end
  
  # modified fixdivmod to return array instead of using pointers
  def fix_mod
    add_function :fixdivmod, :rb_num_coerce_bin
    <<-END
      function fix_mod(x, y) {
        if (FIXNUM_P(y)) {
          var mod = fixdivmod(FIX2LONG(x), FIX2LONG(y))[1];
          return LONG2NUM(mod);
        }
        return rb_num_coerce_bin(x, y);
      }
    END
  end
  
  # CHECK
  def fix_odd_p
    <<-END
      function fix_odd_p(num) {
        return (num & 2) ? Qtrue : Qfalse;
      }
    END
  end
  
  # CHECK
  def fix_plus
    add_function :rb_float_new, :rb_num_coerce_bin
    <<-END
      function fix_plus(x, y) { 
        if (FIXNUM_P(y)) { return LONG2NUM(FIX2LONG(x) + FIX2LONG(y)); }
        if (TYPE(y) == T_FLOAT) { return rb_float_new(FIX2LONG(x) + y.value); }
        return rb_num_coerce_bin(x, y);
      }
    END
  end
  
  # verbatim
  def fix_to_f
    <<-END
      function fix_to_f(num) {
        return rb_float_new(FIX2LONG(num));
      }
    END
  end
  
  # CHECK
  def fix_to_s
    add_functions :rb_scan_args, :rb_fix2str
    <<-END
      function fix_to_s(argc, argv, x) {
        var b = rb_scan_args(argc, argv, "01")[0];
        var base = (argc === 0) ? 10 : NUM2INT(b);
        return rb_fix2str(x, base);
      }
    END
  end
  
  # verbatim
  def fix_uminus
    <<-END
      function fix_uminus(num) {
        return LONG2NUM(-FIX2LONG(num));
      }
    END
  end
  
  # CHECK
  def fix_zero_p
    <<-END
      function fix_zero_p(num) {
        return (FIX2LONG(num) === 0) ? Qtrue : Qfalse
      }
    END
  end
  
  # modified to return array [div, mod] instead of using pointers
  def fixdivmod
    add_function :rb_num_zerodiv
    <<-END
      function fixdivmod(x, y) {
        var div;
        var mod;
        if (y == 0) { rb_num_zerodiv(); }
        if (y < 0) {
          if (x < 0) {
            div = -x / -y;
          } else {
            div = -(x / -y);
          }
        } else {
          if (x < 0) {
            div = -(-x / y);
          } else {
            div = x / y;
          }
        }
        mod = x - div * y;
        if ((mod < 0 && y > 0) || (mod > 0 && y < 0)) {
          mod += y;
          div -= 1;
        }
        return [div, mod];
      }
    END
  end
  
  # CHECK
  def rb_fix2str
    add_function :rb_raise, :rb_str_new
    <<-END
      function rb_fix2str(x, base) {
        if (base < 2 || 36 < base) { rb_raise(rb_eArgError, "illegal radix %d", base); }
        return rb_str_new(FIX2LONG(x).toString(base));
      }
    END
  end
  
  # CHECK
  def rb_fix_new
    <<-END
      function rb_fix_new(v) {
        return INT2FIX(i);
      }
    END
  end
end
