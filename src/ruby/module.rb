class Red::MethodCompiler
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
  def rb_mod_eqq
    add_function :rb_obj_is_kind_of
    <<-END
      function rb_mod_eqq(mod, arg) {
        return rb_obj_is_kind_of(arg, mod);
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
          rb_funcall(argv[argc], rb_intern("append_features"), 1, module);
          rb_funcall(argv[argc], rb_intern("included"), 1, module);
        }
        return module;
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
        //clone.iv_tbl = st_copy(RCLASS(orig)->iv_tbl);
          id = rb_intern("__classpath__");
        //st_delete(clone.iv_tbl, (st_data_t*)&id, 0);
          id = rb_intern("__classid__");
        //st_delete(clone.iv_tbl, (st_data_t*)&id, 0);
        }
        if (orig.m_tbl) {
          var data;
          data.tbl = clone.m_tbl = st_init_numtable();
          data.klass = clone;
        //st_foreach(orig.m_tbl, clone_method, (st_data_t)&data);
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
  
  # CHECK
  def rb_mod_to_s
    add_function :rb_str_new, :rb_iv_get, :rb_str_cat, :rb_str_append,
                 :rb_inspect, :rb_str_dup, :rb_any_to_s, :rb_class_name
    <<-END
      function rb_mod_to_s(klass) {
        if (FL_TEST(klass, FL_SINGLETON)) {
          var s = rb_str_new("#<"); // changed from rb_str_new2
          var v = rb_iv_get(klass, "__attached__");
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
