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
  
  # removed 'len' handling
  def bignew
    <<-END
      function bignew_1(klass, len, sign) {
        var big = NEWOBJ();
        OBJSETUP(big, klass, T_BIGNUM);
        big.sign = sign ? 1 : 0;
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
  
  # CHECK THIS - DON'T KNOW WHAT 'digits[i]' IS SUPPOSED TO DO
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
  def rb_big2str
    add_function :rb_big2str0
    <<-END
      function rb_big2str(x, base) {
        return rb_big2str0(x, base, Qtrue);
      }
    END
  end
  
  def rb_big2str0
    add_function :rb_raise, :rb_fix2str, :rb_big_clone, :rb_str_new
    <<-END
      function rb_big2str0(x, base, trim) {
        if (FIXNUM_P(x)) { return rb_fix2str(x, base); }
        var i = x.digits.length;
      //if (BIGZEROP(x)) { return rb_str_new2("0"); }
        if (base < 2 || base > 36) { rb_raise(rb_eArgError, "illegal radix %d", base); }
        var hbase = base * base;
      //hbase *= hbase;
        var t = rb_big_clone(x);
        var ds = BDIGITS(t);
        var ss = rb_str_new();
        var s = ss.ptr;
        s += x.sign ? '+' : '-';
      //TRAP_BEG;
      //while (i && j > 1) {
        while (i) {
          var k = i;
          var num = 0;
          while (k--) {
            num = BIGUP(num) + ds[k];
            ds[k] = (num / hbase);
            num %= hbase;
          }
          if (trim && (ds[i - 1] === 0)) { i--; }
          k = 2;
          while (k--) {
            s = ruby_digitmap[num % base] + s;
            num /= base;
          //if (!trim && j <= 1) { break; }
            if (trim && (i === 0) && (num === 0)) { break; }
          }
        }
      //TRAP_END;
        return ss;
      }
    END
  end
  
  # verbatim
  def rb_big_clone
    add_function :bignew_1
    <<-END
      function rb_big_clone(x) {
        var z = bignew_1(CLASS_OF(x), x.digits.length, x.sign);
        MEMCPY(BDIGITS(z), BDIGITS(x), x.digits.length);
        return z;
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
        if (FIXABLE(n)) { return LONG2FIX(n); }
        return rb_int2big(n);
      }
    END
  end
  
  # verbatim
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
        return big;
      }
    END
  end
end
