class Red::MethodCompiler
  # removed 'len' and 'capa' handling
  def ary_alloc
    <<-END
      function ary_alloc(klass) {
        NEWOBJ(ary);
        OBJSETUP(ary, klass, T_ARRAY);
        ary.ptr = [];
        return ary;
      }
    END
  end
  
  # verbatim
  def ary_make_hash
    add_function :rb_hash_new, :rb_hash_aset
    <<-END
      function ary_make_hash(ary1, ary2) {
        var hash = rb_hash_new();
        for (var i = 0, p = ary1.ptr, l = p.length; i < l; ++i) {
          rb_hash_aset(hash, p[i], Qtrue);
        }
        if (ary2) {
          for (var i = 0, p2 = ary2.ptr, l2 = p2.length; i < l2; ++i) {
            rb_hash_aset(hash, p2[i], Qtrue);
          }
        }
        return hash;
      }
    END
  end
  
  # removed 'len' and 'capa' handling
  def ary_new
    add_function :ary_alloc, :rb_raise
    <<-END
      function ary_new(klass, len) {
        var ary = ary_alloc(klass);
        if (len < 0) { rb_raise(rb_eArgError, "negative array size (or size too big)"); }
        if (len > ARY_MAX_SIZE) { rb_raise(rb_eArgError, "array size too big"); }
        ary.ptr = [];
        return ary;
      }
    END
  end
  
  # renamed from 'recursive_eql'
  def ary_recursive_eql
    add_function :rb_ary_elt, :rb_eql
    <<-END
      function ary_recursive_eql(ary1, ary2, recur) {
        if (recur) { return Qfalse; }
        for (var i = 0, p = ary1.ptr, l = p.length; i < l; ++i) {
          if (!rb_eql(rb_ary_elt(ary1, i), rb_ary_elt(ary2, i))) { return Qfalse; }
        }
        return Qtrue;
      }
    END
  end
  
  # simplified from thread-based original
  def get_inspect_tbl
    add_function :rb_ary_new
    <<-END
      function get_inspect_tbl(create) {
        if (NIL_P(inspect_tbl)) {
          if (create) { inspect_tbl = rb_ary_new(); }
        }
        return inspect_tbl;
      }
    END
  end
  
  # removed str_buf handling
  def inspect_ary
    add_function :rb_str_new, :rb_inspect
    <<-END
      function inspect_ary(ary) {
        var tainted = OBJ_TAINTED(ary);
        var str = rb_str_new("[");
        for (var s, i = 0, p = ary.ptr, l = p.length; i < l; ++i) {
          s = rb_inspect(p[i]);
          if (OBJ_TAINTED(s)) { tainted = Qtrue; }
          if (i > 0) { str.ptr += ", "; }
          str.ptr += s.ptr;
        }
        str.ptr += "]";
        if (tainted) { OBJ_TAINT(str); }
        return str;
      }
    END
  end
  
  # verbatim
  def inspect_call
    <<-END
      function inspect_call(arg) {
        return arg.func(arg.arg1, arg.arg2);
      }
    END
  end
  
  # verbatim
  def inspect_ensure
    add_function :rb_ary_pop, :get_inspect_tbl
    <<-END
      function inspect_ensure(obj) {
        var inspect_tbl = get_inspect_tbl(Qfalse);
        if (!NIL_P(inspect_tbl)) { rb_ary_pop(inspect_tbl); }
        return 0;
      }
    END
  end
  
  # verbatim
  def inspect_join
    add_function :rb_ary_join
    <<-END
      function inspect_join(ary, arg) {
        return rb_ary_join(arg[0], arg[1]);
      }
    END
  end
  
  # verbatim
  def memfill
    <<-END
      function memfill(mem, size, val) {
        for (var i = 0; i < size; ++i) {
          mem[i] = val;
        }
      }
    END
  end
  
  # modified 'search_method' to return array instead of using pointers
  def rb_Array
    add_function :rb_check_array_type, :rb_intern, :search_method, :rb_raise, :rb_funcall, :rb_ary_new3
    add_method :to_a
    <<-END
      function rb_Array(val) {
        var tmp = rb_check_array_type(val);
        if (NIL_P(tmp)) {
          var id = rb_intern('to_a');
          var m = search_method(CLASS_OF(val), id);
          var body = m[0];
          var origin = m[1];
          if (body && (origin.m_tbl != rb_mKernel.m_tbl)) {
            val = rb_funcall(val, id, 0);
            if (TYPE(val) != T_ARRAY) { rb_raise(rb_eTypeError, "'to_a' did not return Array"); }
            return val;
          } else {
            return rb_ary_new3(1, val);
          }
        }
        return tmp;
      }
    END
  end
  
  # modified rb_range_beg_len to return array instead of using pointers
  def rb_ary_aref
    add_function :rb_ary_subseq, :rb_scan_args, :rb_ary_entry, :rb_raise, :rb_range_beg_len, :rb_num2long
    <<-END
      function rb_ary_aref(argc, argv, ary) {
        if (argc == 2) {
          if (SYMBOL_P(argv[0])) { rb_raise(rb_eTypeError, "Symbol as array index"); }
          var beg = NUM2LONG(argv[0]);
          var len = NUM2LONG(argv[1]);
          if (beg < 0) { beg += ary.ptr.length; }
          return rb_ary_subseq(ary, beg, len);
        }
        if (argc != 1) { rb_scan_args(argc, argv, '11'); }
        var arg = argv[0];
        /* special case - speeding up */
        if (FIXNUM_P(arg)) { return rb_ary_entry(ary, FIX2LONG(arg)); }
        if (SYMBOL_P(arg)) { rb_raise(rb_eTypeError, "Symbol as array index"); }
        /* check if idx is Range */
        var tmp = rb_range_beg_len(arg, ary.ptr.length, 0);
        switch (tmp[0]) {
          case Qfalse:
            break;
          case Qnil:
            return Qnil;
          default:
            return rb_ary_subseq(ary, tmp[1], tmp[2]);
        }
        return rb_ary_entry(ary, NUM2LONG(arg));
      }
    END
  end
  
  # modified rb_range_beg_len to return array instead of using pointers, unwound 'goto' architecture
  def rb_ary_aset
    add_function :rb_raise, :rb_ary_splice, :rb_range_beg_len, :rb_ary_store, :rb_num2long
    <<-END
      function rb_ary_aset(argc, argv, ary) {
        if (argc == 3) {
          if (SYMBOL_P(argv[0])) { rb_raise(rb_eTypeError, "Symbol as array index"); }
          if (SYMBOL_P(argv[1])) { rb_raise(rb_eTypeError, "Symbol as subarray length"); }
          rb_ary_splice(ary, NUM2LONG(argv[0]), NUM2LONG(argv[1]), argv[2]);
          return argv[2];
        }
        if (argc != 2) { rb_raise(rb_eArgError, "wrong number of arguments (%d for 2)", argc); }
        var offset;
        if (FIXNUM_P(argv[0])) {
          offset = FIX2LONG(argv[0]);
        } else { // added to handle 'goto fixnum'
          if (SYMBOL_P(argv[0])) { rb_raise(rb_eTypeError, "Symbol as array index"); }
          var tmp = rb_range_beg_len(argv[0], ary.ptr.length, 1);
          if (tmp[0]) {
            /* check if idx is Range */
            rb_ary_splice(ary, tmp[1], tmp[2], argv[1]);
            return argv[1];
          }
          offset = NUM2LONG(argv[0]);
        }
        rb_ary_store(ary, offset, argv[1]);
        return argv[1];
      }
    END
  end
  
  # verbatim
  def rb_ary_at
    add_function :rb_ary_entry
    <<-END
      function rb_ary_at(ary, pos) {
        return rb_ary_entry(ary, NUM2LONG(pos));
      }
    END
  end
  
  # verbatim
  def rb_ary_cmp
    add_function :to_ary, :rb_exec_recursive, :recursive_cmp
    <<-END
      function rb_ary_cmp(ary1, ary2) {
        ary2 = to_ary(ary2);
        if (ary1 == ary2) { return INT2FIX(0); }
        var v = rb_exec_recursive(recursive_cmp, ary1, ary2);
        if (v != Qundef) { return v; }
        var len = ary1.ptr.length - ary2.ptr.length;
        if (len === 0) { return INT2FIX(0); }
        if (len > 0) { return INT2FIX(1); }
        return INT2FIX(-1);
      }
    END
  end
  
  # verbatim
  def rb_ary_diff
    add_function :ary_make_hash, :to_ary, :rb_ary_new, :st_lookup, :rb_ary_push, :rb_ary_elt
    <<-END
      function rb_ary_diff(ary1, ary2) {
        var hash = ary_make_hash(to_ary(ary2), 0);
        var ary3 = rb_ary_new();
        for (var i = 0, p = ary1.ptr, l = p.length; i < l; ++i) {
          if (st_lookup(hash.tbl, p[i], 0)) { continue; }
          rb_ary_push(ary3, rb_ary_elt(ary1, i));
        }
        return ary3;
      }
    END
  end
  
  # changed rb_ary_new2 to rb_ary_new, expanded DUPSETUP
  def rb_ary_dup
    add_function :rb_ary_dup, :rb_obj_class, :rb_copy_generic_ivar
    <<-END
      function rb_ary_dup(ary) {
        var dup = rb_ary_new();
        OBJSETUP(dup, rb_obj_class(ary), ary.basic.flags & (T_MASK|FL_EXIVAR|FL_TAINT));
        if (FL_TEST(ary, FL_EXIVAR)) { rb_copy_generic_ivar(dup, ary); }
        MEMCPY(dup.ptr, ary.ptr, ary.ptr.length);
        return dup;
      }
    END
  end
  
  # verbatim
  def rb_ary_each
    add_function :rb_yield
    <<-END
      function rb_ary_each(ary) {
        RETURN_ENUMERATOR(ary, 0, 0);
        for (var i = 0, p = ary.ptr, l = p.length; i < l; ++i) {
          rb_yield(p[i]);
        }
        return ary;
      }
    END
  end
  
  # verbatim
  def rb_ary_elt
    <<-END
      function rb_ary_elt(ary, offset) {
        var p = ary.ptr;
        if (p.length === 0) { return Qnil; }
        if ((offset < 0) || (p.length <= offset)) { return Qnil; }
        return p[offset];
      }
    END
  end
  
  # verbatim
  def rb_ary_entry
    add_function :rb_ary_elt
    <<-END
      function rb_ary_entry(ary, offset) {
        if (offset < 0) { offset += ary.ptr.length; }
        return rb_ary_elt(ary, offset);
      }
    END
  end
  
  # renamed 'recursive_eql' to 'ary_recursive_eql'
  def rb_ary_eql
    add_function :rb_exec_recursive, :ary_recursive_eql
    <<-END
      function rb_ary_eql(ary1, ary2) {
        if (ary1 == ary2) { return Qtrue; }
        if (TYPE(ary2) != T_ARRAY) { return Qfalse; }
        if (ary1.ptr.length != ary2.ptr.length) { return Qfalse; }
        return rb_exec_recursive(ary_recursive_eql, ary1, ary2);
      }
    END
  end
  
  # verbatim
  def rb_ary_equal
    add_function :rb_respond_to, :rb_intern, :rb_equal, :rb_exec_recursive, :recursive_equal
    add_method :to_ary
    <<-END
      function rb_ary_equal(ary1, ary2) {
        if (ary1 == ary2) { return Qtrue; }
        if (TYPE(ary2) != T_ARRAY) {
          if (!rb_respond_to(ary2, rb_intern('to_ary'))) { return Qfalse; }
          return rb_equal(ary2, ary1);
        }
        if (ary1.ptr.length != ary2.ptr.length) { return Qfalse; }
        return rb_exec_recursive(recursive_equal, ary1, ary2);
      }
    END
  end
  
  # verbatim
  def rb_ary_hash
    add_function :rb_exec_recursive, :recursive_hash
    <<-END
      function rb_ary_hash(ary) {
        return rb_exec_recursive(recursive_hash, ary, 0);
      }
    END
  end
  
  # verbatim
  def rb_ary_includes
    add_function :rb_equal
    <<-END
      function rb_ary_includes(ary, item) {
        for (var i = 0, p = ary.ptr, l = p.length; i < l; ++i) {
          if (rb_equal(p[i], item)) { return Qtrue; }
        }
        return Qfalse;
      }
    END
  end
  
  # removed capacity handler and multiple warnings
  def rb_ary_initialize
    add_function :rb_scan_args, :rb_ary_modify, :rb_check_array_type,
                 :rb_ary_replace, :rb_raise, :rb_block_given_p, :rb_ary_store,
                 :rb_yield, :memfill, :rb_num2long
    <<-END
      function rb_ary_initialize(argc, argv, ary) {
        rb_ary_modify(ary);
        var tmp = rb_scan_args(argc, argv, '02');
        var size = tmp[1];
        var val = tmp[2];
        if (tmp[0] === 0) { return ary; } // removed 'RARRAY(ary)->len = 0' and warning
        if ((argc == 1) && !FIXNUM_P(size)) {
          val = rb_check_array_type(size);
          if (!NIL_P(val)) {
            rb_ary_replace(ary, val);
            return ary;
          }
        }
        var len = NUM2LONG(size);
        if (len < 0) { rb_raise(rb_eArgError, "negative array size"); }
        if (len > ARY_MAX_SIZE) { rb_raise(rb_eArgError, "array size too big"); }
        // removed capacity handler
        if (rb_block_given_p()) {
          // removed warning
          for (var i = 0; i < len; i++) {
            rb_ary_store(ary, i, rb_yield(LONG2NUM(i)));
          // removed 'RARRAY(ary)->len = i + 1'
          }
        } else {
          memfill(ary.ptr, len, val);
          // removed 'RARRAY(ary)->len = len'
        }
        return ary;
      }
    END
  end
  
  # changed rb_str_new2 to rb_str_new
  def rb_ary_inspect
    add_function :rb_str_new, :rb_inspecting_p, :rb_protect_inspect, :inspect_ary
    <<-END
      function rb_ary_inspect(ary) {
        if (ary.ptr.length === 0) { return rb_str_new("[]"); }
        if (rb_inspecting_p(ary)) { rb_str_new("[...]"); }
        return rb_protect_inspect(inspect_ary, ary, 0);
      }
    END
  end
  
  # removed 'len' and 'str_buf' handling
  def rb_ary_join
    add_function :rb_check_string_type, :rb_inspecting_p, :rb_str_new,
                 :rb_protect_inspect, :inspect_join, :rb_obj_as_string
    <<-END
      function rb_ary_join(ary, sep) {
        var taint = Qfalse;
        var result = rb_str_new();
        var tmp;
        if (ary.ptr.length === 0) { return result; }
        if (OBJ_TAINTED(ary) || OBJ_TAINTED(sep)) { taint = Qtrue; }
        for (var i = 0, p = ary.ptr, l = ary.ptr.length; i < l; ++i) {
          rb_check_string_type(p[i]);
        }
        if (!NIL_P(sep)) { StringValue(sep); }
        for (i = 0; i < l; ++i) {
          tmp = p[i];
          switch (TYPE(tmp)) {
            case T_STRING:
              break;
            case T_ARRAY:
              if (rb_inspecting_p(tmp)) {
                tmp = rb_str_new("[...]");
              } else {
                var args = [tmp, sep];
                tmp = rb_protect_inspect(inspect_join, ary, args);
              }
              break;
            default:
              tmp = rb_obj_as_string(tmp);
          }
          if (i > 0 && !NIL_P(sep)) { result += sep.ptr; }
          result.ptr += tmp.ptr; // was rb_str_buf_append(result, tmp);
          if (OBJ_TAINTED(tmp)) { taint = Qtrue; }
        }
        if (taint) { OBJ_TAINT(result); }
        return result;
      }
    END
  end
  
  # modified rb_scan_args
  def rb_ary_join_m
    add_function :rb_scan_args, :rb_ary_join
    <<-END
      function rb_ary_join_m(argc, argv, ary){
        var tmp = rb_scan_args(argc, argv, '01');
        var sep = tmp[1];
        if (tmp[0] === 0) { sep = rb_output_fs; }
        return rb_ary_join(ary, sep);
      }
    END
  end
  
  # verbatim
  def rb_ary_length
    add_function :rb_int2inum
    <<-END
      function rb_ary_length(ary) {
        return LONG2NUM(ary.ptr.length);
      }
    END
  end
  
  # removed ELTS_SHARED stuff
  def rb_ary_modify
    add_function :rb_ary_modify_check
    <<-END
      function rb_ary_modify(ary) {
        rb_ary_modify_check(ary);
      }
    END
  end
  
  # verbatim
  def rb_ary_modify_check
    add_function :rb_error_frozen, :rb_raise
    <<-END
      function rb_ary_modify_check(ary) {
        if (OBJ_FROZEN(ary)) { rb_error_frozen("array"); }
        if (FL_TEST(ary, ARY_TMPLOCK)) { rb_raise(rb_eRuntimeError, "can't modify array during iteration"); }
        if (!OBJ_TAINTED(ary) && ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "Insecure: can't modify array"); }
      }
    END
  end
  
  # replaced ARY_DEFAULT_SIZE with 0
  def rb_ary_new
    add_function :ary_new
    <<-END
      function rb_ary_new() {
        return ary_new(rb_cArray, 0);
      }
    END
  end
  
  # modified to use JS 'arguments' object instead of va_list
  def rb_ary_new3
    <<-END
      function rb_ary_new3(n) {
        var ary = rb_ary_new();
        for (var i = 0, p = ary.ptr; i < n; ++i) {
          p[i] = arguments[i + 1];
        }
        return ary;
      }
    END
  end
  
  # changed rb_ary_new2 to rb_ary_new
  def rb_ary_new4
    add_function :rb_ary_new
    <<-END
      function rb_ary_new4(n, elts) {
        var ary = rb_ary_new();
        if (n > 0 && elts) { MEMCPY(ary.ptr, elts, n); }
        return ary;
      }
    END
  end
  
  # verbatim
  def rb_ary_or
    add_function :to_ary, :rb_ary_new, :ary_make_hash, :rb_ary_elt, :rb_ary_push
    <<-END
      function rb_ary_or(ary1, ary2) {
        ary2 = to_ary(ary2);
        var ary3 = rb_ary_new();
        var hash = ary_make_hash(ary1, ary2);
        for (var v, vv, tmp, i = 0, l = ary1.ptr.length; i < l; ++i) {
          v = vv = rb_ary_elt(ary1, i);
          tmp = st_delete(hash.tbl, vv, 0);
          if (tmp[0]) { rb_ary_push(ary3, v); }
        }
        for (i = 0, l = ary2.ptr.length; i < l; ++i) {
          v = vv = rb_ary_elt(ary2, i);
          tmp = st_delete(hash.tbl, vv, 0);
          if (tmp[0]) { rb_ary_push(ary3, v); }
        }
        return ary3;
      }
    END
  end
  
  # removed ELTS_SHARED stuff
  def rb_ary_pop
    add_function :rb_ary_modify_check
    <<-END
      function rb_ary_pop(ary) {
        rb_ary_modify_check(ary);
        if (ary.ptr.length === 0) { return Qnil; }
        return ary.ptr.pop();
      }
    END
  end
  
  # verbatim
  def rb_ary_pop_m
    add_function :ary_shared_first, :rb_ary_modify_check
    <<-END
      function rb_ary_pop_m(argc, argv, ary) {
        var result;
        if (argc === 0) { return rb_ary_pop(ary); }
        rb_ary_modify_check(ary);
        result = ary_shared_first(argc, argv, ary, Qtrue);
        return result;
      }
    END
  end
  
  # hacked MEMCPY with offset
  def rb_ary_plus
    add_function :to_ary, :rb_ary_new
    <<-END
      function rb_ary_plus(x, y) {
        y = to_ary(y);
        var z = rb_ary_new();
        MEMCPY(z.ptr, x.ptr, x.ptr.length);
        MEMCPY(z.ptr, y.ptr, y.ptr.length, x.ptr.length);
        return z;
      }
    END
  end
  
  # CHECK
  def rb_ary_push
    <<-END
      function rb_ary_push(ary, item) {
        ary.ptr.push(item); // was rb_ary_store(ary, RARRAY(ary)->len, item);
        return ary;
      }
    END
  end
  
  # EMPTY
  def rb_ary_replace
    <<-END
      function rb_ary_replace() {}
    END
  end
  
  # modified to use simple JS 'reverse'
  def rb_ary_reverse
    add_function :rb_ary_modify
    <<-END
      function rb_ary_reverse(ary) {
        rb_ary_modify(ary);
        if (ary.ptr.length > 1) { ary.ptr.reverse(); }
        return ary;
      }
    END
  end
  
  # verbatim
  def rb_ary_reverse_bang
    add_function :rb_ary_reverse
    <<-END
      function rb_ary_reverse_bang(ary) {
        return rb_ary_reverse(ary);
      }
    END
  end
  
  # verbatim
  def rb_ary_reverse_m
    add_function :rb_ary_reverse, :rb_ary_dup
    <<-END
      function rb_ary_reverse_m(ary) {
        return rb_ary_reverse(rb_ary_dup(ary));
      }
    END
  end
  
  # removed 'len' and 'capa' handling
  def rb_ary_s_create
    add_function :ary_alloc
    <<-END
      function rb_ary_s_create(argc, argv, klass) {
        var ary = ary_alloc(klass);
        if (argc > 0) {
          ary.ptr = [];
          MEMCPY(ary.ptr, argv, argc);
        }
        return ary;
      }
    END
  end
  
  # verbatim
  def rb_ary_sort_bang
    add_function :rb_ensure, :sort_internal, :sort_unlock, :rb_ary_modify
    <<-END
      function rb_ary_sort_bang(ary) {
        rb_ary_modify(ary);
        if (ary.ptr.length > 1) {
          FL_SET(ary, ARY_TMPLOCK); /* prohibit modification during sort */
          rb_ensure(sort_internal, ary, sort_unlock, ary);
        }
        return ary;
      }
    END
  end
  
  # removed 'capa' handling, STILL NEEDS TO BE FIXED (MEMMOVE)
  def rb_ary_splice
    add_function :rb_raise, :rb_ary_to_ary, :rb_ary_modify, :rb_mem_clear
    <<-END
      function rb_ary_splice(ary, beg, len, rpl) {
        var rlen;
        if (len < 0) { rb_raise(rb_eIndexError, "negative length (%d)", len); }
        if (beg < 0) {
          beg += ary.ptr.length;
          if (beg < 0) {
            beg -= ary.ptr.length;
            rb_raise(rb_eIndexError, "index %d out of array", beg);
          }
        }
        if ((ary.ptr.length < len) || (ary.ptr.length < (beg + len))) { len = ary.ptr.length - beg; }
        if (NIL_P(rpl)) {
          rlen = 0;
        } else {
          rpl = rb_ary_to_ary(rpl);
          rlen = rpl.ptr.length;
        }
        rb_ary_modify(ary);
        if (beg >= ary.ptr.length) {
          if (beg > (ARY_MAX_SIZE - rlen)) { rb_raise(rb_eIndexError, "index %d too big", beg); }
          len = beg + rlen;
          rb_mem_clear(ary.ptr, beg - ary.ptr.length, ary.ptr.length);
          if (rlen > 0) { MEMCPY(ary.ptr, rpl.ptr, rlen, beg); }
        } else {
          if ((beg + len) > ary.ptr.length) { len = ary.ptr.length - beg; }
          var alen = ary.ptr.length + rlen - len;
          if (len != rlen) { MEMMOVE(ary.ptr + beg + rlen, ary.ptr + beg + len, VALUE, ary.ptr.length - (beg + len)); }
          if (rlen > 0) { MEMMOVE(ary.ptr + beg, rpl.ptr, VALUE, rlen); }
        }
      }
    END
  end
  
  # removed 'len' and 'capa' handling
  def rb_ary_store
    add_function :rb_raise, :rb_mem_clear, :rb_ary_modify
    <<-END
      function rb_ary_store(ary, idx, val) {
        var len = ary.ptr.length;
        if (idx < 0) {
          idx += len;
          if (idx < 0) { rb_raise(rb_eIndexError, "index %d out of array", idx - len); }
        } else if (idx >= ARY_MAX_SIZE) {
          rb_raise(rb_eIndexError, "index %d too big", idx);
        }
        rb_ary_modify(ary);
        if (idx > len) { rb_mem_clear(ary.ptr, idx - len + 1, len); }
        if (idx >= len) { len = idx + 1; }
        ary.ptr[idx] = val;
      }
    END
  end
  
  # verbatim
  def rb_ary_subseq
    add_function :rb_obj_class, :ary_new, :ary_make_shared, :ary_alloc
    <<-END
      function rb_ary_subseq(ary, beg, len) {
        var p = ary.ptr;
        var l = p.length;
        if (beg > l) { return Qnil; }
        if ((beg < 0) || (len < 0)) { return Qnil; }
        if ((l < len) || (l < (beg + len))) {
          len = l - beg;
          if (len < 0) { len = 0; }
        }
        var klass = rb_obj_class(ary);
        if (len === 0) { return ary_new(klass, 0); }
        var shared = ary_make_shared(ary);
        var ptr = p;
        var ary2 = ary_alloc(klass);
        ary2.ptr = ptr + beg;
        ary2.aux.shared = shared;
        FL_SET(ary2, ELTS_SHARED);
        return ary2;
      }
    END
  end
  
  # modified to use simple JS 'push'; CHECK: may be faster to restore to original [i]= methodology
  def rb_ary_times
    add_function :rb_ary_join, :rb_check_string_type, :ary_new, :rb_obj_class, :rb_raise, :rb_num2long
    <<-END
      function rb_ary_times(ary, times) {
        var tmp = rb_check_string_type(times);
        if (!NIL_P(tmp)) { return rb_ary_join(ary, tmp); }
        var len = NUM2LONG(times);
        if (len === 0) { return ary_new(rb_obj_class(ary), 0); }
        if (len < 0) { rb_raise(rb_eArgError, "negative argument"); }
        if ((ARY_MAX_SIZE / len) < ary.ptr.length) { rb_raise(rb_eArgError, "argument too big"); }
        var ary2 = ary_new(rb_obj_class(ary, 0));
        for (var i = 0, p1 = ary.ptr, p2 = ary2.ptr; i < len; ++i) { 
          for (var j = 0, l = p1.length; j < l; ++j) {
            p2.push(p1[j]);
          }
        }
        OBJ_INFECT(ary2, ary);
        return ary2;
      }
    END
  end
  
  # changed rb_ary_new2 to rb_ary_new
  def rb_ary_to_a
    add_function :rb_obj_class, :rb_ary_new, :rb_ary_replace
    <<-END
      function rb_ary_to_a(ary) {
        if (rb_obj_class(ary) != rb_cArray) {
          var dup = rb_ary_new();
          rb_ary_replace(dup, ary);
          return dup;
        }
        return ary;
      }
    END
  end
  
  # verbatim
  def rb_ary_to_ary
    add_function :rb_respond_to, :rb_intern, :rb_convert_type, :rb_ary_new3
    add_method :to_ary
    <<-END
      function rb_ary_to_ary(obj) {
        if (TYPE(obj) == T_ARRAY) { return obj; }
        if (rb_respond_to(obj, rb_intern('to_ary'))) { return rb_convert_type(obj, T_ARRAY, 'Array', 'to_ary'); }
        return rb_ary_new3(1, obj);
      }
    END
  end
  
  # verbatim
  def rb_ary_to_ary_m
    <<-END
      function rb_ary_to_ary_m(ary) {
        return ary;
      }
    END
  end
  
  # verbatim
  def rb_ary_to_s
    add_function :rb_str_new, :rb_ary_join
    <<-END
      function rb_ary_to_s(ary) {
        if (ary.ptr.length === 0) { return rb_str_new(0); }
        return rb_ary_join(ary, rb_output_fs);
      }
    END
  end
  
  # modified to use simple JS 'unshift'
  def rb_ary_unshift
    add_function :rb_ary_modify
    <<-END
      function rb_ary_unshift(ary, item) {
        rb_ary_modify(ary);
        ary.ptr.unshift(item);
        return ary;
      }
    END
  end
  
  # changed rb_ary_new2 to rb_ary_new
  def rb_assoc_new
    add_function :rb_ary_new
    <<-END
      function rb_assoc_new(car, cdr) {
        var ary = rb_ary_new();
        ary.ptr[0] = car;
        ary.ptr[1] = cdr;
        return ary;
      }
    END
  end
  
  # verbatim
  def rb_check_array_type
    add_function :rb_check_convert_type
    add_method :to_ary
    <<-END
      function rb_check_array_type(ary) {
        return rb_check_convert_type(ary, T_ARRAY, 'Array', 'to_ary');
      }
    END
  end
  
  # verbatim
  def rb_inspecting_p
    add_function :get_inspect_tbl, :rb_ary_includes, :rb_obj_id
    <<-END
      function rb_inspecting_p(obj) {
        var inspect_tbl = get_inspect_tbl(Qfalse);
        if (NIL_P(inspect_tbl)) { return Qfalse; }
        return rb_ary_includes(inspect_tbl, rb_obj_id(obj));
      }
    END
  end
  
  # modified to use 'offset'
  def rb_mem_clear
    <<-END
      function rb_mem_clear(mem, size, offset) {
        for (var i = 0; i < size; ++i) {
          mem[i] = Qnil;
        }
      }
    END
  end
  
  # verbatim
  def rb_protect_inspect
    add_function :rb_ary_new, :rb_obj_id, :rb_ary_includes, :rb_ary_push, :rb_ensure, :inspect_call, :inspect_ensure, :get_inspect_tbl
    <<-END
      function rb_protect_inspect(func, obj, arg) {
        var iarg = {};
        var inspect_tbl = get_inspect_tbl(Qtrue);
        var id = rb_obj_id(obj);
        if (rb_ary_includes(inspect_tbl, id)) { return func(obj, arg); }
        rb_ary_push(inspect_tbl, id);
        var iarg = { func: func, arg1: obj, arg2: arg };
        return rb_ensure(inspect_call, iarg, inspect_ensure, obj); // &iarg
      }
    END
  end
  
  # verbatim
  def recursive_cmp
    add_function :rb_funcall, :rb_ary_elt
    add_method :'<=>'
    <<-END
      function recursive_cmp(ary1, ary2, recur) {
        if (recur) { return Qnil; }
        var len = ary1.ptr.length;
        if (len > ary2.ptr.length) { len = ary2.ptr.length; }
        for (var i = 0; i < len; i++) {
          var v = rb_funcall(rb_ary_elt(ary1, i), id_cmp, 1, rb_ary_elt(ary2, i));
          if (v != INT2FIX(0)) { return v; }
        }
        return Qundef;
      }
    END
  end
  
  # verbatim
  def recursive_equal
    add_function :rb_equal, :rb_ary_elt
    <<-END
      function recursive_equal(ary1, ary2, recur) {
        if (recur) { return Qfalse; }
        for (var i = 0, p = ary1.ptr, l = p.length; i < l; ++i) {
          if (!rb_equal(rb_ary_elt(ary1, i), rb_ary_elt(ary2, i))) { return Qfalse; }
        }
        return Qtrue;
      }
    END
  end
  
  # EMPTY
  def ruby_qsort
    <<-END
      function ruby_qsort() {}
    END
  end
  
  # EMPTY
  def sort_1
    <<-END
      function sort_1() {}
    END
  end
  
  # EMPTY
  def sort_2
    <<-END
      function sort_2() {}
    END
  end
  
  # 
  def sort_internal
    add_function :ruby_qsort, :sort_1, :sort_2
    <<-END
      function sort_internal(ary) {
        var data = {};
        data.ary = ary;
        data.ptr = ary.ptr;
        data.len = ary.ptr.length;
        ruby_qsort(ary.ptr, ary.ptr.len, /*sizeof(VALUE),*/ rb_block_given_p() ? sort_1 : sort_2, data);
        return ary;
      }
    END
  end
  
  # verbatim
  def sort_unlock
    <<-END
      function sort_unlock(ary) {
        FL_UNSET(ary, ARY_TMPLOCK);
        return ary;
      }
    END
  end
  
  # verbatim
  def to_ary
    add_function :rb_convert_type
    add_method :to_ary
    <<-END
      function to_ary(ary) {
        return rb_convert_type(ary, T_ARRAY, 'Array', 'to_ary');
      }
    END
  end
end
