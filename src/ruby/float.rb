class Red::MethodCompiler
  # modified output to return array of [div, mod] instead of using pointers
  def flodivmod
    add_function :fmod, :isinf, :isnan
    <<-END
      function flodivmod(x, y) {
        var div;
        var mod = fmod(x, y);
        if (isinf(x) && !isinf(y) && !isnan(y)) {
          div = x;
        } else {
          div = (x - mod) / y;
        }
        if ((y * mod) < 0) {
          mod += y;
          div -= 1.0;
        }
        return [div, mod];
      }
    END
  end
  
  # replaced 'fabs' with 'Math.abs'
  def flo_abs
    add_function :rb_float_new
    <<-END
      function flo_abs(flt) {
        return rb_float_new(Math.abs(flt.value));
      }
    END
  end
  
  # verbatim
  def flo_cmp
    add_function :rb_big2dbl, :rb_num_coerce_cmp, :rb_dbl_cmp
    <<-END
      function flo_cmp(x, y) {
        var b;
        var a = x.value;
        switch (TYPE(y)) {
          case T_FIXNUM:
            b = FIX2LONG(y);
            break;
          case T_BIGNUM:
            b = rb_big2dbl(y);
            break;
          case T_FLOAT:
            b = y.value;
            break;
          default:
            return rb_num_coerce_cmp(x, y);
        }
        return rb_dbl_cmp(a, b);
      }
    END
  end
  
  # verbatim
  def flo_coerce
    add_function :rb_assoc_new, :rb_Float
    <<-END
      function flo_coerce(x, y) {
        return rb_assoc_new(rb_Float(y), x);
      }
    END
  end
  
  # verbatim
  def flo_div
    add_function :rb_float_new, :rb_big2dbl, :rb_num_coerce_bin
    <<-END
      function flo_div(x, y) {
        switch (TYPE(y)) {
          case T_FIXNUM:
            return rb_float_new(x.value / FIX2LONG(y));
          case T_BIGNUM:
            return rb_float_new(x.value / rb_big2dbl(y));
          case T_FLOAT:
            return rb_float_new(x.value / y.value);
          default:
            return rb_num_coerce_bin(x, y);
        }
      }
    END
  end
  
  # verbatim
  def flo_divmod
    add_function :rb_big2dbl, :rb_num_coerce_bin, :flodivmod, :rb_dbl2big, :rb_float_new, :rb_assoc_new
    <<-END
      function flo_divmod(x, y) {
        var fy;
        switch (TYPE(y)) {
          case T_FIXNUM:
            fy = FIX2LONG(y);
            break;
          case T_BIGNUM:
            fy = rb_big2dbl(y);
            break;
          case T_FLOAT:
            fy = y.value;
            break;
          default:
            return rb_num_coerce_bin(x, y);
        }
        var tmp = flodivmod(x.value, fy);
        var div = tmp[0];
        var mod = tmp[1];
        var a;
        if (FIXABLE(div)) {
          a = LONG2FIX(Math.round(div));
        } else {
          a = rb_dbl2big(div);
        }
        var b = rb_float_new(mod);
        return rb_assoc_new(a, b);
      }
    END
  end
  
  # EMPTY
  def flo_eq
    <<-END
      function flo_eq() {}
    END
  end
  
  # verbatim
  def flo_eql
    add_function :isnan
    <<-END
      function flo_eql(x, y) {
        if (TYPE(y) == T_FLOAT) {
          var a = x.value;
          var b = y.value;
          if (isnan(a) || isnan(b)) { return Qfalse; }
          if (a == b) { return Qtrue; }
        }
        return Qfalse;
      }
    END
  end
  
  def flo_ge
    add_function :rb_big2dbl, :isnan, :rb_num_coerce_relop
    <<-END
      function flo_ge(x, y) {
        var b;
        var a = x.value;
        switch (TYPE(y)) {
          case T_FIXNUM:
            b = FIX2LONG(y);
            break;
          case T_BIGNUM:
            b = rb_big2dbl(y);
            break;
          case T_FLOAT:
            b = y.value;
            if (isnan(b)) { return Qfalse; }
            break;
          default:
            return rb_num_coerce_relop(x, y);
        }
        if (isnan(a)) { return Qfalse; }
        return (a >= b) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def flo_gt
    add_function :rb_big2dbl, :isnan, :rb_num_coerce_relop
    <<-END
      function flo_gt(x, y) {
        var b;
        var a = x.value;
        switch (TYPE(y)) {
          case T_FIXNUM:
            b = FIX2LONG(y);
            break;
          case T_BIGNUM:
            b = rb_big2dbl(y);
            break;
          case T_FLOAT:
            b = y.value;
            if (isnan(b)) { return Qfalse; }
            break;
          default:
            return rb_num_coerce_relop(x, y);
        }
        if (isnan(a)) { return Qfalse; }
        return (a > b) ? Qtrue : Qfalse;
      }
    END
  end
  
  # NEEDS WORK
  def flo_hash
    <<-END
      function flo_hash(num) {
        var hash = 0;
        var d = num.value;
        var c = d.toString().replace(/[.]/,'');
        for (var i = 0; i < 16; ++i) { // sizeof(double) taken to be 16
          hash = ((hash * 971) ^ (c.charCodeAt(i))) & 0x7FFFFFFF;
        }
        if (hash < 0) { hash = -hash; }
        return INT2FIX(hash);
      }
    END
  end
  
  # verbatim
  def flo_le
    add_function :rb_big2dbl, :isnan, :rb_num_coerce_relop
    <<-END
      function flo_le(x, y) {
        var b;
        var a = x.value;
        switch (TYPE(y)) {
          case T_FIXNUM:
            b = FIX2LONG(y);
            break;
          case T_BIGNUM:
            b = rb_big2dbl(y);
            break;
          case T_FLOAT:
            b = y.value;
            if (isnan(b)) { return Qfalse; }
            break;
          default:
            return rb_num_coerce_relop(x, y);
        }
        if (isnan(a)) { return Qfalse; }
        return (a <= b) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def flo_lt
    add_function :rb_big2dbl, :isnan, :rb_num_coerce_relop
    <<-END
      function flo_lt(x, y) {
        var b;
        var a = x.value;
        switch (TYPE(y)) {
          case T_FIXNUM:
            b = FIX2LONG(y);
            break;
          case T_BIGNUM:
            b = rb_big2dbl(y);
            break;
          case T_FLOAT:
            b = y.value;
            if (isnan(b)) { return Qfalse; }
            break;
          default:
            return rb_num_coerce_relop(x, y);
        }
        if (isnan(a)) { return Qfalse; }
        return (a < b) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def flo_minus
    add_function :rb_float_new, :rb_num_coerce_bin, :rb_big2dbl
    <<-END
      function flo_minus(x, y) {
        switch (TYPE(y)) {
          case T_FIXNUM:
            return rb_float_new(x.value - FIX2LONG(y));
          case T_BIGNUM:
            return rb_float_new(x.value - rb_big2dbl(y));
          case T_FLOAT:
            return rb_float_new(x.value - y.value);
          default:
            return rb_num_coerce_bin(x, y);
        }
      }
    END
  end
  
  # modified 'flodivmod' to return array instead of using pointers
  def flo_mod
    add_function :rb_big2dbl, :rb_num_coerce_bin, :flodivmod, :rb_float_new
    <<-END
      function flo_mod(x, y) {
        var fy;
        switch (TYPE(y)) {
          case T_FIXNUM:
            fy = FIX2LONG(y);
            break;
          case T_BIGNUM:
            fy = rb_big2dbl(y);
            break;
          case T_FLOAT:
            fy = y.value;
            break;
          default:
            return rb_num_coerce_bin(x, y);
        }
        var mod = flodivmod(x.value, fy)[1];
        return rb_float_new(mod);
      }
    END
  end
  
  # verbatim
  def flo_mul
    add_function :rb_float_new, :rb_num_coerce_bin, :rb_big2dbl
    <<-END
      function flo_mul(x, y) {
        switch (TYPE(y)) {
          case T_FIXNUM:
            return rb_float_new(x.value * FIX2LONG(y));
          case T_BIGNUM:
            return rb_float_new(x.value * rb_big2dbl(y));
          case T_FLOAT:
            return rb_float_new(x.value * y.value);
          default:
            return rb_num_coerce_bin(x, y);
        }
      }
    END
  end
  
  # verbatim
  def flo_plus
    add_function :rb_float_new, :rb_num_coerce_bin, :rb_big2dbl
    <<-END
      function flo_plus(x, y) {
        switch (TYPE(y)) {
          case T_FIXNUM:
            return rb_float_new(x.value + FIX2LONG(y));
          case T_BIGNUM:
            return rb_float_new(x.value + rb_big2dbl(y));
          case T_FLOAT:
            return rb_float_new(x.value + y.value);
          default:
            return rb_num_coerce_bin(x, y);
        }
      }
    END
  end
  
  # verbatim
  def flo_to_f
    <<-END
      function flo_to_f(num) {
        return num;
      }
    END
  end
  
  # NEEDS WORK, changed rb_str_new2 to rb_str_new
  def flo_to_s
    add_function :isinf, :isnan
    <<-END
      function flo_to_s(flt) {
        var e;
        var value = flt.value;
        var p = 0;
        if (isinf(value)) {
          return rb_str_new((value < 0) ? "-Infinity" : "Infinity");
        } else if (isnan(value)) {
          return rb_str_new("NaN");
        }
        var buf = jsprintf("%.15g", [value]); /* ensure to print decimal point */
        if (!((e = buf.indexOf('e')) > 0)) { e = buf.length; }
        if (!ISDIGIT(buf[e - 1])) { /* reformat if ended with decimal point (ex 111111111111111.) */
          buf = jsprintf("%.14e", [value]);
          if (!((e = buf.indexOf('e')) > 0)) { e = buf.length; }
        }
        p = e;
        while ((buf[p - 1] == '0') && ISDIGIT(buf[p - 2])) { p--; }
        buf[p] = buf[e]; // was 'memmove(p, e, strlen(e) + 1)'
        return rb_str_new(buf);
      }
    END
  end
  
  # verbatim
  def flo_truncate
    add_function :rb_dbl2big
    <<-END
      function flo_truncate(num) {
        var f = num.value;
        if (f > 0.0) { f = Math.floor(f); }
        if (f < 0.0) { f = Math.ceil(f); }
        if (!FIXABLE(f)) { return rb_dbl2big(f); }
        var val = f;
        return LONG2FIX(val);
      }
    END
  end
  
  # verbatim
  def flo_uminus
    add_function :rb_float_new
    <<-END
      function flo_uminus(flt) {
        return rb_float_new(-flt.value);
      }
    END
  end
  
  # from http://kevin.vanzonneveld.net/techblog/article/javascript_equivalent_for_phps_fmod/
  def fmod
    <<-END
      function fmod(x, y) {
        var tmp = x.toExponential().match(/^.\.?(.*)e(.+)$/);
        var p = parseInt(tmp[2]) - (tmp[1]+'').length;
        tmp = y.toExponential().match(/^.\.?(.*)e(.+)$/);
        var pY = parseInt(tmp[2]) - (tmp[1]+'').length;
        if (pY > p) { p = pY; }
        var tmp2 = x % y;
        if ((p < -100) || (p > 20)) {
          var l = Math.round(Math.log(tmp2) / Math.log(10));
          var l2 = Math.pow(10, l);
          return (tmp2 / l2).toFixed(l-p) * l2;
        } else {
          return parseFloat(tmp2.toFixed(-p));
        }
      }
    END
  end
  
  # modified to use simple comparison to JS infinity
  def isinf
    <<-END
      function isinf(d) {
        return (d == Infinity) || (d == -Infinity);
      }
    END
  end
  
  # modified to use JS NaN comparison
  def isnan
    <<-END
      function isnan(d) {
        return String(d) === 'NaN';
      }
    END
  end
  
  # added; returns array [integer_part, fractional_part]
  def modf
    <<-END
      function modf(x) {
        var i = (x > 0) ? Math.floor(x) : Math.ceil(x);
        var f = (x + 1e-16) - (i - 1e-16);
        return [i, f];
      }
    END
  end
  
  # verbatim
  def rb_float_new
    <<-END
      function rb_float_new(d) {
        NEWOBJ(flt);
        OBJSETUP(flt, rb_cFloat, T_FLOAT);
        flt.value = d;
        return flt;
      }
    END
  end
end
