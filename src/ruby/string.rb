class Red::MethodCompiler
  # verbatim
  def memcmp
    <<-END
      function memcmp(s1, s2, len) {
        var tmp;
        for (var i = 0; i < len; ++i) {
          if (tmp = s1.charCodeAt(i) - s2.charCodeAt(i)) { return tmp; }
        }
        return 0;
      }
    END
  end
  
  # removed ELTS_SHARED stuff
  def rb_check_string_type
    add_function :rb_check_convert_type
    add_method :to_str
    <<-END
      function rb_check_string_type(str) {
        str = rb_check_convert_type(str, T_STRING, "String", "to_str");
        return str;
      }
    END
  end
  
  # simplified to use simple JS parseFloat
  def rb_cstr_to_dbl
    add_function :isnan, :rb_invalid_str
    <<-END
      function rb_cstr_to_dbl(p, badcheck) {
        if (!p) { return 0; }
        try {
          p = p.replace(/_/g,'');
          var f = parseFloat(p);
          if (isnan(f)) { return 0; }
          return f;
        } catch (e) {
          rb_invalid_str(p, "Float()");
        }
      }
    END
  end
  
  # CHECK
  def rb_obj_as_string
    add_function :rb_funcall, :rb_any_to_s
    add_method :to_s
    <<-END
      function rb_obj_as_string(obj) {
        if (TYPE(obj) == T_STRING) { return obj; }
        var str = rb_funcall(obj, id_to_s, 0);
        if (TYPE(str) != T_STRING) { return rb_any_to_s(obj); }
        if (OBJ_TAINTED(obj)) OBJ_TAINT(str);
        return str;
      }
    END
  end
  
  # CHECK
  def rb_str_append
    <<-END
      function rb_str_append(str, str2) {
      //rb_str_modify(str);
        str.ptr = str.ptr + str2.ptr;
        OBJ_INFECT(str, str2);
        return str;
      }
    END
  end
  
  # CHECK
  def rb_str_cat
    <<-END
      function rb_str_cat(str, ptr) {
      //rb_str_modify(str);
        str.ptr = str.ptr + ptr;
        return str;
      }
    END
  end
  
  # replaced rb_memcmp with memcmp
  def rb_str_cmp
    add_function :memcmp
    <<-END
      function rb_str_cmp(str1, str2) {
        var retval;
        var p1 = str1.ptr;
        var p2 = str2.ptr;
        var l1 = p1.length;
        var l2 = p2.length;
        var len = (l1 > l2) ? l2 : l1;
        var retval = memcmp(p1, p2, len);
        if (retval == 0) {
          if (l1 == l2) { return 0; }
          if (l1 > l2) { return 1; }
          return -1;
        }
        if (retval > 0) { return 1; }
        return -1;
      }
    END
  end
  
  # verbatim
  def rb_str_cmp_m
    add_function :rb_respond_to, :rb_intern, :rb_funcall, :rb_str_cmp, :rb_int2inum
    add_method :to_str, :'<=>', :-
    <<-END
      function rb_str_cmp_m(str1, str2) {
        var result;
        if (TYPE(str2) != T_STRING) {
          if (!rb_respond_to(str2, rb_intern("to_str"))) {
            return Qnil;
          } else if (!rb_respond_to(str2, rb_intern("<=>"))) {
            return Qnil;
          } else {
            var tmp = rb_funcall(str2, rb_intern("<=>"), 1, str1);
            if (NIL_P(tmp)) { return Qnil; }
            if (!FIXNUM_P(tmp)) { return rb_funcall(LONG2FIX(0), '-', 1, tmp); }
            result = -FIX2LONG(tmp);
          }
        } else {
          result = rb_str_cmp(str1, str2);
        }
        return LONG2NUM(result);
      }
    END
  end
  
  # CHECK
  def rb_str_dup
    add_function :str_alloc, :rb_obj_class, :rb_str_replace
    <<-END
      function rb_str_dup(str) {
        var dup = str_alloc(rb_obj_class(str));
        rb_str_replace(dup, str);
        return dup;
      }
    END
  end
  
  # verbatim
  def rb_str_equal
    add_function :rb_respond_to, :rb_intern, :rb_equal, :rb_str_cmp
    add_method :to_str
    <<-END
      function rb_str_equal(str1, str2) {
        if (str1 == str2) { return Qtrue; }
        if (TYPE(str2) != T_STRING) {
          if (!rb_respond_to(str2, rb_intern("to_str"))) { return Qfalse; }
          return rb_equal(str2, str1);
        }
        if ((str1.ptr.length == str2.ptr.length) && (rb_str_cmp(str1, str2) === 0)) { return Qtrue; }
        return Qfalse;
      }
    END
  end
  
  # verbatim
  def rb_str_format_m
    add_function :rb_check_array_type, :rb_str_format
    <<-END
      function rb_str_format_m(str, arg) {
        var tmp = rb_check_array_type(arg);
        if (!NIL_P(tmp)) { return rb_str_format(tmp.ptr.length, tmp.ptr, str); }
        return rb_str_format(1, arg, str);
      }
    END
  end
  
  # fixed "int" length problem with "& 0x7FFFFFFF"
  def rb_str_hash
    <<-END
      function rb_str_hash(str) {
        var tmp;
        var p = str.ptr;
        var i = 0;
        var len = p.length;
        var key = 0;
        while (len--) {
          key = ((key * 65599) + p.charCodeAt(i)) & 0x7FFFFFFF;
          i++;
        }
        key = (key + (key >> 5)) & 0x7FFFFFFF;
        return key;
      }
    END
  end
  
  # verbatim
  def rb_str_hash_m
    add_function :rb_str_hash
    <<-END
      function rb_str_hash_m(str) {
        return INT2FIX(rb_str_hash(str));
      }
    END
  end
  
  # expanded rb_scan_args
  def rb_str_init
    add_function :rb_scan_args, :rb_str_replace
    <<-END
      function rb_str_init(argc, argv, str) {
        var tmp = rb_scan_args(argc, argv, "01");
        var orig = tmp[1];
        if (tmp[0] == 1) { rb_str_replace(str, orig); }
        return str;
      }
    END
  end
  
  # EMPTY
  def rb_str_inspect
    <<-END
      function rb_str_inspect() {}
    END
  end
  
  # CHECK
  def rb_str_intern
    add_function :rb_raise, :rb_sym_interned_p, :rb_intern
    <<-END
      function rb_str_intern(s) {
        var str = s;
        if (!str.ptr || str.ptr.length === 0) { rb_raise(rb_eArgError, "interning empty string"); }
        if (OBJ_TAINTED(str) && rb_safe_level() >= 1 && !rb_sym_interned_p(str)) { rb_raise(rb_eSecurityError, "Insecure: can't intern tainted string"); }
        var id = rb_intern(str.ptr);
        return ID2SYM(id);
      }
    END
  end
  
  # CHECK
  def rb_str_new
    add_function :str_alloc
    <<-END
      function rb_str_new(ptr) {
        var str = str_alloc(rb_cString);
        str.ptr = ptr || '';
        return str;
      }
    END
  end
  
  # CHECK
  def rb_str_replace
    <<-END
      function rb_str_replace(str, str2) {
        if (str === str2) { return str; }
      //StringValue(str2);
      //rb_str_modify(str);
        str.ptr = str2.ptr;
        return str;
      }
    END
  end
  
  # removed char allocation and checking
  def rb_str_to_dbl
    add_function :rb_cstr_to_dbl
    <<-END
      function rb_str_to_dbl(str, badcheck) {
        var s = str.ptr;
        var len = str.ptr.length;
        return rb_cstr_to_dbl(s, badcheck);
      }
    END
  end
  
  # verbatim
  def rb_str_to_f
    add_function :rb_float_new, :rb_str_to_dbl
    <<-END
      function rb_str_to_f(str) {
        return rb_float_new(rb_str_to_dbl(str, Qfalse));
      }
    END
  end
  
  # verbatim
  def rb_str_to_s
    add_function :str_alloc, :rb_str_replace, :rb_obj_class
    <<-END
      function rb_str_to_s(str) {
        if (rb_obj_class(str) != rb_cString) {
          var dup = str_alloc(rb_cString);
          rb_str_replace(dup, str);
          return dup;
        }
        return str;
      }
    END
  end
  
  # CHECK
  def str_alloc
    <<-END
      function str_alloc(klass) {
        var str = NEWOBJ();
        OBJSETUP(str, klass, T_STRING);
        str.ptr = 0;
        return str;
      }
    END
  end
  
  # verbatim
  def str_to_id
    add_function :rb_str_intern
    <<-END
      function str_to_id(str) {
        return SYM2ID(rb_str_intern(str));
      }
    END
  end
end
