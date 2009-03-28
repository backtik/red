class Red::MethodCompiler
  # removed a check against 'sizeof(VALUE)*CHAR_BIT'
  def fix_aref
    add_function :fix_coerce, :rb_big_norm
    <<-END
      function fix_aref(fix, idx) {
        var val = FIX2LONG(fix);
        if (!FIXNUM_P(idx = fix_coerce(idx))) {
          idx = rb_big_norm(idx);
          if (!FIXNUM_P(idx)) {
            if (!idx.sign || val >= 0) { return INT2FIX(0); }
            return INT2FIX(1);
          }
        }
        var i = FIX2LONG(idx);
        if (i < 0) { return INT2FIX(0); }
      //if (sizeof(VALUE)*CHAR_BIT-1 < i) {
      //  if (val < 0) { return INT2FIX(1); }
      //  return INT2FIX(0);
      //}
        if (val & (1 << i)) { return INT2FIX(1); }
        return INT2FIX(0);
      }
    END
  end
  
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
  
  # verbatim
  def fix_coerce
    add_function :rb_to_int
    <<-END
      function fix_coerce(x) {
        while (!FIXNUM_P(x) && (TYPE(x) != T_BIGNUM)) { x = rb_to_int(x); }
        return x;
      }
    END
  end
  
  # modified fixdivmod to return array instead of using pointers
  def fix_div
    add_function :fixdivmod, :rb_num_coerce_bin
    <<-END
      function fix_div(x, y) {
        if (FIXNUM_P(y)) {
          var tmp = fixdivmod(FIX2LONG(x), FIX2LONG(y));
          return LONG2NUM(tmp[0]);
        }
        return rb_num_coerce_bin(x, y);
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
    add_function :fixdivmod, :rb_num_coerce_bin, :rb_int2inum
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
  
  # verbatim
  def fix_mul
    add_function :rb_big_mul, :rb_int2big, :rb_num_coerce_bin
    <<-END
      function fix_mul(x, y) {
        if (FIXNUM_P(y)) {
          var a = FIX2LONG(x);
          if (a === 0) { return x; }
          var b = FIX2LONG(y);
          var c = a * b;
          var r = LONG2FIX(c);
          if ((FIX2LONG(r) != c) || ((c / a) != b)) { r = rb_big_mul(rb_int2big(a), rb_int2big(b)); }
          return r;
        }
        if (TYPE(y) == T_FLOAT) { return rb_float_new(FIX2LONG(x) * y.value); }
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
  
  # verbatim
  def fix_or
    add_function :fix_coerce, :rb_big_or
    <<-END
      function fix_or(x, y) {
        if (!FIXNUM_P(y = fix_coerce(y))) { return rb_big_or(y, x); }
        var val = FIX2LONG(x) | FIX2LONG(y);
        return LONG2NUM(val);
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
        var b = rb_scan_args(argc, argv, '01')[0];
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
        if (y === 0) { rb_num_zerodiv(); }
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
        var mod = x - (div &= 0x7FFFFFFF) * y;
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
  
  # verbatim
  def rb_fix_lshift
    add_function :rb_big_lshift, :rb_int2big, :fix_rshift, :fix_lshift
    <<-END
      function rb_fix_lshift(x, y) {
        long val, width;
        var val = NUM2LONG(x);
        if (!FIXNUM_P(y)) { return rb_big_lshift(rb_int2big(val), y); }
        width = FIX2LONG(y);
        if (width < 0) { return fix_rshift(val, -width); }
        return fix_lshift(val, width);
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
