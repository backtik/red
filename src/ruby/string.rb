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
        str = rb_check_convert_type(str, T_STRING, 'String', 'to_str');
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
  
  # verbatim
  def rb_f_split
    add_function :rb_str_split_m, :uscore_get
    <<-END
      function rb_f_split(argc, argv) {
        return rb_str_split_m(argc, argv, uscore_get());
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
        if (OBJ_TAINTED(obj)) { OBJ_TAINT(str); }
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
  
  # verbatim
  def rb_str_aref_m
    add_function :rb_str_subpat, :rb_str_substr, :rb_raise, :rb_str_aref, :rb_num2long
    <<-END
      function rb_str_aref_m(argc, argv, str) {
        if (argc == 2) {
          if (TYPE(argv[0]) == T_REGEXP) { return rb_str_subpat(str, argv[0], NUM2INT(argv[1])); }
          return rb_str_substr(str, NUM2LONG(argv[0]), NUM2LONG(argv[1]));
        }
        if (argc != 1) { rb_raise(rb_eArgError, "wrong number of arguments (%d for 1)", argc); }
        return rb_str_aref(str, argv[0]);
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
        if (retval === 0) {
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
          if (!rb_respond_to(str2, rb_intern('to_str'))) {
            return Qnil;
          } else if (!rb_respond_to(str2, rb_intern('<=>'))) {
            return Qnil;
          } else {
            var tmp = rb_funcall(str2, rb_intern('<=>'), 1, str1);
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
  def rb_str_concat
    add_function :rb_str_new
    <<-END
      function rb_str_concat(str1, str2) {
        if (FIXNUM_P(str2)) {
          int i = FIX2INT(str2);
          if (0 <= i && i <= 0xff) { /* byte */
            return rb_str_new(str.ptr + String.fromCharCode(i));
          //return rb_str_cat(str1, &c, 1);
          }
        }
        //str1 = rb_str_append(str1, str2);
        str1.ptr += str2.ptr;
        return str1;
      }
    END
  end
  
  # verbatim
  def rb_str_delete
    add_function :rb_str_dup, :rb_str_delete_bang
    <<-END
      function rb_str_delete(argc, argv, str) {
        str = rb_str_dup(str);
        rb_str_delete_bang(argc, argv, str);
        return str;
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
  
  # EMPTY
  def rb_str_each_line
    <<-END
      function rb_str_each_line() {}
    END
  end
  
  # verbatim
  def rb_str_empty
    <<-END
      function rb_str_empty(str) {
        return (str.ptr.length === 0) ? Qtrue : Qfalse;
      }
    END
  end
  
  # changed 'lesser' to JS 'Math.min'
  def rb_str_eql
    add_function :memcmp
    <<-END
      function rb_str_eql(str1, str2) {
        if ((TYPE(str2) != T_STRING) || (str1.ptr.length != str2.ptr.length)) { return Qfalse; }
        if (memcmp(str1.ptr, str2.ptr, Math.min(str1.ptr.length, str2.ptr.length)) === 0) { return Qtrue; }
        return Qfalse;
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
          if (!rb_respond_to(str2, rb_intern('to_str'))) { return Qfalse; }
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
  
  # fixed 'int' length problem with '& 0x7FFFFFFF'
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
  
  # CHECK: look up what 'memchr' is
  def rb_str_include
    add_function :rb_string_value, :rb_str_index
    <<-END
      function rb_str_include(str, arg) {
        if (FIXNUM_P(arg)) {
          if (memchr(str.ptr, FIX2INT(arg), str.ptr.length)) { return Qtrue; }
          return Qfalse;
        }
        rb_string_value(arg);
        return (rb_str_index(str, arg, 0) == -1) ? Qfalse : Qtrue;
      }
    END
  end
  
  # verbatim
  def rb_str_index
    add_function :rb_memsearch
    <<-END
      function rb_str_index(str, sub, offset) {
        if (offset < 0) {
          offset += str.ptr.length;
          if (offset < 0) { return -1; }
        }
        if ((str.ptr.length - offset) < sub.ptr.length) { return -1; }
        if (sub.ptr.length === 0) { return offset; }
        var pos = rb_memsearch(sub.ptr, sub.ptr.length, str.ptr + offset, str.ptr.length - offset);
        if (pos < 0) { return pos; }
        return pos + offset;
      }
    END
  end
  
  # expanded rb_scan_args
  def rb_str_init
    add_function :rb_scan_args, :rb_str_replace
    <<-END
      function rb_str_init(argc, argv, str) {
        var tmp = rb_scan_args(argc, argv, '01');
        var orig = tmp[1];
        if (tmp[0] == 1) { rb_str_replace(str, orig); }
        return str;
      }
    END
  end
  
  # verbatim
  def rb_str_insert
    add_function :rb_str_splice
    <<-END
      function rb_str_insert(str, idx, str2) {
        var pos = NUM2LONG(idx);
        if (pos == -1) {
          pos = str.ptr.length;
        } else if (pos < 0) {
          pos++;
        }
        rb_str_splice(str, pos, 0, str2);
        return str;
      }
    END
  end
  
  # CHECK: TOTALLY WRONG
  def rb_str_inspect
    <<-END
      function rb_str_inspect(str) {
        return rb_str_new("\\x22" + str.ptr + "\\x22");
      }
    END
  end
  
  # CHECK
  def rb_str_intern
    add_function :rb_raise, :rb_sym_interned_p, :rb_intern
    <<-END
      function rb_str_intern(s) {
        var str = s;
        if (!str.ptr || str.ptr.length === 0) { rb_raise(rb_eArgError, "interning empty string"); }
        if (OBJ_TAINTED(str) && ruby_safe_level >= 1 && !rb_sym_interned_p(str)) { rb_raise(rb_eSecurityError, "Insecure: can't intern tainted string"); }
        var id = rb_intern(str.ptr);
        return ID2SYM(id);
      }
    END
  end
  
  # verbatim
  def rb_str_length
    <<-END
      function rb_str_length(str) {
        return LONG2NUM(str.ptr.length);
      }
    END
  end
  
  # verbatim
  def rb_str_match_m
    add_function :rb_funcall, :get_pat
    add_method :match
    <<-END
      function rb_str_match_m(str, re) {
        return rb_funcall(get_pat(re, 0), rb_intern('match'), 1, str);
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
  
  # verbatim
  def rb_str_new5
    add_function :str_new, :rb_obj_class
    <<-END
      function rb_str_new5(obj, ptr, len) {
        return str_new(rb_obj_class(obj), ptr, len);
      }
    END
  end
  
  # removed 'len' handling
  def rb_str_plus
    add_function :rb_str_new
    <<-END
      function rb_str_plus(str1, str2) {
      //StringValue(str2);
        var str3 = rb_str_new();
        str3.ptr = str1.ptr + str2.ptr;
        if (OBJ_TAINTED(str1) || OBJ_TAINTED(str2)) { OBJ_TAINT(str3); }
        return str3;
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
  
  # modified string handling
  def rb_str_reverse
    add_function :rb_str_dup, :rb_str_new
    <<-END
      function rb_str_reverse(str) {
        if (str.ptr.length <= 1) { return rb_str_dup(str); }
        var s = str.ptr.split('').reverse().join('');
        var obj = rb_str_new(s);
        OBJ_INFECT(obj, str);
        return obj;
      }
    END
  end
  
  # modified string handling
  def rb_str_reverse_bang
    <<-END
      function rb_str_reverse_bang(str) {
        if (str.ptr.length > 1) { str.ptr = str.ptr.split('').reverse().join(''); }
        return str;
      }
    END
  end
  
  # modified to return variable instead of using pointer
  def rb_str_setter
    add_function :rb_raise, :rb_id2name
    <<-END
      function rb_str_setter(val, id, variable) {
        if (!NIL_P(val) && (TYPE(val) != T_STRING)) { rb_raise(rb_eTypeError, "value of %s must be String", rb_id2name(id)); }
        return val;
      }
    END
  end
  
  # CHECK: this is a substitute for the real function, using the simple JS 'split' function and allowing only one argument
  def rb_str_split_m
    <<-END
      function rb_str_split_m(argc, argv, str) {
        var tmp = rb_scan_args(argc, argv, "02");
        var spat = tmp[1];
        var ary = rb_ary_new();
        var tmp = str.ptr.split(spat.ptr || ' ');
        for (var i = 0, l = tmp.length; i < l; ++i) {
          ary.ptr.push(rb_str_new(tmp[i]));
        }
        return ary;
      }
    END
  end
  
  # verbatim
  def rb_str_subpat
    add_function :rb_reg_search, :rb_reg_nth_match, :rb_backref_get
    <<-END
      function rb_str_subpat(str, re, nth) {
        if (rb_reg_search(re, str, 0, 0) >= 0) { return rb_reg_nth_match(nth, rb_backref_get()); }
        return Qnil;
      }
    END
  end
  
  # 
  def rb_str_substr
    <<-END
      function rb_str_substr(str, beg, len) {
      //VALUE str2;
      //var p = str.ptr;
      //var l = str.ptr.length;
      //if (len < 0) { return Qnil; }
      //if (beg > l) { return Qnil; }
      //if (beg < 0) {
      //  beg += l;
      //  if (beg < 0) { return Qnil; }
      //}
      //if (beg + len > l) { len = l - beg; }
      //if (len < 0) { len = 0; }
      //if (len === 0) {
      //  str2 = rb_str_new5(str,0,0);
      //} else if (len > sizeof(struct RString)/2 && (beg + len) == l)) && !FL_TEST(str, STR_ASSOC)) {
      //  str2 = rb_str_new4(str);
      //  str2 = str_new3(rb_obj_class(str2), str2);
      //  RSTRING(str2)->ptr += RSTRING(str2)->len - len;
      //  RSTRING(str2)->len = len;
      //} else {
      //  str2 = rb_str_new5(str, RSTRING(str)->ptr+beg, len);
      //}
      //OBJ_INFECT(str2, str);
      //return str2;
      }
    END
  end
  
  # 
  def rb_str_succ
    <<-END
      function rb_str_succ(orig) {
        char *s;
        int c = -1;
        long n = 0;
        var str = rb_str_new5(orig, orig.ptr, orig.ptr.length);
        OBJ_INFECT(str, orig);
        if (str.ptr.length === 0) { return str; }
        var c = -1;
        var n = 0;
        var sp = str.ptr;
        var s = str.ptr.length - 1;
        while (s > -1) {
          if (ISALNUM(sp[s])) {
            if ((c = succ_char(s)) === 0) { break; }
            n = s;
          }
          s--;
        }
        if (c == -1) { /* str contains no alnum */
          s = str.ptr.length - 1;
          c = '\001';
          while (s > -1) {
            if ((*s += 1) != 0) { break; }
            s--;
          }
        }
        if (s < 0) {
          s = n;
          memmove(s + 1, s, str.ptr.length - n);
          sp[s] = c;
        }
        return str;
      }
    END
  end
  
  # removed 'len' handling
  def rb_str_times
    add_function :rb_str_new5, :rb_raise, :rb_num2long
    <<-END
      function rb_str_times(str, times) {
        var len = NUM2LONG(times);
        if (len < 0) { rb_raise(rb_eArgError, "negative argument"); }
        if (len && ((LONG_MAX / len) < str.ptr.length)) { rb_raise(rb_eArgError, "argument too big"); }
        str2 = rb_str_new5(str);
        for (var i = 0; i < len; i += str.ptr.length) {
          str2.ptr += str.ptr;
        }
        OBJ_INFECT(str2, str);
        return str2;
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
  def rb_str_to_i
    add_function :rb_scan_args, :rb_raise, :rb_str_to_inum
    <<-END
      function rb_str_to_i(argc, argv, str) {
        var base;
        var b = rb_scan_args(argc, argv, '01')[1];
        if (argc === 0) {
          base = 10;
        } else {
          base = NUM2INT(b);
        }
        if (base < 0) { rb_raise(rb_eArgError, "illegal radix %d", base); }
        return rb_str_to_inum(str, base, Qfalse);
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
  
  # verbatim
  def rb_str_to_str
    add_function :rb_convert_type
    add_method :to_str
    <<-END
      function rb_str_to_str(str) {
        return rb_convert_type(str, T_STRING, 'String', 'to_str');
      }
    END
  end
  
  # removed ELTS_SHARED stuff
  def rb_string_value
    add_function :rb_str_to_str
    <<-END
      function rb_string_value(obj) {
        var s = obj;
        if (TYPE(s) != T_STRING) { obj = rb_str_to_str(s); }
        return s;
      }
    END
  end
  
  # CHECK
  def str_alloc
    <<-END
      function str_alloc(klass) {
        NEWOBJ(str);
        OBJSETUP(str, klass, T_STRING);
        str.ptr = 0;
        return str;
      }
    END
  end
  
  # removed 'len' and 'capa' handling
  def str_new
    add_function :rb_raise, :str_alloc
    <<-END
      function str_new(klass, ptr, len) {
        if (len < 0) { rb_raise(rb_eArgError, "negative string size (or size too big)"); }
        var str = str_alloc(klass);
        str.ptr = ptr || '';
        return str;
      }
    END
  end
  
  # verbatim
  def str_step
    add_function :rb_str_upto
    <<-END
      function str_step(args) {
        return rb_str_upto(args[0], args[1], EXCL(args[2]));
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
  
  # modified to return [rollover, s] instead of using pointer
  def succ_char
    <<-END
      function succ_char(s) {
        var rollover = 0;
        var c = s;
        if (('0' <= c) && (c < '9')) { /* numerics */
          s = (+s + 1).toString();
        } else if (c == '9') {
          s = '0';
          rollover = '1';
        } else if ('a' <= c && c < 'z') { /* small alphabets */
          s = String.fromCharCode(s.charCodeAt(0) + 1);
        } else if (c == 'z') {
          rollover = 'a';
        } else if ('A' <= c && c < 'Z') { /* capital alphabets */
          s = String.fromCharCode(s.charCodeAt(0) + 1);
        } else if (c == 'Z') {
          rollover = 'A';
        }
        return [rollover, s];
      }
    END
  end
  
  def uscore_get
    add_function :rb_lastline_get, :rb_raise, :rb_obj_classname
    <<-END
      function uscore_get() {
        var line = rb_lastline_get();
        if (TYPE(line) != T_STRING) { rb_raise(rb_eTypeError, "$_ value need to be String (%s given)", NIL_P(line) ? "nil" : rb_obj_classname(line)); }
        return line;
      }
    END
  end
end
