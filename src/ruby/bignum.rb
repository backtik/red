class Red::MethodCompiler
  # verbatim
  def big2dbl
    <<-END
      function big2dbl(x) {
        var d = 0.0;
        var i = x.len;
        var ds = BDIGITS(x);
        while (i--) {
          d = ds[i] + BIGRAD * d;
        }
        if (!x.sign) { d = -d; }
        return d;
      }
    END
  end
  
  # CHECK THIS - IT'S WRONG
  def bigfixize
    <<-END
      function bigfixize(x) {
        var len = x.len;
        var ds = BDIGITS(x);
        if (len * SIZEOF_BDIGITS <= sizeof(VALUE)) {
          var num = 0;
          while (len--) {
            num = BIGUP(num) + ds[len];
          }
          if (num >= 0) {
            if (x.sign) {
              if (POSFIXABLE(num)) { return LONG2FIX(num); }
            } else {
              if (NEGFIXABLE(-num)) { return LONG2FIX(-num); }
            }
          }
        }
        return x;
      }
    END
  end
  
  # verbatim
  def bignorm
    add_function :bigfixize, :bigtrunc
    <<-END
      function bignorm(x) {
        if (!FIXNUM_P(x) && (TYPE(x) == T_BIGNUM)) { x = bigfixize(bigtrunc(x)); }
        return x;
      }
    END
  end
  
  # CHECK THIS - PROBABLY WRONG
  def bigtrunc
    <<-END
      function bigtrunc(x) {
        var len = x.len;
        ds = BDIGITS(x);
        if (len == 0) { return x; }
        while (--len && !ds[len]);
        x.len = ++len;
        return x;
      }
    END
  end
  
  # CHECK THIS - DON'T KNOW WHAT "digits[i]" IS SUPPOSED TO DO
  def dbl2big
    add_function :isinf, :isnan, :rb_raise, :bignew
    <<-END
      function dbl2big(d) {
        var i = 0;
        var c;
        var digits;
        var z;
        var u = (d < 0) ? -d : d;
        if (isinf(d)) { rb_raise(rb_eFloatDomainError, d < 0 ? "-Infinity" : "Infinity"); }
        if (isnan(d)) { rb_raise(rb_eFloatDomainError, "NaN"); }
        while (!POSFIXABLE(u) || (0 !== u)) {
          u /= (BIGRAD);
          i++;
        }
        z = bignew(i, d >= 0);
        digits = BDIGITS(z);
        while (i--) {
          u *= BIGRAD;
          c = u;
          u -= c;
          digits[i] = c;
        }
        return z;
      }
    END
  end
  
  # removed warning
  def rb_big2dbl
    <<-END
      function rb_big2dbl(x) {
        return big2dbl(x);
      }
    END
  end
  
  # verbatim
  def rb_big_norm
    <<-END
      function rb_big_norm(x) {
        return bignorm(x);
      }
    END
  end
  
  # verbatim
  def rb_dbl2big
    add_function :bignorm, :dbl2big
    <<-END
      function rb_dbl2big(d) {
        return bignorm(dbl2big(d));
      }
    END
  end
end
