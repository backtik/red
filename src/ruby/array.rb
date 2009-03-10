class Red::MethodCompiler
  # CHECK
  def ary_alloc
    <<-END
      function ary_alloc(klass) {
        var ary = NEWOBJ();
        OBJSETUP(ary, klass, T_ARRAY);
        ary.ptr = [];
        return ary;
      }
    END
  end
  
  # replaced with simple rb_ary_new
  def get_inspect_tbl
    add_function :rb_ary_new
    <<-END
      function get_inspect_tbl(create) {
        return rb_ary_new();
      }
    END
  end
  
  # CHECK
  def inspect_ary
    add_function :rb_inspect, :rb_str_cat, :rb_str_append
    <<-END
      function inspect_ary(ary) {
        var str = rb_str_new("[");
        for (var i = 0, l = ary.ptr.length; i < l; ++i) {
          s = rb_inspect(ary.ptr[i]);
          if (i > 0) { rb_str_cat(str, ", "); }
          rb_str_append(str, s);
        }
        rb_str_cat(str, "]");
        return str;
      }
    END
  end
  
  # verbatim
  def inspect_call
    <<-END
      function inspect_call(arg) {
        return (arg.func)(arg.arg1, arg.arg2);
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
  
  # CHECK
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
          if (body && origin.m_tbl != rb_mKernel.m_tbl) {
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
  
  # EMPTY
  def rb_ary_equal
    <<-END
      function rb_ary_equal() {}
    END
  end
  
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
    add_function :rb_scan_args, :rb_check_array_type, :rb_ary_replace, :rb_raise, :rb_block_given_p, :rb_ary_store, :rb_yield, :memfill
    <<-END
      function rb_ary_initialize(argc, argv, ary) {
        var len;
      //rb_ary_modify(ary);
        var tmp = rb_scan_args(argc, argv, "02");
        var size = tmp[1];
        var val = tmp[2];
        if (tmp[0] === 0) { return ary; } // removed "RARRAY(ary)->len = 0" and warning
        if ((argc == 1) && !FIXNUM_P(size)) {
          val = rb_check_array_type(size);
          if (!NIL_P(val)) {
            rb_ary_replace(ary, val);
            return ary;
          }
        }
        len = NUM2LONG(size);
        if (len < 0) { rb_raise(rb_eArgError, "negative array size"); }
        if (len > ARY_MAX_SIZE) { rb_raise(rb_eArgError, "array size too big"); }
        // removed capacity handler
        if (rb_block_given_p()) {
          // removed warning
          for (var i = 0; i < len; i++) {
            rb_ary_store(ary, i, rb_yield(LONG2NUM(i)));
          // removed "RARRAY(ary)->len = i + 1"
          }
        } else {
          memfill(ary.ptr, len, val);
          // removed "RARRAY(ary)->len = len"
        }
        return ary;
      }
    END
  end
  
  # CHECK
  def rb_ary_inspect
    add_function :rb_str_new, :rb_inspecting_p, :rb_protect_inspect
    <<-END
      function rb_ary_inspect(ary) {
        if (!ary.ptr.length) { return rb_str_new("[]"); }
        if (rb_inspecting_p(ary)) { rb_str_new("[...]"); }
        return rb_protect_inspect(inspect_ary, ary, 0);
      }
    END
  end
  
  # removed "len" and "str_buf" handling
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
        var tmp = rb_scan_args(argc, argv, "01");
        var sep = tmp[1];
        if (tmp[0] === 0) { sep = rb_output_fs; }
        return rb_ary_join(ary, sep);
      }
    END
  end
  
  # CHECK
  def rb_ary_new
    add_function :ary_alloc
    <<-END
      function rb_ary_new() {
        return ary_alloc(rb_cArray);
      }
    END
  end
  
  # modified to use JS "arguments" object instead of va_list
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
  
  # removed ELTS_SHARED stuff
  def rb_ary_pop
    <<-END
      function rb_ary_pop(ary) {
      //rb_ary_modify_check(ary);
        if (ary.ptr.length == 0) { return Qnil; }
        return ary.ptr.pop();
      }
    END
  end
  
  # 
  def rb_ary_pop_m
    add_function :ary_shared_first
    <<-END
      function rb_ary_pop_m(argc, argv, ary) {
        var result;
        if (argc == 0) { return rb_ary_pop(ary); }
      //rb_ary_modify_check(ary);
        result = ary_shared_first(argc, argv, ary, Qtrue);
        return result;
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
  
  # removed "ary.aux.capa" stuff
  def rb_ary_store
    add_function :rb_raise, :rb_mem_clear
    <<-END
      function rb_ary_store(ary, idx, val) {
        var len = ary.ptr.length;
        if (idx < 0) {
          idx += len;
          if (idx < 0) { rb_raise(rb_eIndexError, "index %ld out of array", idx - len); }
        } else if (idx >= ARY_MAX_SIZE) {
          rb_raise(rb_eIndexError, "index %ld too big", idx);
        }
      //rb_ary_modify(ary);
        if (idx > len) { rb_mem_clear(ary.ptr + len, idx - len + 1); }
        if (idx >= len) { len = idx + 1; }
        ary.ptr[idx] = val;
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
  def rb_ary_to_s
    add_function :rb_str_new, :rb_ary_join
    <<-END
      function rb_ary_to_s(ary) {
        if (ary.ptr.length === 0) { return rb_str_new(0); }
        return rb_ary_join(ary, rb_output_fs);
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
  
  # CHECK
  def rb_check_array_type
    add_function :rb_check_convert_type
    <<-END
      function rb_check_array_type(ary) {
        return rb_check_convert_type(ary, T_ARRAY, "Array", "to_ary");
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
  
  # verbatim
  def rb_mem_clear
    <<-END
      function rb_mem_clear(mem, size) {
        for (var i = 0; i < size; ++i) {
          mem[i] = Qnil;
        }
      }
    END
  end
  
  # CHECK
  def rb_protect_inspect
    add_function :rb_ary_new, :rb_obj_id, :rb_ary_includes, :rb_ary_push, :rb_ensure, :inspect_call, :inspect_ensure
    <<-END
      function rb_protect_inspect(func, obj, arg) {
        var iarg = {};
        var inspect_tbl = rb_ary_new(); // get_inspect_tbl(Qtrue);
        var id = rb_obj_id(obj);
        return func(obj, arg);
        if (rb_ary_includes(inspect_tbl, id)) { return func(obj, arg); }
        rb_ary_push(inspect_tbl, id);
        var iarg = { func: func, arg1: obj, arg2: arg };
        return rb_ensure(inspect_call, iarg, inspect_ensure, obj); // &iarg
      }
    END
  end
  
  # verbatim
  def recursive_eql
    add_function :rb_ary_elt, :rb_eql
    <<-END
      function recursive_eql(ary1, ary2, recur) {
        if (recur) { return Qfalse; }
        for (var i = 0, p = ary1.ptr, l = p.length; i < l; ++i) {
          if (!rb_eql(rb_ary_elt(ary1, i), rb_ary_elt(ary2, i))) { return Qfalse; }
        }
        return Qtrue;
      }
    END
  end
end
