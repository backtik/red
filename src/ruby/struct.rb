class Red::MethodCompiler
  # modified string handling
  def inspect_struct
    add_function :rb_class2name, :rb_obj_class, :rb_struct_members,
                 :rb_is_local_id, :rb_is_const_id, :rb_id2name, :rb_inspect
    <<-END
      function inspect_struct(s) {
        var cname = rb_class2name(rb_obj_class(s));
        var members = rb_struct_members(s);
        var str = rb_str_new("#<struct " + cname + " ");
        for (var i = 0, p = s.ptr, l = p.length; i < l; ++i) {
          if (i > 0) { str.ptr += ", "; }
          var slot = members.ptr[i];
          var id = SYM2ID(slot);
          if (rb_is_local_id(id) || rb_is_const_id(id)) {
            str.ptr += rb_id2name(id);
          } else {
            str.ptr += rb_inspect(slot).ptr;
          }
          str.ptr += "=" + rb_inspect(p[i]).ptr;
        }
        str.ptr += ">";
        OBJ_INFECT(str, s);
        return str;
      }
    END
  end
  
  # 
  def make_struct
    add_function :rb_class_new, :rb_make_metaclass, :rb_class_inherited,
                 :rb_intern, :rb_is_const_id, :rb_name_error,
                 :rb_const_defined_at, :rb_mod_remove_const,
                 :rb_define_class_under, :rb_id2name, :rb_iv_set,
                 :rb_define_alloc_func, :rb_define_singleton_method,
                 :rb_class_new_instance, :rb_struct_s_members_m,
                 :rb_is_local_id, :rb_define_method_id, :rb_id_attrset,
                 :rb_struct_set, :rb_struct_ref, :rb_int2inum, :struct_alloc,
                 :rb_string_value
    <<-END
      function make_struct(name, members, klass) {
        var nstr;
        var id;
        OBJ_FREEZE(members);
        if (NIL_P(name)) {
          nstr = rb_class_new(klass);
          rb_make_metaclass(nstr, klass.basic.klass);
          rb_class_inherited(klass, nstr);
        } else {
          var cname = rb_string_value(name).ptr;
          id = rb_intern(cname);
          if (!rb_is_const_id(id)) { rb_name_error(id, "identifier %s needs to be constant", cname); }
          if (rb_const_defined_at(klass, id)) {
            // removed warning
            rb_mod_remove_const(klass, ID2SYM(id));
          }
          nstr = rb_define_class_under(klass, rb_id2name(id), klass);
        }
        rb_iv_set(nstr, '__size__', LONG2NUM(members.ptr.length));
        rb_iv_set(nstr, '__members__', members);
        rb_define_alloc_func(nstr, struct_alloc);
        rb_define_singleton_method(nstr, 'new', rb_class_new_instance, -1);
        rb_define_singleton_method(nstr, '[]', rb_class_new_instance, -1);
        rb_define_singleton_method(nstr, 'members', rb_struct_s_members_m, 0);
        for (var i = 0, p = members.ptr, l = p.length; i < l; ++i) {
          id = SYM2ID(p[i]);
          if (rb_is_local_id(id) || rb_is_const_id(id)) {
            if (i < 10) {
              rb_define_method_id(nstr, id, ref_func[i], 0);
            } else {
              rb_define_method_id(nstr, id, rb_struct_ref, 0);
            }
            rb_define_method_id(nstr, rb_id_attrset(id), rb_struct_set, 1);
          }
        }
        return nstr;
      }
    END
  end
  
  # verbatim
  def rb_struct_alloc
    add_function :rb_class_new_instance
    <<-END
      function rb_struct_alloc(klass, values) {
        return rb_class_new_instance(values.ptr.length, values.ptr, klass);
      }
    END
  end
  
  # verbatim
  def rb_struct_aset
    add_function :rb_struct_aset_id, :rb_to_id, :rb_raise, :rb_struct_modify, :rb_num2long
    <<-END
      function rb_struct_aset(s, idx, val) {
        if ((TYPE(idx) == T_STRING) || (TYPE(idx) == T_SYMBOL)) { return rb_struct_aset_id(s, rb_to_id(idx), val); }
        var i = NUM2LONG(idx);
        if (i < 0) { i = s.ptr.length + i; }
        if (i < 0) { rb_raise(rb_eIndexError, "offset %d too small for struct(size:%d)", i, s.ptr.length); }
        if (s.ptr.length <= i) { rb_raise(rb_eIndexError, "offset %d too large for struct(size:%d)", i, s.ptr.length); }
        rb_struct_modify(s);
        return s.ptr[i] = val;
      }
    END
  end
  
  # verbatim
  def rb_struct_aset_id
    add_function :rb_struct_members, :rb_struct_modify, :rb_raise, :rb_name_error, :rb_id2name
    <<-END
      function rb_struct_aset_id(s, id, val) {
        var members = rb_struct_members(s);
        rb_struct_modify(s);
        var len = members.ptr.length;
        if (s.ptr.length != len) { rb_raise(rb_eTypeError, "struct size differs (%d required %d given)", len, s.ptr.length); }
        for (var i = 0, p = members.ptr; i < len; ++i) {
          if (SYM2ID(p[i]) == id) {
            p[i] = val;
            return val;
          }
        }
        rb_name_error(id, "no member '%s' in struct", rb_id2name(id));
      }
    END
  end
  
  # verbatim
  def rb_struct_each
    add_function :rb_yield
    <<-END
      function rb_struct_each(s) {
        RETURN_ENUMERATOR(s, 0, 0);
        for (var i = 0, p = s.ptr, l = p.length; i < l; ++i) {
          rb_yield(p[i]);
        }
        return s;
      }
    END
  end
  
  # verbatim
  def rb_struct_each_pair
    add_function :rb_yield_values, :rb_ary_entry, :rb_struct_members
    <<-END
      function rb_struct_each_pair(s) {
        RETURN_ENUMERATOR(s, 0, 0);
        var members = rb_struct_members(s);
        for (var i = 0, p = s.ptr, l = p.length; i < l; ++i) {
          rb_yield_values(2, rb_ary_entry(members, i), p[i]);
        }
        return s;
      }
    END
  end
  
  # removed bug warning
  def rb_struct_equal
    add_function :rb_equal, :rb_obj_class
    <<-END
      function rb_struct_equal(s, s2) {
        if (s == s2) { return Qtrue; }
        if (TYPE(s2) != T_STRUCT) { return Qfalse; }
        if (rb_obj_class(s) != rb_obj_class(s2)) { return Qfalse; }
        for (var i = 0, p = s.ptr, p2 = s2.ptr, l = s.ptr.length; i < l; ++i) {
          if (!rb_equal(p[i], p2[i])) { return Qfalse; }
        }
        return Qtrue;
      }
    END
  end
  
  # removed bug warning
  def rb_struct_eql
    add_function :rb_obj_class, :rb_eql
    <<-END
      function rb_struct_eql(s, s2) {
        if (s == s2) { return Qtrue; }
        if (TYPE(s2) != T_STRUCT) { return Qfalse; }
        if (rb_obj_class(s) != rb_obj_class(s2)) { return Qfalse; }
        for (var i = 0, p = s.ptr, p2 = s2.ptr, l = p.length; i < l; ++i) {
          if (!rb_eql(p[i], p2[i])) { return Qfalse; }
        }
        return Qtrue;
      }
    END
  end
  
  # verbatim
  def rb_struct_getmember
    add_function :rb_name_error, :rb_id2name, :rb_struct_members
    <<-END
      function rb_struct_getmember(obj, id) {
        var members = rb_struct_members(obj);
        var slot = ID2SYM(id);
        for (var i = 0, p = members.ptr, l = p.length; i < l; ++i) {
          if (p[i] == slot) { return obj.ptr[i]; }
        }
        rb_name_error(id, "%s is not struct member", rb_id2name(id));
        return Qnil; /* not reached */
      }
    END
  end
  
  # verbatim
  def rb_struct_hash
    add_function :rb_hash, :rb_obj_class, :rb_num2long
    <<-END
      function rb_struct_hash(s) {
        var n;
        var h = rb_hash(rb_obj_class(s));
        for (var i = 0, l = s.len; i < l; ++i) {
          h = (h << 1) | ((h < 0) ? 1 : 0);
          n = rb_hash(s.ptr[i]);
          h ^= NUM2LONG(n);
        }
        return LONG2FIX(h);
      }
    END
  end
  
  # verbatim
  def rb_struct_init_copy
    add_function :rb_check_frozen, :rb_obj_is_instance_of, :rb_obj_class, :rb_raise
    <<-END
      function rb_struct_init_copy(copy, s) {
        if (copy == s) { return copy; }
        rb_check_frozen(copy);
        if (!rb_obj_is_instance_of(s, rb_obj_class(copy))) { rb_raise(rb_eTypeError, "wrong argument class"); }
        if (copy.ptr.length != s.ptr.length) { rb_raise(rb_eTypeError, "struct size mismatch"); }
        MEMCPY(copy.ptr, s.ptr, copy.ptr.length);
        return copy;
      }
    END
  end
  
  # verbatim
  def rb_struct_initialize
    add_function :rb_struct_iv_get, :rb_raise, :rb_obj_class, :rb_mem_clear, :rb_struct_modify
    <<-END
      function rb_struct_initialize(self, values) {
        var klass = rb_obj_class(self);
        rb_struct_modify(self);
        var size = rb_struct_iv_get(klass, '__size__');
        var n = FIX2LONG(size);
        if (n < values.ptr.length) { rb_raise(rb_eArgError, "struct size differs"); }
        MEMCPY(self.ptr, values.ptr, values.ptr.length);
        if (n > values.ptr.length) { rb_mem_clear(self.ptr, n - values.ptr.length, values.ptr.length); }
        return Qnil;
      }
    END
  end
  
  # modified string handling
  def rb_struct_inspect
    add_function :rb_inspecting_p, :rb_class2name, :rb_obj_class, :rb_protect_inspect, :inspect_struct
    <<-END
      function rb_struct_inspect(s) {
        if (rb_inspecting_p(s)) {
          var cname = rb_class2name(rb_obj_class(s));
          var str = rb_str_new(jsprintf("#<struct %s:...>", cname));
          return str;
        }
        return rb_protect_inspect(inspect_struct, s, 0);
      }
    END
  end
  
  # verbatim
  def rb_struct_iv_get
    add_function :rb_ivar_defined, :rb_ivar_get
    <<-END
      function rb_struct_iv_get(c, name) {
        var id = rb_intern(name);
        for (;;) {
          if (rb_ivar_defined(c, id)) { return rb_ivar_get(c, id); }
          c = c.superclass;
          if ((c === 0) || (c == rb_cStruct)) { return Qnil; }
        }
      }
    END
  end
  
  # verbatim
  def rb_struct_members
    add_function :rb_struct_s_members, :rb_obj_class, :rb_raise
    <<-END
      function rb_struct_members(s) {
        var members = rb_struct_s_members(rb_obj_class(s));
        if (s.ptr.length != members.ptr.length) { rb_raise(rb_eTypeError, "struct size differs (%d required %d given)", members.ptr.length, s.ptr.length); }
        return members;
      }
    END
  end
  
  # verbatim
  def rb_struct_members_m
    add_function :rb_struct_members_m, :rb_obj_class
    <<-END
      function rb_struct_members_m(obj) {
        return rb_struct_s_members_m(rb_obj_class(obj));
      }
    END
  end
  
  # verbatim
  def rb_struct_modify
    add_function :rb_error_frozen, :rb_raise
    <<-END
      function rb_struct_modify(s) {
        if (OBJ_FROZEN(s)) { rb_error_frozen("Struct"); }
        if (!OBJ_TAINTED(s) && (ruby_safe_level >= 4)) { rb_raise(rb_eSecurityError, "Insecure: can't modify Struct"); }
      }
    END
  end
  
  # modified to use JS arguments instead of va_list
  def rb_struct_new
    add_function :rb_struct_iv_get, :rb_class_new_instance
    <<-END
      function rb_struct_new(klass) {
        var sz = rb_struct_iv_get(klass, '__size__');
        var size = FIX2LONG(sz); 
        var mem = [];
        for (var i = 1; i < size; ++i) {
          mem[i] = arguments[i + 1];
        }
        return rb_class_new_instance(size, mem, klass);
      }
    END
  end
  
  # verbatim
  def rb_struct_ref
    add_function :rb_struct_getmember
    <<-END
      function rb_struct_ref(obj) {
        return rb_struct_getmember(obj, ruby_frame.orig_func);
      }
    END
  end
  
  # verbatim
  def rb_struct_s_def
    add_function :rb_ary_unshift, :rb_to_id, :rb_scan_args, :rb_block_given_p, :make_struct, :rb_mod_module_eval
    <<-END
      function rb_struct_s_def(argc, argv, klass) {
        var tmp = rb_scan_args(argc, argv, '1*');
        var name = tmp[1];
        var rest = tmp[2];
        if (!NIL_P(name) && SYMBOL_P(name)) {
          rb_ary_unshift(rest, name);
          name = Qnil;
        }
        var id;
        for (var i = 0, p = rest.ptr, l = p.length; i < l; ++i) {
          id = rb_to_id(p[i]);
          p[i] = ID2SYM(id);
        }
        var st = make_struct(name, rest, klass);
        if (rb_block_given_p()) { rb_mod_module_eval(0, 0, st); }
        return st;
      }
    END
  end
  
  # verbatim
  def rb_struct_s_members
    add_function :rb_struct_iv_get, :rb_raise
    <<-END
      function rb_struct_s_members(klass) {
        var members = rb_struct_iv_get(klass, '__members__');
        if (NIL_P(members)) { rb_raise(rb_eTypeError, "uninitialized struct"); }
        if (TYPE(members) != T_ARRAY) { rb_raise(rb_eTypeError, "corrupted struct"); }
        return members;
      }
    END
  end
  
  # changed 'while' loop to 'for' loop
  def rb_struct_s_members_m
    add_function :rb_struct_s_members, :rb_ary_new, :rb_ary_push, :rb_str_new, :rb_id2name
    <<-END
      function rb_struct_s_members_m(klass) {
        var members = rb_struct_s_members(klass);
        var ary = rb_ary_new();
        for (var i = 0, p = members.ptr, l = p.length; i < l; ++i) {
          rb_ary_push(ary, rb_str_new(rb_id2name(SYM2ID(p[i]))));
        }
        return ary;
      }
    END
  end
  
  # verbatim
  def rb_struct_select
    add_function :rb_raise, :rb_ary_new, :rb_yield, :rb_ary_push
    <<-END
      function rb_struct_select(argc, argv, s) {
        if (argc > 0) { rb_raise(rb_eArgError, "wrong number of arguments (%d for 0)", argc); }
        var result = rb_ary_new();
        for (var i = 0, p = s.ptr, l = p.length; i < l; i++) {
          if (RTEST(rb_yield(p[i]))) { rb_ary_push(result, p[i]); }
        }
        return result;
      }
    END
  end
  
  # verbatim
  def rb_struct_set
    add_function :rb_struct_members, :rb_struct_modify, :rb_id_attrset,
                 :rb_name_error, :rb_id2name, :rb_name_error
    <<-END
      function rb_struct_set(obj, val) {
        rb_struct_modify(obj);
        var slot;
        var members = rb_struct_members(obj);
        var id = ruby_frame.orig_func;
        for (var i = 0, p = members.ptr, l = p.length; i < l; ++i) {
          slot = p[i];
          if (rb_id_attrset(SYM2ID(slot)) == id) { return obj.ptr[i] = val; }
        }
        rb_name_error(ruby_frame.last_func, "'%s' is not a struct member", rb_id2name(id));
        return Qnil; /* not reached */
      }
    END
  end
  
  # verbatim
  def rb_struct_size
    <<-END
      function rb_struct_size(s) {
        return LONG2FIX(s.ptr.length);
      }
    END
  end
  
  # verbatim
  def rb_struct_to_a
    add_function :rb_ary_new4
    <<-END
      function rb_struct_to_a(s) {
        return rb_ary_new4(s.ptr.length, s.ptr);
      }
    END
  end
  
  # verbatim
  def rb_struct_values_at
    add_function :rb_values_at, :struct_entry
    <<-END
      function rb_struct_values_at(argc, argv, s) {
        return rb_values_at(s, s.ptr.length, argc, argv, struct_entry);
      }
    END
  end
  
  # verbatim
  def struct_alloc
    <<-END
      function struct_alloc(klass) {
        NEWOBJ(st);
        OBJSETUP(st, klass, T_STRUCT);
        var size = rb_struct_iv_get(klass, '__size__');
        var n = FIX2LONG(size);
        st.ptr = [];
        rb_mem_clear(st.ptr, n);
        return st;
      }
    END
  end
end
