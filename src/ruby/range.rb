class Red::MethodCompiler
  # verbatim
  def r_le
    add_function :rb_funcall, :rb_cmpint
    add_method :'<=>'
    <<-END
      function r_le(a, b) {
        var r = rb_funcall(a, id_cmp, 1, b);
        if (NIL_P(r)) { return Qfalse; }
        var c = rb_cmpint(r, a, b);
        if (c === 0) { return INT2FIX(0); }
        if (c < 0) { return Qtrue; }
        return Qfalse;
      }
    END
  end
  
  # verbatim
  def r_lt
    add_function :rb_funcall, :rb_cmpint
    add_method :'<=>'
    <<-END
      function r_lt(a, b) {
        var r = rb_funcall(a, id_cmp, 1, b);
        if (NIL_P(r)) { return Qfalse; }
        if (rb_cmpint(r, a, b) < 0) { return Qtrue; }
        return Qfalse;
      }
    END
  end
  
  # verbatim
  def range_check
    add_function :rb_funcall
    add_method :'<=>'
    <<-END
      function range_check(args) {
        return rb_funcall(args[0], id_cmp, 1, args[1]);
      }
    END
  end
  
  # verbatim
  def range_each
    add_function :rb_ivar_get, :rb_respond_to, :rb_raise, :rb_obj_classname,
                 :rb_yield, :step_i, :rb_iterate, :range_each_func, :str_step,
                 :range_each_i
    <<-END
      function range_each(range) {
        RETURN_ENUMERATOR(range, 0, 0);
        var beg = rb_ivar_get(range, id_beg);
        var end = rb_ivar_get(range, id_end);
        if (!rb_respond_to(beg, id_succ)) { rb_raise(rb_eTypeError, "can't iterate from %s", rb_obj_classname(beg)); }
        if (FIXNUM_P(beg) && FIXNUM_P(end)) { /* fixnums are special */
          var lim = FIX2LONG(end);
          if (!EXCL(range)) { lim += 1; }
          for (var i = FIX2LONG(beg); i < lim; ++i) {
            rb_yield(LONG2NUM(i));
          }
        } else if (TYPE(beg) == T_STRING) {
          var args = [beg, end, range];
          var iter = [INT2FIX(1), INT2FIX(1)];
          rb_iterate(str_step, args, step_i, iter);
        } else {
          range_each_func(range, range_each_i, beg, end, NULL);
        }
        return range;
      }
    END
  end
  
  # verbatim
  def range_each_func
    add_function :r_lt, :r_le, :rb_funcall
    add_method :succ
    <<-END
      function range_each_func(range, func, v, e, arg) {
        var c;
        if (EXCL(range)) {
          while (r_lt(v, e)) {
            func(v, arg);
            v = rb_funcall(v, id_succ, 0, 0);
          }
        } else {
          while (RTEST(c = r_le(v, e))) {
            func(v, arg);
            if (c == INT2FIX(0)) { break; }
            v = rb_funcall(v, id_succ, 0, 0);
          }
        }
      }
    END
  end
  
  # renamed from 'each_i'
  def range_each_i
    add_function :rb_yield
    <<-END
      function range_each_i(v, arg) {
        rb_yield(v);
      }
    END
  end
  
  # verbatim
  def range_eq
    add_function :rb_obj_is_instance_of, :rb_obj_class, :rb_equal, :rb_ivar_get
    <<-END
      function range_eq(range, obj) {
        if (range == obj) { return Qtrue; }
        if (!rb_obj_is_instance_of(obj, rb_obj_class(range))) { return Qfalse; }
        if (!rb_equal(rb_ivar_get(range, id_beg), rb_ivar_get(obj, id_beg))) { return Qfalse; }
        if (!rb_equal(rb_ivar_get(range, id_end), rb_ivar_get(obj, id_end))) { return Qfalse; }
        if (EXCL(range) != EXCL(obj)) { return Qfalse; }
        return Qtrue;
      }
    END
  end
  
  # verbatim
  def range_eql
    add_function :rb_obj_is_instance_of, :rb_obj_class, :rb_eql, :rb_ivar_get
    <<-END
      function range_eql(range, obj) {
        if (range == obj) { return Qtrue; }
        if (!rb_obj_is_instance_of(obj, rb_obj_class(range))) { return Qfalse; }
        if (!rb_eql(rb_ivar_get(range, id_beg), rb_ivar_get(obj, id_beg))) { return Qfalse; }
        if (!rb_eql(rb_ivar_get(range, id_end), rb_ivar_get(obj, id_end))) { return Qfalse; }
        if (EXCL(range) != EXCL(obj)) { return Qfalse; }
        return Qtrue;
      }
    END
  end
  
  # verbatim
  def range_failed
    add_function :rb_raise
    <<-END
      function range_failed() {
        rb_raise(rb_eArgError, "bad value for range");
        return Qnil;
      }
    END
  end
  
  # verbatim
  def range_hash
    add_function :rb_hash, :rb_ivar_get
    <<-END
      function range_hash(range) {
        var hash = EXCL(range);
        var v = rb_hash(rb_ivar_get(range, id_beg));
        hash ^= v << 1;
        v = rb_hash(rb_ivar_get(range, id_end));
        hash ^= v << 9;
        hash ^= EXCL(range) << 24;
        return LONG2FIX(hash);
      }
    END
  end
  
  # verbatim
  def range_include
    add_function :rb_ivar_get, :r_le, :r_lt
    <<-END
      function range_include(range, val) {
        var beg = rb_ivar_get(range, id_beg);
        var end = rb_ivar_get(range, id_end);
        if (r_le(beg, val)) {
          if (EXCL(range)) {
            if (r_lt(val, end)) { return Qtrue; }
          } else {
            if (r_le(val, end)) { return Qtrue; }
          }
        }
        return Qfalse;
      }
    END
  end
  
  # verbatim
  def range_init
    add_function :rb_rescue, :range_failed, :rb_ivar_set
    <<-END
      function range_init(range, beg, end, exclude_end) {
        var args = [beg, end];
        if (!FIXNUM_P(beg) || !FIXNUM_P(end)) {
          var v = rb_rescue(range_check, args, range_failed, 0);
          if (NIL_P(v)) { range_failed(); }
        }
        SET_EXCL(range, exclude_end);
        rb_ivar_set(range, id_beg, beg);
        rb_ivar_set(range, id_end, end);
      }
    END
  end
  
  # expanded rb_scan_args
  def range_initialize
    add_function :rb_ivar_defined, :rb_name_error, :range_init
    <<-END
      function range_initialize(argc, argv, range) {
        var tmp = rb_scan_args(argc, argv, '21');
        var beg = tmp[1];
        var end = tmp[2];
        var flags = tmp[3];
        /* Ranges are immutable, so that they should be initialized only once. */
        if (rb_ivar_defined(range, id_beg)) { rb_name_error(rb_intern('initialize'), "'initialize' called twice"); }
        range_init(range, beg, end, RTEST(flags));
        return Qnil;
      }
    END
  end
  
  # CHECK
  def range_inspect
    add_function :rb_inspect, :rb_ivar_get, :rb_str_dup, :rb_str_cat, :rb_str_append
    <<-END
      function range_inspect(range) {
        var str = rb_inspect(rb_ivar_get(range, id_beg));
        var str2 = rb_inspect(rb_ivar_get(range, id_end));
        str = rb_str_dup(str);
        rb_str_cat(str, EXCL(range) ? '...' : '..');
        rb_str_append(str, str2);
        OBJ_INFECT(str, str2);
        return str;
      }
    END
  end
  
  # modified string handling
  def range_to_s
    add_function :rb_obj_as_string, :rb_ivar_get, :rb_str_dup
    <<-END
      function range_to_s(range) {
        var str = rb_obj_as_string(rb_ivar_get(range, id_beg));
        var str2 = rb_obj_as_string(rb_ivar_get(range, id_end));
        var str = rb_str_dup(str);
        str.ptr += (EXCL(range) ? "..." : "..") + str2.ptr;
        OBJ_INFECT(str, str2);
        return str;
      }
    END
  end
  
  # modified to return array [result, begp, lenp] instead of using pointers
  def rb_range_beg_len
    add_function :rb_obj_is_kind_of, :rb_ivar_get, :rb_raise, :rb_num2long
    <<-END
      function rb_range_beg_len(range, len, err) {
        if (!rb_obj_is_kind_of(range, rb_cRange)) { return Qfalse; }
        var b, beg = b = NUM2LONG(rb_ivar_get(range, id_beg));
        var e, end = e = NUM2LONG(rb_ivar_get(range, id_end));
        if (beg < 0) {
          beg += len;
          if (beg < 0) {
            if (err) { rb_raise(rb_eRangeError, "%d..%s%d out of range", b, EXCL(range) ? "." : "", e); }
            return [Qnil, 0, 0];
          }
        }
        if ((err === 0) || (err == 2)) {
          if (beg > len) {
            if (err) { rb_raise(rb_eRangeError, "%d..%s%d out of range", b, EXCL(range) ? "." : "", e); }
            return [Qnil, 0, 0];
          }
          if (end > len) { end = len; }
        }
        if (end < 0) { end += len; }
        if (!EXCL(range)) { end++; } /* include end point */
        len = end - beg;
        if (len < 0) { len = 0; }
        return [Qtrue, beg, len];
      }
    END
  end
  
  # CHECK
  def rb_range_new
    add_function :rb_obj_alloc, :range_init
    <<-END
      function rb_range_new(beg, end, exclude_end) {
        var range = rb_obj_alloc(rb_cRange);
        range_init(range, beg, end, exclude_end);
        return range;
      }
    END
  end
end

