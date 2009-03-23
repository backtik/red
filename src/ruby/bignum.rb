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
  
  def bigadd
    add_function :bigsub, :bignew
    <<-END
      function bigadd(x, y, sign) {
        var z;
        var len;
        sign = (sign == y.sign);
        if (x.sign != sign) {
          if (sign) { return bigsub(y, x); }
          return bigsub(x, y);
        }
        if (x.len > y.len) {
          len = x.len + 1;
          z = x; x = y; y = z;
        } else {
          len = y.len + 1;
        }
        z = bignew(len, sign);
        len = x.len;
        for (var i = 0, num = 0; i < len; i++) {
          num += BDIGITS(x)[i] + BDIGITS(y)[i];
          BDIGITS(z)[i] = BIGLO(num);
          num = BIGDN(num);
        }
        len = y.len;
        while (num && i < len) {
          num += BDIGITS(y)[i];
          BDIGITS(z)[i++] = BIGLO(num);
          num = BIGDN(num);
        }
        while (i < len) {
          BDIGITS(z)[i] = BDIGITS(y)[i];
          i++;
        }
        BDIGITS(z)[i] = num;
        return z;
      }
    END
  end
  
  # CHECK THIS - IT'S WRONG
  def bigfixize
    <<-END
      function bigfixize(x) {
        var len = x.len;
        var ds = BDIGITS(x);
        if (len * 2 <= (1 << 31)) {
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
  
  # verbatim (renamed to 'bignew' so that 'add_function :bignew' correctly adds 'bignew_1', which is added by PreProcessor)
  def bignew
    <<-END
      function bignew_1(klass, len, sign) {
        var big = NEWOBJ();
        OBJSETUP(big, klass, T_BIGNUM);
        big.sign = sign ? 1 : 0;
        big.len = len;
        big.digits = [];
        return big;
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
  
  # verbatim
  def bigsub
    add_function :bignew
    <<-END
      function bigsub(x, y) {
        var z = 0;
        var i = x.len;
        /* if x is larger than y, swap */
        if (x.len < y.len) {
          z = x; x = y; y = z; /* swap x y */
        } else if (x.len == y.len) {
          while (i > 0) {
            i--;
            if (BDIGITS(x)[i] > BDIGITS(y)[i]) { break; }
            if (BDIGITS(x)[i] < BDIGITS(y)[i]) {
              z = x; x = y; y = z; /* swap x y */
              break;
            }
          }
        }
        z = bignew(x.len, z === 0);
        var zds = BDIGITS(z);
        for (var i = 0, num = 0, l = y.len; i < l; i++) {
          num += BDIGITS(x)[i] - BDIGITS(y)[i];
          zds[i] = BIGLO(num);
          num = BIGDN(num);
        }
        while (num && (i < x.len)) {
          num += BDIGITS(x)[i];
          zds[i++] = BIGLO(num);
          num = BIGDN(num);
        }
        while (i < x.len) {
          zds[i] = BDIGITS(x)[i];
          i++;
        }
        return z;
      }
    END
  end
  
  # CHECK THIS - PROBABLY WRONG
  def bigtrunc
    <<-END
      function bigtrunc(x) {
        var len = x.len;
        ds = BDIGITS(x);
        if (len === 0) { return x; }
        while (--len && !ds[len]);
        x.len = ++len;
        return x;
      }
    END
  end
  
  # verbatim
  def bigzero_p
    <<-END
      function bigzero_p(x) {
        for (var i = 0, l = x.len; i < l; ++i) {
          if (BDIGITS(x)[i]) { return 0; }
        }
        return 1;
      }
    END
  end
  
  # CHECK THIS - DON'T KNOW WHAT 'digits[i]' IS SUPPOSED TO DO
  def dbl2big
    add_function :isinf, :isnan, :rb_raise, :bignew
    <<-END
      function dbl2big(d) {
        var i = 0;
        var c;
        var digits;
        var u = (d < 0) ? -d : d;
        if (isinf(d)) { rb_raise(rb_eFloatDomainError, d < 0 ? "-Infinity" : "Infinity"); }
        if (isnan(d)) { rb_raise(rb_eFloatDomainError, "NaN"); }
        while (!POSFIXABLE(u) || (0 !== u)) {
          u /= (BIGRAD);
          i++;
        }
        var z = bignew(i, d >= 0);
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
  def rb_big2str
    add_function :rb_big2str0
    <<-END
      function rb_big2str(x, base) {
        return rb_big2str0(x, base, Qtrue);
      }
    END
  end
  
  # modified string handling
  def rb_big2str0
    add_function :rb_raise, :rb_fix2str, :rb_big_clone, :rb_str_new, :bigzero_p
    <<-END
      function rb_big2str0(x, base, trim) {
        if (FIXNUM_P(x)) { return rb_fix2str(x, base); }
        var i = x.len;
        if (BIGZEROP(x)) { return rb_str_new("0"); }
        if ((base < 2) || (base > 36)) { rb_raise(rb_eArgError, "illegal radix %d", base); }
        var hbase = base * base;
        var t = rb_big_clone(x);
        var ds = BDIGITS(t);
        var ss = rb_str_new();
      //TRAP_BEG;
        while (i) {
          var k = i;
          var num = 0;
          while (k--) {
            num = BIGUP(num) + ds[k];
            ds[k] = Math.floor(num / hbase);
            num %= hbase;
          }
          if (trim && (ds[i - 1] === 0)) { i--; }
          k = 2;
          while (k--) {
            ss.ptr = ruby_digitmap[num % base] + ss.ptr;
            num = Math.floor(num / base);
            if (trim && (i === 0) && (num === 0)) { break; }
          }
        }
      //TRAP_END;
        if (!x.sign) { ss.ptr = '-' + ss.ptr; }
        return ss;
      }
    END
  end
  
  # verbatim
  def rb_big_clone
    add_function :bignew
    <<-END
      function rb_big_clone(x) {
        var z = bignew_1(CLASS_OF(x), x.len, x.sign);
        MEMCPY(BDIGITS(z), BDIGITS(x), x.len);
        return z;
      }
    END
  end
  
  # verbatim
  def rb_big_minus
    add_function :rb_int2big, :bignorm, :rb_float_new, :rb_num_coerce_bin, :bigadd, :rb_big2dbl
    <<-END
      function rb_big_minus(x, y) {
        switch (TYPE(y)) {
          case T_FIXNUM:
            y = rb_int2big(FIX2LONG(y));
            /* fall through */
          case T_BIGNUM:
            return bignorm(bigadd(x, y, 0));
          case T_FLOAT:
            return rb_float_new(rb_big2dbl(x) - y.value);
          default:
            return rb_num_coerce_bin(x, y);
        }
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
  def rb_big_to_s
    add_function :rb_scan_args, :rb_big2str
    <<-END
      function rb_big_to_s(argc, argv, x) {
        var base;
        var tmp = rb_scan_args(argc, argv, '01');
        var b = tmp[1];
        if (argc === 0) {
          base = 10;
        } else {
          base = NUM2INT(b);
        }
        return rb_big2str(x, base);
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
  
  # verbatim
  def rb_int2big
    add_function :rb_uint2big
    <<-END
      function rb_int2big(n) {
        var neg = 0;
        if (n < 0) {
          n = -n;
          neg = 1;
        }
        var big = rb_uint2big(n);
        if (neg) { big.sign = 0; }
        return big;
      }
    END
  end
  
  # verbatim
  def rb_int2inum
    add_function :rb_int2big
    <<-END
      function rb_int2inum(n) {
        return (FIXABLE(n)) ? LONG2FIX(n) : rb_int2big(n);
      }
    END
  end
  
  # CHECK
  def rb_uint2big
    <<-END
      function rb_uint2big(n) {
        var num = n;
        var i = 0;
        var big = bignew(DIGSPERLONG, 1);
        var digits = BDIGITS(big);
        while (i < DIGSPERLONG) {
          digits[i++] = BIGLO(num);
          num = BIGDN(num);
        }
        i = DIGSPERLONG;
        while (--i && !digits[i]) {};
        big.len = i + 1;
        return big;
      }
    END
  end
end
