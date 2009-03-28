class Red::MethodCompiler
  # verbatim
  def rb_class_inherited_p
    add_function :rb_raise
    <<-END
      function rb_class_inherited_p(mod, arg) {
        var start = mod;
        if (mod == arg) { return Qtrue; }
        switch (TYPE(arg)) {
          case T_MODULE:
          case T_CLASS:
            break;
          default:
            rb_raise(rb_eTypeError, "compared with non class/module");
        }
        if (FL_TEST(mod, FL_SINGLETON)) {
          if (mod.m_tbl == arg.m_tbl) { return Qtrue; }
          mod = mod.basic.klass;
        }
        while (mod) {
          if (mod.m_tbl == arg.m_tbl) { return Qtrue; }
          mod = mod.superclass;
        }
        /* not mod < arg; check if mod > arg */
        while (arg) {
          if (arg.m_tbl == start.m_tbl) { return Qfalse; }
          arg = arg.superclass;
        }
        return Qnil;
      }
    END
  end
  
  # verbatim
  def rb_mod_append_features
    add_function :rb_include_module, :rb_check_type
    <<-END
      function rb_mod_append_features(module, include) {
        switch (TYPE(include)) {
          case T_CLASS:
          case T_MODULE:
            break;
          default:
            Check_Type(include, T_CLASS);
            break;
        }
        rb_include_module(include, module);
        return module;
      }
    END
  end
  
  # verbatim
  def rb_mod_attr
    add_function :rb_attr, :rb_to_id, :rb_scan_args
    <<-END
      function rb_mod_attr(argc, argv, klass) {
        var tmp = rb_scan_args(argc, argv, '11');
        var name = tmp[1];
        var pub = tmp[2];
        rb_attr(klass, rb_to_id(name), 1, RTEST(pub), Qtrue);
        return Qnil;
      }
    END
  end
  
  # verbatim
  def rb_mod_attr_accessor
    add_function :rb_attr, :rb_to_id
    <<-END
      function rb_mod_attr_accessor(argc, argv, klass) {
        for (var i = 0; i < argc; ++i) { rb_attr(klass, rb_to_id(argv[i]), 1, 1, Qtrue); }
        return Qnil;
      }
    END
  end
  
  # verbatim
  def rb_mod_attr_reader
    add_function :rb_attr, :rb_to_id
    <<-END
      function rb_mod_attr_reader(argc, argv, klass) {
        for (var i = 0; i < argc; ++i) { rb_attr(klass, rb_to_id(argv[i]), 1, 0, Qtrue); }
        return Qnil;
      }
    END
  end
  
  # verbatim
  def rb_mod_attr_writer
    add_function :rb_attr, :rb_to_id
    <<-END
      function rb_mod_attr_writer(argc, argv, klass) {
        for (var i = 0; i < argc; ++i) { rb_attr(klass, rb_to_id(argv[i]), 0, 1, Qtrue); }
        return Qnil;
      }
    END
  end
  
  # verbatim
  def rb_mod_cmp
    add_function :rb_class_inherited_p
    <<-END
      function rb_mod_cmp(mod, arg) {
        if (mod == arg) { return INT2FIX(0); }
        switch (TYPE(arg)) {
          case T_MODULE:
          case T_CLASS:
            break;
          default:
            return Qnil;
        }
        var cmp = rb_class_inherited_p(mod, arg);
        if (NIL_P(cmp)) { return Qnil; }
        if (cmp) { return INT2FIX(-1); }
        return INT2FIX(1);
      }
    END
  end
  
  # verbatim
  def rb_mod_eqq
    add_function :rb_obj_is_kind_of
    <<-END
      function rb_mod_eqq(mod, arg) {
        return rb_obj_is_kind_of(arg, mod);
      }
    END
  end
  
  # verbatim
  def rb_mod_ge
    add_function :rb_raise, :rb_class_inherited_p
    <<-END
      function rb_mod_ge(mod, arg) {
        switch (TYPE(arg)) {
          case T_MODULE:
          case T_CLASS:
            break;
          default:
            rb_raise(rb_eTypeError, "compared with non class/module");
        }
        return rb_class_inherited_p(arg, mod);
      }
    END
  end
  
  # verbatim
  def rb_mod_gt
    add_function :rb_mod_ge
    <<-END
      function rb_mod_gt(mod, arg) {
        if (mod == arg) { return Qfalse; }
        return rb_mod_ge(mod, arg);
      }
    END
  end
  
  # verbatim
  def rb_mod_include
    add_function :rb_check_type, :rb_funcall
    add_methods :append_features, :included
    <<-END
      function rb_mod_include(argc, argv, module) {
        for (var i = 0; i < argc; ++i) { Check_Type(argv[i], T_MODULE); }
        while (argc--) {
          rb_funcall(argv[argc], rb_intern('append_features'), 1, module);
          rb_funcall(argv[argc], rb_intern('included'), 1, module);
        }
        return module;
      }
    END
  end
  
  # verbatim
  def rb_mod_include_p
    add_function :rb_check_type
    <<-END
      function rb_mod_include_p(mod, mod2) {
        rb_check_type(mod2, T_MODULE);
        for (var p = mod.superclass; p; p = p.superclass) {
          if (BUILTIN_TYPE(p) == T_ICLASS) {
            if (p.basic.klass == mod2) { return Qtrue; }
          }
        }
        return Qfalse;
      }
    END
  end
  
  # INCOMPLETE -- CHECK ON ST FUNCTIONS
  def rb_mod_init_copy
    add_function :rb_obj_init_copy, :rb_singleton_class_clone, :clone_method, :st_init_numtable
    <<-END
      function rb_mod_init_copy(clone, orig) {
        console.log('check on st_functions in rb_mod_init_copy');
        rb_obj_init_copy(clone, orig);
        if (!FL_TEST(CLASS_OF(clone), FL_SINGLETON)) {
          clone.basic.klass = orig.basic.klass;
          clone.basic.klass = rb_singleton_class_clone(clone);
        }
        clone.superclass = orig.superclass;
        if (orig.iv_tbl) {
          var id;
          clone.iv_tbl = st_copy(orig.iv_tbl);
          id = rb_intern('__classpath__');
          st_delete(clone.iv_tbl, id, 0);
          id = rb_intern('__classid__');
          st_delete(clone.iv_tbl, id, 0);
        }
        if (orig.m_tbl) {
          var data = {};
          data.tbl = clone.m_tbl = st_init_numtable();
          data.klass = clone;
          st_foreach(orig.m_tbl, clone_method, data);
        }
        return clone;
      }
    END
  end
  
  # verbatim
  def rb_mod_initialize
    add_function :rb_block_given_p, :rb_mod_module_eval
    <<-END
      function rb_mod_initialize(module) {
        if (rb_block_given_p()) { rb_mod_module_eval(0, 0, module); }
        return Qnil;
      }
    END
  end
  
  # verbatim
  def rb_mod_lt
    add_function :rb_class_inherited_p
    <<-END
      function rb_mod_lt(mod, arg) {
        if (mod == arg) { return Qfalse; }
        return rb_class_inherited_p(mod, arg);
      }
    END
  end
  
  # verbatim
  def rb_mod_method
    add_function :rb_to_id, :mnew
    <<-END
      function rb_mod_method(mod, vid) {
        return mnew(mod, Qundef, rb_to_id(vid), rb_cUnboundMethod);
      }
    END
  end
  
  # verbatim
  def rb_mod_module_eval
    add_function :specific_eval
    <<-END
      function rb_mod_module_eval(argc, argv, mod) {
        return specific_eval(argc, argv, mod, mod);
      }
    END
  end
  
  # removed 'ruby_wrapper' handling
  def rb_mod_nesting
    <<-END
      function rb_mod_nesting()
      {
        var cbase = ruby_cref;
        var ary = rb_ary_new();
        while (cbase && cbase.nd_next) {
          if (!NIL_P(cbase.nd_clss)) rb_ary_push(ary, cbase.nd_clss);
          cbase = cbase.nd_next;
        }
        return ary;
      }
    END
  end
  
  # verbatim
  def rb_mod_public
    add_function :secure_visibility, :set_method_visibility
    <<-END
      function rb_mod_public(argc, argv, module) {
        secure_visibility(module);
        if (argc == 0) {
          SCOPE_SET(SCOPE_PUBLIC);
        } else {
          set_method_visibility(module, argc, argv, NOEX_PUBLIC);
        }
        return module;
      }
    END
  end
  
  # CHECK
  def rb_mod_to_s
    add_function :rb_str_new, :rb_iv_get, :rb_str_cat, :rb_str_append,
                 :rb_inspect, :rb_str_dup, :rb_any_to_s, :rb_class_name
    <<-END
      function rb_mod_to_s(klass) {
        if (FL_TEST(klass, FL_SINGLETON)) {
          var s = rb_str_new("#<"); // changed from rb_str_new2
          var v = rb_iv_get(klass, '__attached__');
          rb_str_cat(s, "Class:"); // changed from rb_str_cat2
          switch (TYPE(v)) {
            case T_CLASS:
            case T_MODULE:
              rb_str_append(s, rb_inspect(v));
              break;
            default:
              rb_str_append(s, rb_any_to_s(v));
              break;
          }
          rb_str_cat(s, ">"); // changed from rb_str_cat2
          return s;
        }
        return rb_str_dup(rb_class_name(klass));
      }
    END
  end
end
