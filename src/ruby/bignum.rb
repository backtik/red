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
  
  # modified to return array [div, mod] instead of using pointers
  def bigdivmod
    <<-END
      function bigdivmod(x, y) {
        var tmp = bigdivrem(x, y);
        var div = tmp[0];
        var mod = tmp[1];
        if ((x.sign != y.sign) && !BIGZEROP(mod)) {
          return [bigadd(div, rb_int2big(1), 0), bigadd(mod, y, 1)];
        } else {
          return [div, mod];
        }
      }
    END
  end
  
  # modified to return array [div, mod] instead of using pointers
  def bigdivrem
    add_function :rb_num_zerodiv, :rb_big_clone, :rb_int2big, :bignew, :rb_uint2big
    <<-END
      function bigdivrem(x, y) {
        var div;
        var mod;
        var z;
        var zds;
        var dd;
        var t2;
        var i;
        var j;
        var yy;
        var tds;
        var nx = x.len;
        var ny = y.len;
        if (BIGZEROP(y)) { rb_num_zerodiv(); }
        if ((nx < ny) || ((nx == ny) && (BDIGITS(x)[nx - 1] < BDIGITS(y)[ny - 1]))) { return [rb_int2big(0), x]; }
        var xds = BDIGITS(x);
        var yds = BDIGITS(y);
        if (ny == 1) {
          z = rb_big_clone(x);
          zds = BDIGITS(z);
          dd = yds[0];
          t2 = 0;
          i = nx;
          while (i--) {
            t2 = BIGUP(t2) + zds[i];
            zds[i] = (t2 / dd);
            t2 %= dd;
          }
          z.sign = (x.sign == y.sign) ? 1 : 0;
          mod = rb_uint2big(t2);
          mod.sign = x.sign;
          return [z, mod];
        }
        z = bignew((nx == ny) ? nx + 2 : nx + 1, (x.sign == y.sign) ? 1 : 0);
        zds = BDIGITS(z);
        if (nx == ny) { zds[nx + 1] = 0; }
        while (!yds[ny - 1]) {
          ny--;
        }
        dd = 0;
        var q = yds[ny - 1];
        while ((q & (1 << (BITSPERDIG - 1))) === 0) {
          q <<= 1;
          dd++;
        }
        if (dd) {
          yy = rb_big_clone(y);
          tds = BDIGITS(yy);
          j = 0;
          t2 = 0;
          while (j < ny) {
            t2 += yds[j] << dd;
            tds[j++] = BIGLO(t2);
            t2 = BIGDN(t2);
          }
          yds = tds;
          j = 0;
          t2 = 0;
          while (j<nx) {
            t2 += xds[j] << dd;
            zds[j++] = BIGLO(t2);
            t2 = BIGDN(t2);
          }
          zds[j] = t2;
        } else {
          zds[nx] = 0;
          j = nx;
          while (j--) {
            zds[j] = xds[j];
          }
        }
        j = (nx == ny) ? nx + 1 : nx;
        do {
          if (zds[j] == yds[ny-1]) {
            q = BIGRAD - 1;
          } else {
            q = ((BIGUP(zds[j]) + zds[j - 1]) / yds[ny-1]);
          }
          if (q) {
            i = 0;
            var num = 0;
            t2 = 0;
            do { /* multiply and subtract */
              t2 += yds[i] * q;
              var ee = num - BIGLO(t2);
              num = zds[j - ny + i] + ee;
              if (ee) { zds[j - ny + i] = BIGLO(num); }
              num = BIGDN(num);
              t2 = BIGDN(t2);
            } while (++i < ny);
            num += zds[j - ny + i] - t2; /* borrow from high digit; don't update */
            while (num) { /* "add back" required */
              i = 0;
              num = 0;
              q--;
              do {
                var ee = num + yds[i];
                num = zds[j - ny + i] + ee;
                if (ee) { zds[j - ny + i] = BIGLO(num); }
                num = BIGDN(num);
              } while (++i < ny);
              num--;
            }
          }
          zds[j] = q;
        } while (--j >= ny);
        /* move quotient down in z */
        div = rb_big_clone(z);
        zds = BDIGITS(div);
        j = ((nx == ny) ? nx + 2 : nx + 1) - ny;
        for (i = 0; i < j; ++i) {
          zds[i] = zds[i + ny];
        }
        div.len = i;
        /* normalize remainder */
        mod = rb_big_clone(z);
        zds = BDIGITS(mod);
        while (--ny && !zds[ny]) {};
        ++ny;
        if (dd) {
          t2 = 0; i = ny;
          while (i--) {
            t2 = (t2 | zds[i]) >> dd;
            q = zds[i];
            zds[i] = BIGLO(t2);
            t2 = BIGUP(q);
          }
        }
        mod.len = ny;
        mod.sign = x.sign;
        return [div, mod];
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
  
  # verbatim (renamed to 'bignew' so that 'add_function :bignew' correctly adds 'bignew_1', which is added by Preprocessor)
  def bignew
    <<-END
      function bignew_1(klass, len, sign) {
        NEWOBJ(big);
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
  
  # verbatim
  def get2comp
    <<-END
      function get2comp(x) {
        var i = x.len;
        var ds = BDIGITS(x);
        if (!i) { return; }
        while (i--) {
          ds[i] = ~ds[i];
        }
        i = 0;
        var num = 1;
        do {
          num += ds[i];
          ds[i++] = BIGLO(num);
          num = BIGDN(num);
        } while (i < x.len);
        if (num != 0) {
        //REALLOC_N(RBIGNUM(x)->digits, BDIGIT, ++RBIGNUM(x)->len);
          ds = BDIGITS(x);
          ds[x.len - 1] = x.sign ? ~0 : 1;
        }
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
  def rb_big_and
    add_function :rb_to_int, :rb_int2big, :rb_big_clone, :get2comp, :bignew, :bignorm
    <<-END
      function rb_big_and(xx, yy) {
        var l1;
        var l2;
        var ds1;
        var ds2;
        var sign;
        var x = xx;
        var y = rb_to_int(yy);
        if (FIXNUM_P(y)) { y = rb_int2big(FIX2LONG(y)); }
        if (!y.sign) {
          y = rb_big_clone(y);
          get2comp(y);
        }
        if (!x.sign) {
          x = rb_big_clone(x);
          get2comp(x);
        }
        if (x.len > y.len) {
          l1 = y.len;
          l2 = x.len;
          ds1 = BDIGITS(y);
          ds2 = BDIGITS(x);
          sign = y.sign;
        } else {
          l1 = x.len;
          l2 = y.len;
          ds1 = BDIGITS(x);
          ds2 = BDIGITS(y);
          sign = x.sign;
        }
        var z = bignew(l2, x.sign || y.sign);
        var zds = BDIGITS(z);
        for (var i = 0; i < l1; ++i) {
          zds[i] = ds1[i] & ds2[i];
        }
        for (; i < l2; ++i) {
          zds[i] = sign ? 0 : ds2[i];
        }
        if (!z.sign) { get2comp(z); }
        return bignorm(z);
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
  def rb_big_cmp
    add_function :rb_int2big, :rb_dbl_cmp, :rb_big2dbl, :rb_num_coerce_cmp
    <<-END
      function rb_big_cmp(x, y) {
        var xlen = x.len;
        switch (TYPE(y)) {
          case T_FIXNUM:
            y = rb_int2big(FIX2LONG(y));
            break;
          case T_BIGNUM:
            break;
          case T_FLOAT:
            return rb_dbl_cmp(rb_big2dbl(x), y.value);
          default:
            return rb_num_coerce_cmp(x, y);
        }
        if (x.sign > y.sign) { return INT2FIX(1); }
        if (x.sign < y.sign) { return INT2FIX(-1); }
        if (xlen < y.len) { return (x.sign) ? INT2FIX(-1) : INT2FIX(1); }
        if (xlen > y.len) { return (x.sign) ? INT2FIX(1) : INT2FIX(-1); }
        while(xlen-- && (BDIGITS(x)[xlen] == BDIGITS(y)[xlen])) {};
        if (-1 == xlen) { return INT2FIX(0); }
        return (BDIGITS(x)[xlen] > BDIGITS(y)[xlen]) ? (x.sign ? INT2FIX(1) : INT2FIX(-1)) : (x.sign ? INT2FIX(-1) : INT2FIX(1));
      }
    END
  end
  
  # verbatim
  def rb_big_coerce
    add_function :rb_assoc_new, :rb_int2big, :rb_raise, :rb_obj_classname
    <<-END
      function rb_big_coerce(x, y) {
        if (FIXNUM_P(y)) {
          return rb_assoc_new(rb_int2big(FIX2LONG(y)), x);
        } else if (TYPE(y) == T_BIGNUM) {
          return rb_assoc_new(y, x);
        } else {
          rb_raise(rb_eTypeError, "can't coerce %s to Bignum", rb_obj_classname(y));
        }
        /* not reached */
        return Qnil;
      }
    END
  end
  
  # verbatim
  def rb_big_eq
    add_function :rb_int2big, :isnan, :rb_big2dbl, :memcmp, :rb_equal
    <<-END
      function rb_big_eq(x, y) {
        switch (TYPE(y)) {
          case T_FIXNUM:
            y = rb_int2big(FIX2LONG(y));
            break;
          case T_BIGNUM:
            break;
          case T_FLOAT:
            var a = y.value;
            if (isnan(a)) { return Qfalse; }
            var b = rb_big2dbl(x);
            return (a == b) ? Qtrue : Qfalse;
          default:
            return rb_equal(y, x);
        }
        if (x.sign != y.sign) { return Qfalse; }
        if (x.len != y.len) { return Qfalse; }
        if (memcmp(BDIGITS(x), BDIGITS(y), y.len) !== 0) { return Qfalse; }
        return Qtrue;
      }
    END
  end
  
  # verbatim
  def rb_big_eql
    add_function :memcmp
    <<-END
      function rb_big_eql(x, y) {
        if (TYPE(y) != T_BIGNUM) { return Qfalse; }
        if (x.sign != y.sign) { return Qfalse; }
        if (x.len != y.len) { return Qfalse; }
        if (memcmp(BDIGITS(x), BDIGITS(y), y.len) !== 0) { return Qfalse; }
        return Qtrue;
      }
    END
  end
  
  # verbatim
  def rb_big_hash
    <<-END
      function rb_big_hash(x) {
        var key = 0;
        var digits = BDIGITS(x);
        var len = x.len;
        for (var i = 0; i < len; ++i) {
          key ^= digits[i];
        }
        return LONG2FIX(key);
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
  def rb_big_modulo
    add_function :rb_int2big, :rb_num_coerce_bin, :bigdivmod, :bignorm
    <<-END
      function rb_big_modulo(x, y) {
        switch (TYPE(y)) {
          case T_FIXNUM:
            y = rb_int2big(FIX2LONG(y));
            break;
          case T_BIGNUM:
            break;
          default:
            return rb_num_coerce_bin(x, y);
        }
        var tmp = bigdivmod(x, y);
        return bignorm(tmp[1]);
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
  def rb_big_or
    add_function :rb_to_int, :rb_int2big, :rb_big_clone, :get2comp, :bignew, :bignorm
    <<-END
      function rb_big_or(xx, yy) {
        var l1;
        var l2;
        var ds1;
        var ds2;
        var sign;
        var x = xx;
        var y = rb_to_int(yy);
        if (FIXNUM_P(y)) { y = rb_int2big(FIX2LONG(y)); }
        if (!y.sign) {
          y = rb_big_clone(y);
          get2comp(y);
        }
        if (!x.sign) {
          x = rb_big_clone(x);
          get2comp(x);
        }
        if (x.len > y.len) {
          l1 = y.len;
          l2 = x.len;
          ds1 = BDIGITS(y);
          ds2 = BDIGITS(x);
          sign = y.sign;
        } else {
          l1 = x.len;
          l2 = y.len;
          ds1 = BDIGITS(x);
          ds2 = BDIGITS(y);
          sign = x.sign;
        }
        var z = bignew(l2, x.sign && y.sign);
        var zds = BDIGITS(z);
        for (var i = 0; i < l1; ++i) {
          zds[i] = ds1[i] | ds2[i];
        }
        for (; i < l2; ++i) {
          zds[i] = sign ? ds2[i] : (BIGRAD - 1);
        }
        if (!z.sign) { get2comp(z); }
        return bignorm(z);
      }
    END
  end
  
  # verbatim
  def rb_big_to_f
    add_function :rb_float_new, :rb_big2dbl
    <<-END
      function rb_big_to_f(x) {
        return rb_float_new(rb_big2dbl(x));
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
