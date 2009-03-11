class Red::MethodCompiler
  # verbatim
  def convert_type
    add_function :rb_intern, :rb_respond_to, :rb_raise, :rb_funcall
    <<-END
      function convert_type(val, tname, method, raise) {
        var m = rb_intern(method);
        if (!rb_respond_to(val, m)) {
          if (raise) {
            rb_raise(rb_eTypeError, "can't convert %s into %s", NIL_P(val) ? "nil" : val == Qtrue ? "true" : val == Qfalse ? "false" : rb_obj_classname(val), tname);
          } else {
            return Qnil;
          }
        }
        return rb_funcall(val, m, 0);
      }
    END
  end
  
  # removed st_free_table, removed bug warning
  def init_copy
    add_function :rb_raise, :rb_funcall, :rb_copy_generic_ivar
    add_method :initialize_copy
    <<-END
      function init_copy(dest, obj) {
      //if (OBJ_FROZEN(dest)) { rb_raise(rb_eTypeError, "[bug] frozen object (%s) allocated", rb_obj_classname(dest)); }
        dest.flags &= ~(T_MASK|FL_EXIVAR);
        dest.flags |= obj.basic.flags & (T_MASK|FL_EXIVAR|FL_TAINT);
        if (FL_TEST(obj, FL_EXIVAR)) { rb_copy_generic_ivar(dest, obj); }
      //rb_gc_copy_finalizer(dest, obj);
        switch (TYPE(obj)) {
          case T_OBJECT:
          case T_CLASS:
          case T_MODULE:
            if (dest.iv_tbl) { dest.iv_tbl = 0; } // removed st_free_table(ROBJECT(dest)->iv_tbl);
            if (obj.iv_tbl) { dest.iv_tbl = st_copy(obj.iv_tbl); }
        }
        rb_funcall(dest, id_init_copy, 1, obj);
      }
    END
  end
  
  # modified string handling
  def inspect_obj
    add_function :st_foreach_safe, :inspect_i
    <<-END
      function inspect_obj(obj, str) {
        st_foreach_safe(obj.iv_tbl, inspect_i, str);
        str.ptr = '#' + str.ptr + '>'
        OBJ_INFECT(str, obj);
        return str;
      }
    END
  end
  
  # changed rb_str_new2 to rb_str_new
  def main_to_s
    add_function :rb_str_new
    <<-END
      function main_to_s(obj) {
        return rb_str_new("main");
      }
    END
  end
  
  # verbatim
  def obj_respond_to
    add_function :rb_method_boundp, :rb_scan_args, :rb_to_id
    <<-END
      function obj_respond_to(argc, argv, obj) {
        var tmp = rb_scan_args(argc, argv, "11");
        var mid = tmp[1];
        var priv = tmp[2];
        var id = rb_to_id(mid);
        if (rb_method_boundp(CLASS_OF(obj), id, !RTEST(priv))) { return Qtrue; }
        return Qfalse;
      }
    END
  end
  
  # simplified string builder
  def rb_any_to_s
    add_function :rb_str_new, :rb_obj_classname
    <<-END
      function rb_any_to_s(obj) {
        var str = rb_str_new("#<" + rb_obj_classname(obj) + ":0x" + obj.rvalue.toString(16) + ">");
        if (OBJ_TAINTED(obj)) { OBJ_TAINT(str); }
        return str;
      }
    END
  end
  
  # verbatim
  def rb_check_convert_type
    add_function :convert_type, :rb_raise, :rb_obj_classname
    <<-END
      function rb_check_convert_type(val, type, tname, method) {
        /* always convert T_DATA */
        if ((TYPE(val) == type) && (type != T_DATA)) { return val; }
        var v = convert_type(val, tname, method, Qfalse);
        if (NIL_P(v)) { return Qnil; }
        if (TYPE(v) != type) { rb_raise(rb_eTypeError, "%s#%s should return %s", rb_obj_classname(val), method, tname); }
        return v;
      }
    END
  end
  
  # verbatim
  def rb_class_real
    <<-END
      function rb_class_real(klass) {
        while (FL_TEST(klass, FL_SINGLETON) || (TYPE(klass) == T_ICLASS)) { klass = klass.superclass; }
        return klass;
      }
    END
  end
  
  # verbatim
  def rb_convert_type
    add_function :convert_type, :rb_raise, :rb_obj_classname
    <<-END
      function rb_convert_type(val, type, tname, method) {
        if (TYPE(val) == type) { return val; }
        var v = convert_type(val, tname, method, Qtrue);
        if (TYPE(v) != type) { rb_raise(rb_eTypeError, "%s#%s should return %s", rb_obj_classname(val), method, tname); }
        return v;
      }
    END
  end
  
  # verbatim
  def rb_eql
    add_function :rb_funcall
    add_method :eql
    <<-END
      function rb_eql(obj1, obj2)
      {
        return RTEST(rb_funcall(obj1, id_eql, 1, obj2));
      }
    END
  end
  
  # verbatim
  def rb_equal
    add_function :rb_funcall
    add_method :==
    <<-END
      function rb_equal(obj1, obj2) {
        if (obj1 === obj2) { return Qtrue; }
        var result = rb_funcall(obj1, id_eq, 1, obj2);
        return RTEST(result) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def rb_f_array
    add_function :rb_Array
    <<-END
      function rb_f_array(obj, arg) {
        return rb_Array(arg);
      }
    END
  end
  
  # verbatim
  def rb_f_float
    add_function :rb_Float
    <<-END
      function rb_f_float(obj, arg) {
        return rb_Float(arg);
      }
    END
  end
  
  # verbatim
  def rb_f_integer
    add_function :rb_Integer
    <<-END
      function rb_f_integer(obj, arg) {
        return rb_Integer(arg);
      }
    END
  end
  
  # CHECK
  def rb_f_sprintf
    add_function :rb_str_format
    <<-END
      function rb_f_sprintf(argc, argv) {
        if (argc === 0) { rb_raise(rb_eArgError, "too few arguments"); }
        return rb_str_format(argc - 1, argv.slice(1), argv[0]);
      }
    END
  end
  
  # verbatim
  def rb_f_string
    add_function :rb_String
    <<-END
      function rb_f_string(obj, arg) {
        return rb_String(arg);
      }
    END
  end
  
  # verbatim
  def rb_false
    <<-END
      function rb_false() {
        return Qfalse;
      }
    END
  end
  
  # verbatim
  def rb_Float
    add_function :rb_float_new, :rb_big2dbl, :rb_str_to_dbl, :rb_raise, :rb_convert_type, :isnan
    add_method :to_f
    <<-END
      function rb_Float(val) {
        switch (TYPE(val)) {
          case T_FIXNUM:
            return rb_float_new(FIX2LONG(val));
          case T_FLOAT:
            return val;
          case T_BIGNUM:
            return rb_float_new(rb_big2dbl(val));
          case T_STRING:
            return rb_float_new(rb_str_to_dbl(val, Qtrue));
          case T_NIL:
            rb_raise(rb_eTypeError, "can't convert nil into Float");
            break;
          default:
            var f = rb_convert_type(val, T_FLOAT, "Float", "to_f");
            if (isnan(f.value)) { rb_raise(rb_eArgError, "invalid value for Float()"); }
            return f;
        }
      }
    END
  end
  
  # verbatim
  def rb_inspect
    add_function :rb_obj_as_string, :rb_funcall
    add_method :inspect
    <<-END
      function rb_inspect(obj) {
        return rb_obj_as_string(rb_funcall(obj, id_inspect, 0, 0));
      }
    END
  end
  
  # CHECK
  def rb_method_missing
    add_function :rb_funcall, :rb_const_get, :rb_intern, :rb_str_new, :rb_class_new_instance,
                 :rb_exc_raise, :rb_ary_new4
    add_method :_!
    <<-END
      function rb_method_missing(argc, argv, obj) {
        var id;
        var exc = rb_eNoMethodError;
        var format = 0;
        var cnode = ruby_current_node;
        if ((argc === 0) || !SYMBOL_P(argv[0])) { rb_raise(rb_eArgError, "no id given"); }
        id = SYM2ID(argv[0]);
        if (last_call_status & CSTAT_PRIV) { format = "private method '%s' called for %s"; } else
        if (last_call_status & CSTAT_PROT) { format = "protected method '%s' called for %s"; } else
        if (last_call_status & CSTAT_VCALL) { format = "undefined local variable or method '%s' for %s"; exc = rb_eNameError } else
        if (last_call_status & CSTAT_SUPER) { format = "super: no superclass method '%s'"; }
        if (!format) { format = "undefined method '%s' for %s"; }
        ruby_current_node = cnode;
        var n = 0;
        var args = [];
        args[n++] = rb_funcall(rb_const_get(exc, rb_intern("message")), rb_intern("!"), 3, rb_str_new(format), obj, argv[0]); // changed rb_str_new2 to rb_str_new
        args[n++] = argv[0];
        if (exc == rb_eNoMethodError) {
          args[n++] = rb_ary_new4(argc - 1, argv.slice(1));
        }
        exc = rb_class_new_instance(n, args, exc);
        ruby_frame = ruby_frame.prev; /* pop frame for "method_missing" */
        rb_exc_raise(exc);
        return Qnil; /* not reached */
      }
    END
  end
  
  # verbatim
  def rb_obj_alloc
    add_function :rb_raise, :rb_funcall, :rb_obj_class, :rb_class_real
    <<-END
      function rb_obj_alloc(klass) {
        if (klass.superclass == 0) { rb_raise(rb_eTypeError, "can't instantiate uninitialized class"); }
        if (FL_TEST(klass, FL_SINGLETON)) { rb_raise(rb_eTypeError, "can't create instance of virtual class"); }
        var obj = rb_funcall(klass, ID_ALLOCATOR, 0, 0);
        if (rb_obj_class(obj) != rb_class_real(klass)) { rb_raise(rb_eTypeError, "wrong instance allocation"); }
        return obj;
      }
    END
  end
  
  # verbatim
  def rb_obj_call_init
    add_function :rb_block_given_p, :rb_funcall2
    add_method :initialize
    <<-END
      function rb_obj_call_init(obj, argc, argv) {
        PUSH_ITER(rb_block_given_p() ? ITER_PRE : ITER_NOT);
        rb_funcall2(obj, init, argc, argv);
        POP_ITER();
      }
    END
  end
  
  # verbatim
  def rb_obj_class
    add_function :rb_class_real
    <<-END
      function rb_obj_class(obj) {
        return rb_class_real(CLASS_OF(obj));
      }
    END
  end
  
  # verbatim
  def rb_obj_clone
    add_function :rb_special_const_p, :rb_raise, :rb_obj_classname,
                  :rb_obj_alloc, :rb_obj_class, :rb_singleton_class_clone,
                  :init_copy
    <<-END
      function rb_obj_clone(obj) {
        var clone;
        if (rb_special_const_p(obj)) { rb_raise(rb_eTypeError, "can't clone %s", rb_obj_classname(obj)); }
        clone = rb_obj_alloc(rb_obj_class(obj));
        clone.basic.klass = rb_singleton_class_clone(obj);
        clone.basic.flags = (obj.basic.flags | FL_TEST(clone, FL_TAINT)) & ~(FL_FREEZE|FL_FINALIZE);
        init_copy(clone, obj);
        clone.basic.flags |= obj.basic.flags & FL_FREEZE;
        return clone;
      }
    END
  end
  
  # verbatim
  def rb_obj_dummy
    <<-END
      function rb_obj_dummy() {
        return Qnil;
      }
    END
  end
  
  # verbatim
  def rb_obj_dup
    add_function :rb_special_const_p, :rb_raise, :rb_obj_classname,
                 :rb_obj_alloc, :rb_obj_class, :init_copy
    <<-END
      function rb_obj_dup(obj) {
        var dup;
        if (rb_special_const_p(obj)) { rb_raise(rb_eTypeError, "can't dup %s", rb_obj_classname(obj)); }
        dup = rb_obj_alloc(rb_obj_class(obj));
        init_copy(dup, obj);
        return dup;
      }
    END
  end
  
  # verbatim
  def rb_obj_equal
    <<-END
      function rb_obj_equal(obj1, obj2) {
        return (obj1 === obj2) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def rb_obj_freeze
    add_function :rb_raise
    <<-END
      function rb_obj_freeze(obj) {
        if (!OBJ_FROZEN(obj)) {
          if ((rb_safe_level() >= 4) && !OBJ_TAINTED(obj)) { rb_raise(rb_eSecurityError, "Insecure: can't freeze object"); }
          OBJ_FREEZE(obj);
        }
        return obj;
      }
    END
  end
  
  # modified symbol hash function
  def rb_obj_id
    <<-END
      function rb_obj_id(obj) {
        if (TYPE(obj) == T_SYMBOL) { return LONG2FIX(SYM2ID(obj) * 10 + 8); } // was "(SYM2ID(obj) * sizeof(RVALUE) + (4 << 2)) | FIXNUM_FLAG"
        if (SPECIAL_CONST_P(obj)) { return LONG2NUM(obj); }
        return obj.rvalue | FIXNUM_FLAG;
      }
    END
  end
  
  # verbatim
  def rb_obj_init_copy
    add_function :rb_check_frozen, :rb_obj_class, :rb_raise
    <<-END
      function rb_obj_init_copy(obj, orig) {
        if (obj === orig) { return obj; }
        rb_check_frozen(obj);
        if ((TYPE(obj) != TYPE(orig)) || (rb_obj_class(obj) != rb_obj_class(orig))) { rb_raise(rb_eTypeError, "initialize_copy should take same class object"); }
        return obj;
      }
    END
  end
  
  # changed string handling
  def rb_obj_inspect
    add_function :rb_obj_classname, :rb_inspecting_p, :rb_str_new, :rb_protect_inspect, :rb_funcall
    add_method :to_s
    <<-END
      function rb_obj_inspect(obj) {
        if ((TYPE(obj) == T_OBJECT) && obj.iv_tbl) {
          var str;
          var c = rb_obj_classname(obj);
          if (rb_inspecting_p(obj)) {
            str = rb_str_new();
            str.ptr = "#<" + c + ":0x" + obj.toString(16) + " ...>";
            return str;
          }
          str = rb_str_new();
          str.ptr = "-<" + c + ":0x" + obj.toString(16);
          return rb_protect_inspect(inspect_obj, obj, str);
        }
        return rb_funcall(obj, rb_intern("to_s"), 0, 0);
      }
    END
  end
  
  # verbatim
  def rb_obj_is_instance_of
    add_function :rb_raise, :rb_obj_class
    <<-END
      function rb_obj_is_instance_of(obj, c) {
        switch (TYPE(c)) {
          case T_MODULE:
          case T_CLASS:
          case T_ICLASS:
            break;
          default:
            rb_raise(rb_eTypeError, "class or module required");
        }
        return (rb_obj_class(obj) == c) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def rb_obj_is_kind_of
    add_function :rb_raise
    <<-END
      function rb_obj_is_kind_of(obj, c) {
        var cl = CLASS_OF(obj);
        switch (TYPE(c)) {
          case T_MODULE:
          case T_CLASS:
          case T_ICLASS:
            break;
          default:
            rb_raise(rb_eTypeError, "class or module required");
        }
        while (cl) {
          if ((cl == c) || (cl.m_tbl == c.m_tbl)) { return Qtrue; }
          cl = cl.superclass;
        }
        return Qfalse;
      }
    END
  end
  
  # verbatim
  def rb_obj_method
    add_function :mnew, :rb_to_id
    <<-END
      function rb_obj_method(obj, vid) {
        return mnew(CLASS_OF(obj), obj, rb_to_id(vid), rb_cMethod);
      }
    END
  end
  
  # verbatim
  def rb_to_id
    add_function :str_to_id, :rb_id2name, :rb_raise, :rb_check_string_type, :rb_inspect
    <<-END
      function rb_to_id(name) {
        var tmp;
        var id;
        switch (TYPE(name)) {
          case T_STRING:
            return str_to_id(name);
          case T_FIXNUM:
            // removed warning
            id = FIX2LONG(name);
            if (!rb_id2name(id)) { rb_raise(rb_eArgError, "%d is not a symbol", id); }
            break;
          case T_SYMBOL:
            id = SYM2ID(name);
            break;
          default:
            tmp = rb_check_string_type(name);
            if (!NIL_P(tmp)) { return str_to_id(tmp); }
            rb_raise(rb_eTypeError, "%s is not a symbol", rb_inspect(name).ptr);
        }
        return id;
      }
    END
  end
  
  # verbatim
  def rb_to_int
    add_function :rb_to_integer
    add_method :to_int
    <<-END
      function rb_to_int(val) {
        return rb_to_integer(val, "to_int");
      }
    END
  end
  
  # verbatim
  def rb_to_integer
    add_function :convert_type, :rb_obj_is_kind_of, :rb_raise, :rb_obj_classname
    <<-END
      function rb_to_integer(val, method) {
        var v = convert_type(val, "Integer", method, Qtrue);
        if (!rb_obj_is_kind_of(v, rb_cInteger)) { rb_raise(rb_eTypeError, "%s#%s should return Integer", rb_obj_classname(val), method); }
        return v;
      }
    END
  end
end
