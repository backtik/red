class Red::MethodCompiler
  # verbatim
  def clone_method
    add_function :rb_copy_node_scope, :st_insert
    <<-END
      function clone_method(mid, body, data) {
        var fbody = body.nd_body;
        if (fbody && (nd_type(fbody) == NODE_SCOPE)) { fbody = rb_copy_node_scope(fbody, ruby_cref); }
        st_insert(data.tbl, mid, NEW_METHOD(fbody, body.nd_noex));
        return ST_CONTINUE;
      }
    END
  end
  
  # verbatim
  def include_class_new
    add_function :st_init_numtable
    <<-END
      function include_class_new(module, superclass) {
        NEWOBJ(klass);
        OBJSETUP(klass, rb_cClass, T_ICLASS);
        if (BUILTIN_TYPE(module) == T_ICLASS) { module = module.basic.klass; }
        if (!module.iv_tbl) { module.iv_tbl = st_init_numtable(); }
        klass.iv_tbl = module.iv_tbl;
        klass.m_tbl = module.m_tbl;
        klass.superclass = superclass;
        klass.basic.klass = (TYPE(module) == T_ICLASS) ? module.basic.klass : module;
        OBJ_INFECT(klass, module);
        OBJ_INFECT(klass, superclass);
        return klass;
      }
    END
  end
  
  # verbatim
  def rb_check_inheritable
    add_function :rb_raise, :rb_obj_classname
    <<-END
      function rb_check_inheritable(superclass) {
        if (TYPE(superclass) != T_CLASS) { rb_raise(rb_eTypeError, "superclass must be a Class (%s given)", rb_obj_classname(superclass)); }
        if (superclass.basic.flags & FL_SINGLETON) { rb_raise(rb_eTypeError, "can't make subclass of virtual class"); }
      }
    END
  end
  
  # verbatim
  def rb_class_allocate_instance
    <<-END
      function rb_class_allocate_instance(klass) {
        NEWOBJ(obj);
        OBJSETUP(obj, klass, T_OBJECT);
        return obj;
      }
    END
  end
  
  # verbatim
  def rb_class_boot
    add_function :st_init_numtable
    <<-END
      function rb_class_boot(superclass) {
        NEWOBJ(klass);
        OBJSETUP(klass, rb_cClass, T_CLASS);
        klass.superclass = superclass;
        klass.iv_tbl = 0;
        klass.m_tbl = st_init_numtable();
        OBJ_INFECT(klass, superclass);
        return klass;
      }
    END
  end
  
  # verbatim
  def rb_class_inherited
    add_function :rb_funcall, :rb_intern
    add_method :inherited
    <<-END
      function rb_class_inherited(superclass, klass) {
        if (!superclass) { superclass = rb_cObject; }
        return rb_funcall(superclass, rb_intern('inherited'), 1, klass);
      }
    END
  end
  
  # verbatim
  def rb_class_init_copy
    add_function :rb_raise, :rb_mod_init_copy
    <<-END
      function rb_class_init_copy(clone, orig)
      {
        if (clone.superclass !== 0) { rb_raise(rb_eTypeError, "already initialized class"); }
        if (FL_TEST(orig, FL_SINGLETON)) { rb_raise(rb_eTypeError, "can't copy singleton class"); }
        return rb_mod_init_copy(clone, orig);
      }
    END
  end
  
  # expanded rb_scan_args
  def rb_class_initialize
    add_function :rb_raise, :rb_scan_args, :rb_check_inheritable, :rb_make_metaclass, :rb_mod_initialize, :rb_class_inherited
    <<-END
      function rb_class_initialize(argc, argv, klass) {
        var superclass;
        if (klass.superclass !== 0) { rb_raise(rb_eTypeError, "already initialized class"); }
        var tmp = rb_scan_args(argc, argv, '01');
        superclass = tmp[1];
        if (tmp[0] === 0) {
          superclass = rb_cObject;
        } else {
          rb_check_inheritable(superclass);
        }
        klass.superclass = superclass;
        rb_make_metaclass(klass, superclass.basic.klass);
        rb_mod_initialize(klass);
        rb_class_inherited(superclass, klass);
        return klass;
      }
    END
  end
  
  # verbatim
  def rb_class_new
    add_function :rb_raise, :rb_class_boot, :rb_check_type
    <<-END
      function rb_class_new(superclass) {
        Check_Type(superclass, T_CLASS);
        if (superclass == rb_cClass) { rb_raise(rb_eTypeError, "can't make a subclass of Class"); }
        if (FL_TEST(superclass, FL_SINGLETON)) { rb_raise(rb_eTypeError, "can't make subclass of virtual class"); }
        return rb_class_boot(superclass);
      }
    END
  end
  
  # verbatim
  def rb_class_new_instance
    add_function :rb_obj_alloc, :rb_obj_call_init
    <<-END
      function rb_class_new_instance(argc, argv, klass) {
        var obj = rb_obj_alloc(klass);
        rb_obj_call_init(obj, argc, argv);
        return obj;
      }
    END
  end
  
  # verbatim
  def rb_class_s_alloc
    add_function :rb_class_boot
    <<-END
      function rb_class_s_alloc(klass) {
        return rb_class_boot(0);
      }
    END
  end
  
  # verbatim
  def rb_class_superclass
    add_function :rb_raise
    <<-END
      function rb_class_superclass(klass) {
        var superclass = klass.superclass;
        if (!superclass) { rb_raise(rb_eTypeError, "uninitialized class"); }
        if (FL_TEST(klass, FL_SINGLETON)) { superclass = klass.basic.klass; }
        while (TYPE(superclass) == T_ICLASS) { superclass = superclass.superclass; }
        return superclass || Qnil;
      }
    END
  end
  
  # verbatim
  def rb_define_alias
    add_function :rb_alias, :rb_intern
    <<-END
      function rb_define_alias(klass, name1, name2) {
        rb_alias(klass, rb_intern(name1), rb_intern(name2));
      }
    END
  end
  
  # verbatim
  def rb_define_class
    add_function :rb_const_defined, :rb_const_get, :rb_raise,
                 :rb_class_real, :rb_name_error, :rb_define_class_id,
                 :rb_name_class, :rb_const_set, :rb_class_inherited
    <<-END
      function rb_define_class(name, superclass) {
        var klass;
        var id = rb_intern(name);
        if (rb_const_defined(rb_cObject, id)) {
          klass = rb_const_get(rb_cObject, id);
          if (TYPE(klass) != T_CLASS) { rb_raise(rb_eTypeError, "%s is not a class", name); }
          if (rb_class_real(klass.superclass) != superclass) { rb_name_error(id, "%s is already defined", name); }
          return klass;
        }
        // removed warning
        klass = rb_define_class_id(id, superclass);
        rb_class_tbl[id] = klass; // changed from st_add_direct
        rb_name_class(klass, id);
        rb_const_set(rb_cObject, id, klass);
        rb_class_inherited(superclass, klass);
        return klass;
      }
    END
  end
  
  # verbatim
  def rb_define_class_id
    add_function :rb_class_new, :rb_make_metaclass
    <<-END
      function rb_define_class_id(id, superclass) {
        if (!superclass) { superclass = rb_cObject; }
        var klass = rb_class_new(superclass);
        rb_make_metaclass(klass, superclass.basic.klass);
        return klass;
      }
    END
  end
  
  # verbatim
  def rb_define_class_under
    add_function :rb_const_defined_at, :rb_const_get_at, :rb_raise,
                 :rb_class_real, :rb_name_error, :rb_define_class_id,
                 :rb_set_class_path, :rb_const_set, :rb_class_inherited
    <<-END
      function rb_define_class_under(outer, name, superclass) {
        var klass;
        var id = rb_intern(name);
        if (rb_const_defined_at(outer, id)) {
          klass = rb_const_get_at(outer, id);
          if (TYPE(klass) != T_CLASS) { rb_raise(rb_eTypeError, "%s is not a class", name); }
          if (rb_class_real(klass.superclass) != superclass) { rb_name_error(id, "%s is already defined", name); }
          return klass;
        }
        // removed warning
        klass = rb_define_class_id(id, superclass);
        rb_set_class_path(klass, outer, name);
        rb_const_set(outer, id, klass);
        rb_class_inherited(superclass, klass);
        return klass;
      }
    END
  end
  
  # verbatim
  def rb_define_global_function
    add_function :rb_define_module_function
    <<-END
      function rb_define_global_function(name, func, argc) {
        rb_define_module_function(rb_mKernel, name, func, argc);
      }
    END
  end
  
  # verbatim
  def rb_define_method
    add_function :rb_add_method
    <<-END
      function rb_define_method(klass, name, func, argc) {
        rb_add_method(klass, rb_intern(name), NEW_CFUNC(func, argc), NOEX_PUBLIC);
      }
    END
  end
  
  # verbatim
  def rb_define_method_id
    add_function :rb_add_method
    <<-END
      function rb_define_method_id(klass, name, func, argc) {
        rb_add_method(klass, name, NEW_CFUNC(func, argc), NOEX_PUBLIC);
      }
    END
  end
  
  # verbatim
  def rb_define_module
    add_function :rb_const_defined, :rb_const_get, :rb_raise,
                 :rb_obj_classname, :rb_define_module_id, :rb_const_set
    <<-END
      function rb_define_module(name) {
        var module;
        var id = rb_intern(name);
        if (rb_const_defined(rb_cObject, id)) {
          module = rb_const_get(rb_cObject, id);
          if (TYPE(module) == T_MODULE) { return module; }
          rb_raise(rb_eTypeError, "%s is not a module", rb_obj_classname(module));
        }
        module = rb_define_module_id(id);
        rb_class_tbl[id] = module; // was st_add_direct
        rb_const_set(rb_cObject, id, module);
        return module;
      }
    END
  end
  
  # verbatim
  def rb_define_module_function
    add_function :rb_define_private_method, :rb_define_singleton_method
    <<-END
      function rb_define_module_function(module, name, func, argc) {
        rb_define_private_method(module, name, func, argc);
        rb_define_singleton_method(module, name, func, argc);
      }
    END
  end
  
  # verbatim
  def rb_define_module_id
    add_function :rb_name_class, :rb_module_new
    <<-END
      function rb_define_module_id(id) {
        var mdl = rb_module_new();
        rb_name_class(mdl, id);
        return mdl;
      }
    END
  end
  
  # verbatim
  def rb_define_private_method
    add_function :rb_add_method
    <<-END
      function rb_define_private_method(klass, name, func, argc) {
        rb_add_method(klass, rb_intern(name), NEW_CFUNC(func, argc), NOEX_PRIVATE);
      }
    END
  end
  
  # verbatim
  def rb_define_singleton_method
    add_function :rb_define_method, :rb_singleton_class
    <<-END
      function rb_define_singleton_method(obj, name, func, argc) {
        rb_define_method(rb_singleton_class(obj), name, func, argc);
      }
    END
  end
  
  # reworked 'goto' architecture using variable
  def rb_include_module
    add_function :rb_frozen_class_p, :rb_secure, :rb_raise, :include_class_new, :rb_clear_cache, :rb_check_type
    <<-END
      function rb_include_module(klass, module) {
        var changed = 0;
        rb_frozen_class_p(klass);
        if (!OBJ_TAINTED(klass)) { rb_secure(4); }
        if (TYPE(module) != T_MODULE) { Check_Type(module, T_MODULE); }
        OBJ_INFECT(klass, module);
        var c = klass;
        var goto_skip = 0; // added
        while (module) {
          var superclass_seen = Qfalse;
          if (klass.m_tbl == module.m_tbl) { rb_raise(rb_eArgError, "cyclic include detected"); }
          /* ignore if the module included already in superclasses */
          for (var p = klass.superclass; p; p = p.superclass) {
            switch (BUILTIN_TYPE(p)) {
              case T_ICLASS:
                if (p.m_tbl == module.m_tbl) {
                  if (!superclass_seen) { c = p; } /* move insertion point */
                  goto_skip = 1; // changed to variable
                }
                break;
              case T_CLASS:
                superclass_seen = Qtrue;
                break;
            }
            if (goto_skip) { break; } // added
          }
          if (!goto_skip) { // added
            c = c.superclass = include_class_new(module, c.superclass);
            changed = 1;
          }
          module = module.superclass;
        }
        if (changed) { rb_clear_cache(); }
      }
    END
  end
  
  # verbatim
  def rb_make_metaclass
    add_function :rb_class_boot, :rb_singleton_class_attached, :rb_class_real
    <<-END
      function rb_make_metaclass(obj, superclass) {
        var klass = rb_class_boot(superclass);
        FL_SET(klass, FL_SINGLETON);
        obj.basic.klass = klass;
        rb_singleton_class_attached(klass, obj);
        if (BUILTIN_TYPE(obj) == T_CLASS && FL_TEST(obj, FL_SINGLETON)) {
          klass.basic.klass = klass;
          klass.superclass = rb_class_real(obj.superclass).basic.klass;
        } else {
          var metasuper = rb_class_real(superclass).basic.klass;
          if (metasuper) { klass.basic.klass = metasuper; }
        }
        return klass;
      }
    END
  end
  
  # changed st table to object
  def rb_module_new
    add_function :st_init_numtable
    <<-END
      function rb_module_new() {
        NEWOBJ(mdl);
        OBJSETUP(mdl, rb_cModule, T_MODULE);
        mdl.superclass = 0;
        mdl.iv_tbl = 0;
        mdl.m_tbl = st_init_numtable();
        return mdl;
      }
    END
  end
  
  # verbatim
  def rb_module_s_alloc
    add_function :rb_module_new
    <<-END
      function rb_module_s_alloc(klass) {
        var mod = rb_module_new();
        mod.basic.klass = klass;
        return mod;
      }
    END
  end
  
  # verbatim
  def rb_undef_method
    add_function :rb_add_method, :rb_intern
    <<-END
      function rb_undef_method(klass, name) {
        rb_add_method(klass, rb_intern(name), 0, NOEX_UNDEF);
      }
    END
  end
  
  # unpacked SPECIAL_SINGLETON macro
  def rb_singleton_class
    add_function :rb_raise, :rb_special_const_p, :rb_iv_get, :rb_make_metaclass
    <<-END
      function rb_singleton_class(obj) {
        var klass;
        if (FIXNUM_P(obj) || SYMBOL_P(obj)) { rb_raise(rb_eTypeError, "can't define singleton"); }
        if (rb_special_const_p(obj)) {
          if (obj == Qnil)    { return rb_cNilClass; } // was SPECIAL_SINGLETON(Qnil, rb_cNilClass)
          if (obj === Qfalse) { return rb_cFalseClass; } // was SPECIAL_SINGLETON(Qfalse, rb_cFalseClass)
          if (obj == Qtrue)   { return rb_cTrueClass; } // was SPECIAL_SINGLETON(Qtrue, rb_cTrueClass)
        }
      //DEFER_INTS();
        if (FL_TEST(obj.basic.klass, FL_SINGLETON) && (rb_iv_get(obj.basic.klass, '__attached__') == obj)) {
          klass = obj.basic.klass;
        } else {
          klass = rb_make_metaclass(obj, obj.basic.klass);
        }
        if (OBJ_TAINTED(obj)) { OBJ_TAINT(klass); } else { FL_UNSET(klass, FL_TAINT); }
        if (OBJ_FROZEN(obj)) { OBJ_FREEZE(klass); }
      //ALLOW_INTS();
        return klass;
      }
    END
  end
  
  # changed st tables to js objects
  def rb_singleton_class_attached
    add_function :st_init_numtable
    <<-END
      function rb_singleton_class_attached(klass, obj) {
        if (FL_TEST(klass, FL_SINGLETON)) {
          if (!klass.iv_tbl) { klass.iv_tbl = st_init_numtable(); }
          st_insert(klass.iv_tbl, rb_intern('__attached__'), obj);
        }
      }
    END
  end
  
  # verbatim
  def rb_singleton_class_clone
    add_function :st_copy, :st_init_numtable, :st_foreach, :rb_singleton_class_attached
    <<-END
      function rb_singleton_class_clone(obj) {
        var klass = obj.basic.klass;
        if (!FL_TEST(klass, FL_SINGLETON)) {
          return klass;
        } else {
          /* copy singleton(unnamed) class */
          NEWOBJ(clone);
          OBJSETUP(clone, 0, klass.basic.flags);
          if (BUILTIN_TYPE(obj) == T_CLASS) {
            clone.basic.klass = clone;
          } else {
            clone.basic.klass = rb_singleton_class_clone(klass);
          }
          clone.superclass = klass.superclass;
          clone.iv_tbl = 0;
          clone.m_tbl = 0;
          if (klass.iv_tbl) { clone.iv_tbl = st_copy(klass.iv_tbl); }
          var data = {};
          data.tbl = clone.m_tbl = st_init_numtable();
          switch (TYPE(obj)) {
            case T_CLASS:
            case T_MODULE:
              data.klass = obj;
              break;
            default:
              data.klass = 0;
              break;
          }
          st_foreach(klass.m_tbl, clone_method, data);
          rb_singleton_class_attached(clone.basic.klass, clone);
          FL_SET(clone, FL_SINGLETON);
          return clone;
        }
      }
    END
  end
  
  # unwound 'goto' architecture, modified va_arg handling
  # instead of getting pointers in vargs gets 'true' values
  # returns array of values instead of setting pointers: [argc, val1, val2, ...]
  def rb_scan_args
    add_function :rb_raise, :rb_fatal, :rb_ary_new, :rb_block_given_p, :rb_block_proc
    <<-END
      function rb_scan_args(argc, argv, fmt) {
        var n;
        var p = 0;
        var i = 0;
        var ary = [argc];
        var goto_error = 0;
        var goto_rest_arg = 0;
        if (fmt[p] == '*') { goto_rest_arg = 1; }
        if (!goto_rest_arg) { // added to handle 'goto rest_arg'
          if (ISDIGIT(fmt[p])) {
            n = fmt[p] - '0';
            if (argc < n) { rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)", argc, n); }
            for (i = 0; i < n; i++) {
              ary.push(argv[i]);
            }
            p++;
          } else {
            rb_fatal("bad scan arg format: %s", fmt);
            return [0];
          }
          if (ISDIGIT(fmt[p])) {
            n = i + fmt[p] - '0';
            for (; i < n; i++) {
              if (argc > i) {
                ary.push(argv[i]);
              } else {
                ary.push(Qnil);
              }
            }
            p++;
          }
        } // added to handle 'goto rest_arg'
        if (goto_rest_arg || (fmt[p] == '*')) { // added 'goto_rest_arg ||' in condition
          if (argc > i) {
            var ary4 = rb_ary_new();
            MEMCPY(ary4.ptr, argv.slice(i), argc - i);
            ary.push(ary4);
            i = argc;
          } else {
            ary.push(rb_ary_new());
          }
          p++;
        }
        if (fmt[p] == '&') {
          ary.push(rb_block_given_p() ? rb_block_proc() : Qnil);
          p++;
        }
        if (typeof(fmt[p]) != 'undefined') {
          rb_fatal("bad scan arg format: %s", fmt);
          return [0];
        }
        if (argc > i) { rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)", argc, i); }
        return ary;
      }
    END
  end
end
