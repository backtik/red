class Red::MethodCompiler
  # removed bug warning
  def classname
    add_function :st_lookup, :rb_intern, :find_class_path, :rb_str_new, :st_insert, :st_delete
    <<-END
      function classname(klass) {
        var tmp;
        var path = Qnil;
        if (!klass) { klass = rb_cObject; }
        if (!klass.iv_tbl) { return find_class_path(klass); } // shifted from end of function
        tmp = st_lookup(klass.iv_tbl, classpath, path);
        path = tmp[1];
        if (!tmp[0]) {
          var classid = rb_intern('__classid__');
          tmp = st_lookup(klass.iv_tbl, classid, path);
          path = tmp[1];
          if (!tmp[0]) { return find_class_path(klass); }
          path = rb_str_new(rb_id2name(SYM2ID(path))); // was rb_str_new2
          st_insert(klass.iv_tbl, classpath, path);
          st_delete(klass.iv_tbl, classid, 0);
        }
        // removed bug warning
        return path;
      }
    END
  end
  
  # verbatim
  def const_missing
    add_function :rb_funcall
    add_method :const_missing
    <<-END
     function const_missing(klass, id) {
        return rb_funcall(klass, rb_intern('const_missing'), 1, ID2SYM(id));
      }
    END
  end
  
  # verbatim
  def cvar_cbase
    add_functions :rb_raise
    <<-END
      function cvar_cbase() {
        var cref = ruby_cref;
        while (cref && cref.nd_next && (NIL_P(cref.nd_clss) || FL_TEST(cref.nd_clss, FL_SINGLETON))) { cref = cref.nd_next; } // removed bug warning
        if (NIL_P(cref.nd_clss)) { rb_raise(rb_eTypeError, "no class variables available"); }
        return cref.nd_clss;
      }
    END
  end
  
  # verbatim
  def fc_i
    add_function :rb_is_const_id, :fc_path
    <<-END
      function fc_i(key, value, res) {
        if (!rb_is_const_id(key)) { return ST_CONTINUE; }
        if (value == res.klass) {
          res.path = fc_path(res, key);
          return ST_STOP;
        }
        switch (TYPE(value)) {
          case T_MODULE:
          case T_CLASS:
            if (!value.iv_tbl) {
              return ST_CONTINUE;
            } else {
              var arg = {};
              var list = res;
              while (list) {
                if (list.track == value) { return ST_CONTINUE; }
                list = list.prev;
              }
              arg.name = key;
              arg.path = 0;
              arg.klass = res.klass;
              arg.track = value;
              arg.prev = res;
              st_foreach_safe(value.iv_tbl, fc_i, arg);
              if (arg.path) {
                res.path = arg.path;
                return ST_STOP;
              }
            }
            break;
          default:
            break;
        }
        return ST_CONTINUE;
      }
    END
  end
  
  # simplified string handling
  def fc_path
    add_function :rb_str_new, :rb_id2name, :st_lookup, :rb_str_dup
    <<-END
      function fc_path(fc, name) {
        var tmp;
        var path = rb_str_new(rb_id2name(name));
        while (fc) {
          if (fc.track == rb_cObject) { break; }
          if (fc.track.iv_tbl && (tmp = st_lookup(fc.track.iv_tbl, classpath, tmp))[0]) {
            tmp = rb_str_dup(tmp[1]);
            tmp.ptr += '::' + path.ptr;
            return tmp;
          }
          tmp = rb_str_new(rb_id2name(fc.name));
          tmp.ptr += '::' + path.ptr;
          path = tmp;
          fc = fc.prev;
        }
        return path;
      }
    END
  end
  
  # verbatim
  def find_class_path
    add_function :st_foreach_safe, :st_foreach, :fc_i, :st_init_numtable, :st_insert, :st_delete
    <<-END
      function find_class_path(klass) {
        var arg = {};
        arg.name = 0;
        arg.path = 0;
        arg.klass = klass;
        arg.track = rb_cObject;
        arg.prev = 0;
        if (rb_cObject.iv_tbl) { st_foreach_safe(rb_cObject.iv_tbl, fc_i, arg); }
        if (arg.path === 0) { st_foreach(rb_class_tbl, fc_i, arg); }
        if (arg.path) {
          if (!klass.iv_tbl) { klass.iv_tbl = st_init_numtable(); }
          st_insert(klass.iv_tbl, classpath, arg.path);
          st_delete(klass.iv_tbl, tmp_classpath, 0);
          return arg.path;
        }
        return Qnil;
      }
    END
  end
  
  # verbatim
  def generic_ivar_defined
    add_function :st_lookup
    <<-END
      function generic_ivar_defined(obj, id) {
        // removed check for generic_iv_tbl
        var tmp = st_lookup(generic_iv_tbl, obj);
        if (!tmp[0]) { return Qfalse; }
        return (st_lookup(tmp[1], id)[0]) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def generic_ivar_get
    add_function :st_lookup
    <<-END
      function generic_ivar_get(obj, id, warn) {
        // removed check for generic_iv_tbl
        var tmp = st_lookup(generic_iv_tbl, obj);
        if (tmp[0]) {
          var tmp2 = st_lookup(tmp[1], id);
          if (tmp2[0]) { return tmp2[1]; }
        }
        // removed warning
        return Qnil;
      }
    END
  end
  
  # verbatim
  def generic_ivar_set
    add_functions :rb_special_const_p, :st_init_numtable, :st_add_direct, :st_insert, :st_lookup
    <<-END
      function generic_ivar_set(obj, id, val) {
        if (rb_special_const_p(obj)) { special_generic_ivar = 1; }
        // removed check for generic_iv_tbl
        var tmp = st_lookup(generic_iv_tbl, obj);
        if (!tmp[0]) {
          FL_SET(obj, FL_EXIVAR);
          var tbl = st_init_numtable();
          st_add_direct(generic_iv_tbl, obj, tbl);
          st_add_direct(tbl, id, val);
          return;
        }
        st_insert(tmp[1], id, val);
      }
    END
  end
  
  # verbatim
  def global_id
    add_function :rb_intern
    <<-END
      function global_id(name) {
        return rb_intern((name[0] == '$') ? name : '$' + name);
      }
    END
  end
  
  # verbatim
  def ivar_get
    add_functions :rb_special_const_p, :generic_ivar_get, :st_lookup
    <<-END
      function ivar_get(obj, id, warn) {
        var tmp;
        switch (TYPE(obj)) {
          case T_OBJECT:
          case T_CLASS:
          case T_MODULE:
            if (obj.iv_tbl && (tmp = st_lookup(obj.iv_tbl, id))[0]) { return tmp[1]; }
            break;
          default:
            if (FL_TEST(obj, FL_EXIVAR) || rb_special_const_p(obj)) { return generic_ivar_get(obj, id, warn); }
        }
        // removed warning
        return Qnil;
      }
    END
  end
  
  # removed 'autoload' call
  def mod_av_set
    add_functions :rb_raise, :rb_error_frozen, :st_init_numtable, :st_insert
    <<-END
      function mod_av_set(klass, id, val, isconst) {
        if (!OBJ_TAINTED(klass) && ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "Insecure: can't set %s", isconst ? "constant" : "class variable"); }
        if (OBJ_FROZEN(klass)) { rb_error_frozen((BUILTIN_TYPE(klass) == T_MODULE) ? "module" : "class"); }
        if (!klass.iv_tbl) { klass.iv_tbl = st_init_numtable(); } // removed 'autoload' call
        st_insert(klass.iv_tbl, id, val);
      }
    END
  end
  
  # verbatim
  def rb_alias_variable
    add_functions :rb_raise, :rb_global_entry, :st_lookup, :st_add_direct
    <<-END
      function rb_alias_variable(name1, name2) {
        struct global_entry *entry1, *entry2;
        st_data_t data1;
        if (ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "Insecure: can't alias global variable"); }
        var entry1;
        var entry2 = rb_global_entry(name2);
        var tmp = st_lookup(rb_global_tbl, name1);
        if (!tmp[0]) {
          entry1 = {};
          entry1.id = name1;
          st_add_direct(rb_global_tbl, name1, entry1);
      //} else if ((entry1 = tmp[1]).variable != entry2.variable) {
      //  var variable = entry1.variable
      //  if (variable.block_trace) { rb_raise(rb_eRuntimeError, "can't alias in tracer"); }
      //  variable.counter--;
      //  if (variable.counter === 0) {
      //    var trace = variable.trace;
      //    while (trace) {
      //      struct trace_var *next = trace->next;
      //      var next = trace.next;
      //      free(trace);
      //      trace = next;
      //    }
      //    free(variable);
      //  }
        } else {
          return;
        }
        entry2.variable.counter++;
        entry1.variable = entry2.variable;
      }
    END
  end
  
  # verbatim
  def rb_attr_get
    add_functions :ivar_get
    <<-END
      function rb_attr_get(obj, id) {
        return ivar_get(obj, id, Qfalse);
      }
    END
  end
  
  # verbatim
  def rb_class_name
    add_functions :rb_class_path, :rb_class_real
    <<-END
      function rb_class_name(klass) {
        return rb_class_path(rb_class_real(klass));
      }
    END
  end
  
  # modified string handling
  def rb_class_path
    add_functions :classname, :rb_obj_class, :rb_class2name, :rb_str_new, :rb_ivar_set, :st_lookup
    <<-END
      function rb_class_path(klass) {
        var tmp;
        var path = classname(klass);
        if (!NIL_P(path)) { return path; }
        tmp = st_lookup(klass.iv_tbl, tmp_classpath, path);
        path = tmp[1];
        if (klass.iv_tbl && tmp[0]) {
          return path;
        } else {
          var s = "Class";
          if (TYPE(klass) == T_MODULE) { s = (rb_obj_class(klass) == rb_cModule) ? "Module" : rb_class2name(klass.basic.klass); }
          path = rb_str_new(jsprintf("#<%s:0x%x>",[s, klass.rvalue]));
          rb_ivar_set(klass, tmp_classpath, path);
          return path;
        }
      }
    END
  end
  
  # verbatim
  def rb_class2name
    add_functions :rb_class_name
    <<-END
      function rb_class2name(klass) {
        return rb_class_name(klass).ptr;
      }
    END
  end
  
  # verbatim
  def rb_const_defined
    add_functions :rb_const_defined_0
    <<-END
      function rb_const_defined(klass, id) {
        return rb_const_defined_0(klass, id, Qfalse, Qtrue);
      }
    END
  end
  
  # removed 'autoload' call, unwound 'goto' architecture
  def rb_const_defined_0
    add_function :st_lookup
    <<-END
      function rb_const_defined_0(klass, id, exclude, recurse) {
        var tmp = klass;
        var mod_retry = 0;
        do { // added to handle 'goto'
          while (tmp) {
            if (tmp.iv_tbl && (st_lookup(tmp.iv_tbl, id))[0]) { return Qtrue; } // removed 'autoload' call
            if (!recurse && (klass != rb_cObject)) { break; }
            tmp = tmp.superclass;
          }
        } while (!exclude && !mod_retry && (BUILTIN_TYPE(klass) == T_MODULE) && (tmp = rb_cObject) && (mod_retry = 1)); // added to handle 'goto'
        return Qfalse;
      }
    END
  end
  
  # verbatim
  def rb_const_defined_at
    add_functions :rb_const_defined_0
    <<-END
      function rb_const_defined_at(klass, id) {
        return rb_const_defined_0(klass, id, Qtrue, Qfalse);
      }
    END
  end
  
  # verbatim
  def rb_const_get
    add_functions :rb_const_get_0
    <<-END
      function rb_const_get(klass, id) {
        return rb_const_get_0(klass, id, Qfalse, Qtrue);
      }
    END
  end
  
  # removed 'autoload' call, unwound 'goto' architecture
  def rb_const_get_0
    add_functions :const_missing
    <<-END
      function rb_const_get_0(klass, id, exclude, recurse) {
        var value;
        var tmp = klass;
        var mod_retry = 0;
        do {
          while (tmp) {
            while (tmp.iv_tbl && (value = st_lookup(tmp.iv_tbl, id))[0]) { return value[1]; } // removed 'autoload' call
            if (!recurse && (klass != rb_cObject)) { break; }
            tmp = tmp.superclass;
          }
        } while (!exclude && !mod_retry && (BUILTIN_TYPE(klass) == T_MODULE) && (tmp = rb_cObject) && (mod_retry = 1));
        return const_missing(klass, id);
      }
    END
  end
  
  # verbatim
  def rb_const_get_at
    add_functions :rb_const_get_0
    <<-END
      function rb_const_get_at(klass, id) {
        return rb_const_get_0(klass, id, Qtrue, Qfalse);
      }
    END
  end
  
  # verbatim
  def rb_const_get_from
    add_functions :rb_const_get_0
    <<-END
      function rb_const_get_from(klass, id) {
        return rb_const_get_0(klass, id, Qtrue, Qtrue);
      }
    END
  end
  
  # verbatim
  def rb_const_set
    add_functions :rb_raise, :rb_id2name, :mod_av_set
    <<-END
      function rb_const_set(klass, id, val) {
        if (NIL_P(klass)) { rb_raise(rb_eTypeError, "no class/module to define constant %s", rb_id2name(id)); }
        mod_av_set(klass, id, val, Qtrue);
      }
    END
  end
  
  # verbatim
  def rb_copy_generic_ivar
    add_function :st_lookup, :st_free_table, :st_insert, :st_copy, :st_add_direct
    <<-END
      function rb_copy_generic_ivar(clone, obj) {
        if (!generic_iv_tbl) { return; }
        if (!FL_TEST(obj, FL_EXIVAR)) { return; }
        var tmp = st_lookup(generic_iv_tbl, obj);
        if (tmp[0]) {
          var tbl = tmp[1];
          tmp = st_lookup(generic_iv_tbl, clone);
          if (tmp[0]) {
            st_free_table(tmp[1]);
            st_insert(generic_iv_tbl, clone, st_copy(tbl));
          } else {
            st_add_direct(generic_iv_tbl, clone, st_copy(tbl));
          }
        }
      }
    END
  end
  
  # verbatim
  def rb_cvar_get
    add_functions :rb_name_error, :rb_id2name, :rb_class2name
    <<-END
      function rb_cvar_get(klass, id) {
        var tmp = klass;
        while (tmp) {
          var value;
          if (tmp.iv_tbl && (value = st_lookup(tmp.iv_tbl, id))[0]) { return value[1]; }
          tmp = tmp.superclass;
        }
        rb_name_error(id, "uninitialized class variable %s in %s", rb_id2name(id), rb_class2name(klass));
        return Qnil; /* not reached */
      }
    END
  end
  
  # verbatim
  def rb_cvar_set
    add_functions :rb_error_frozen, :rb_raise, :mod_av_set, :st_insert, :st_lookup
    <<-END
      function rb_cvar_set(klass, id, val) {
        var tmp = klass;
        while (tmp) {
          if (tmp.iv_tbl && st_lookup(tmp.iv_tbl, id)[0]) {
            if (OBJ_FROZEN(tmp)) { rb_error_frozen("class/module"); }
            if (!OBJ_TAINTED(tmp) && ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "Insecure: can't modify class variable"); }
            // removed warnings
            st_insert(tmp.iv_tbl, id, val);
            return;
          }
          tmp = tmp.superclass;
        }
        mod_av_set(klass, id, val, Qfalse);
      }
    END
  end
  
  # verbatim
  def rb_define_const
    add_functions :rb_const_set, :rb_secure
    <<-END
      function rb_define_const(klass, name, val) {
        // removed warning
        if (klass == rb_cObject) { rb_secure(4); }
        rb_const_set(klass, rb_intern(name), val);
      }
    END
  end
  
  # verbatim
  def rb_define_global_const
    add_functions :rb_define_const
    <<-END
      function rb_define_global_const(name, val) {
        rb_define_const(rb_cObject, name, val);
      }
    END
  end
  
  # verbatim
  def rb_define_hooked_variable
    add_function :global_id, :rb_global_entry, :var_getter, :var_setter
    <<-END
      function rb_define_hooked_variable(name, variable, getter, setter) {
        var id = global_id(name);
        var gvar = rb_global_entry(id).variable;
        gvar.data = variable;
        gvar.getter = getter ? getter : var_getter;
        gvar.setter = setter ? setter : var_setter;
      //gvar.marker = var_marker;
      }
    END
  end
  
  # verbatim
  def rb_define_variable
    add_function :rb_define_hooked_variable
    <<-END
      function rb_define_variable(name, vars) {
        rb_define_hooked_variable(name, vars, 0, 0);
      }
    END
  end
  
  # verbatim
  def rb_define_virtual_variable
    add_function :val_getter, :readonly_setter, :rb_define_hooked_variable
    <<-END
      function rb_define_virtual_variable(name, getter, setter) {
        if (!getter) { getter = val_getter; }
        if (!setter) { setter = readonly_setter; }
        rb_define_hooked_variable(name, 0, getter, setter);
      }
    END
  end
  
  # verbatim
  def rb_dvar_push
    add_function :new_dvar
    <<-END
      function rb_dvar_push(id, value) {
        ruby_dyna_vars = new_dvar(id, value, ruby_dyna_vars);
      }
    END
  end
  
  # verbatim
  def rb_global_entry
    add_function :undef_getter, :undef_setter, :st_lookup, :st_add_direct
    <<-END
      function rb_global_entry(id) {
        var entry;
        var tmp = st_lookup(rb_global_tbl, id, 0);
        if (tmp[0]) {
          entry = tmp[1];
        } else {
          var variable = {};
          entry = {};
          entry.id = id;
          entry.variable = variable;
          variable.counter = 1;
          variable.data = 0;
          variable.getter = undef_getter;
          variable.setter = undef_setter;
        //variable.marker = undef_marker;
          variable.block_trace = 0;
          variable.trace = 0;
          st_add_direct(rb_global_tbl, id, entry);
        }
        return entry;
      }
    END
  end
  
  # verbatim
  def rb_gvar_get
    <<-END
      function rb_gvar_get(entry) {
        var variable = entry.variable;
        return variable.getter(entry.id, variable.data, variable);
      }
    END
  end
  
  # verbatim
  def rb_gvar_set
    add_function :rb_raise, :rb_ensure
    <<-END
      function rb_gvar_set(entry, val) {
        var trace = {};
        var variable = entry.variable;
        if (ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "Insecure: can't change global variable value"); }
        variable = variable.setter(val, entry.id, variable.data, variable);
      //if (variable.trace && !variable.block_trace) {
      //  variable.block_trace = 1;
      //  trace.trace = variable.trace;
      //  trace.val = val;
      //  rb_ensure(trace_ev, trace, trace_en, variable);
      //}
        return val;
      }
    END
  end
  
  # verbatim
  def rb_iv_get
    add_functions :rb_ivar_get
    <<-END
      function rb_iv_get(obj, name) {
        return rb_ivar_get(obj, rb_intern(name));
      }
    END
  end
  
  # verbatim
  def rb_iv_set
    add_functions :rb_ivar_set
    <<-END
      function rb_iv_set(obj, name, val) {
        return rb_ivar_set(obj, rb_intern(name), val);
      }
    END
  end
  
  # verbatim
  def rb_ivar_defined
    add_function :st_lookup, :rb_special_const_p, :generic_ivar_defined
    <<-END
      function rb_ivar_defined(obj, id) {
        switch (TYPE(obj)) {
          case T_OBJECT:
          case T_CLASS:
          case T_MODULE:
            if (obj.iv_tbl && st_lookup(obj.iv_tbl, id, 0)[0]) { return Qtrue; }
            break;
          default:
            if (FL_TEST(obj, FL_EXIVAR) || rb_special_const_p(obj)) { return generic_ivar_defined(obj, id); }
            break;
        }
        return Qfalse;
      }
    END
  end
  
  # verbatim
  def rb_ivar_get
    add_functions :ivar_get
    <<-END
      function rb_ivar_get(obj, id) {
        return ivar_get(obj, id, Qtrue);
      }
    END
  end
  
  # verbatim
  def rb_ivar_set
    add_functions :rb_raise, :rb_error_frozen, :generic_ivar_set, :st_init_numtable, :st_insert
    <<-END
      function rb_ivar_set(obj, id, val) {
        if (!OBJ_TAINTED(obj) && ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "Insecure: can't modify instance variable"); }
        if (OBJ_FROZEN(obj)) { rb_error_frozen("object"); }
        switch (TYPE(obj)) {
          case T_OBJECT:
          case T_CLASS:
          case T_MODULE:
            if (!obj.iv_tbl) { obj.iv_tbl = st_init_numtable(); }
            st_insert(obj.iv_tbl, id, val);
            break;
          default:
            generic_ivar_set(obj, id, val);
            break;
        }
        return val;
      }
    END
  end
  
  # verbatim
  def rb_mod_const_missing
    add_function :uninitialized_constant, :rb_to_id
    <<-END
      function rb_mod_const_missing(klass, name) {
        ruby_frame = ruby_frame.prev; /* pop frame for 'const_missing' */
        uninitialized_constant(klass, rb_to_id(name));
        return Qnil; /* not reached */
      }
    END
  end
  
  def rb_mod_remove_const
    add_function :rb_to_id, :rb_is_const_id, :rb_id2name, :rb_raise,
                 :rb_error_frozen, :st_delete, :rb_const_defined_at,
                 :rb_name_error, :rb_class2name
    <<-END
      function rb_mod_remove_const(mod, name) {
        var id = rb_to_id(name);
        if (!rb_is_const_id(id)) { rb_name_error(id, "'%s' is not allowed as a constant name", rb_id2name(id)); }
        if (!OBJ_TAINTED(mod) && (ruby_safe_level >= 4)) { rb_raise(rb_eSecurityError, "Insecure: can't remove constant"); }
        if (OBJ_FROZEN(mod)) { rb_error_frozen("class/module"); }
        var tmp = st_delete(mod.iv_tbl);
        id = tmp[1];
        val = tmp[2];
        if (mod.iv_tbl && tmp[0]) {
          if (val == Qundef) { val = Qnil; }
          return val;
        }
        if (rb_const_defined_at(mod, id)) { rb_name_error(id, "cannot remove %s::%s", rb_class2name(mod), rb_id2name(id)); }
        rb_name_error(id, "constant %s::%s not defined", rb_class2name(mod), rb_id2name(id));
        return Qnil; /* not reached */
      }
    END
  end
  
  # verbatim
  def rb_name_class
    add_functions :rb_iv_set
    <<-END
      function rb_name_class(klass, id) {
        rb_iv_set(klass, '__classid__', ID2SYM(id));
      }
    END
  end
  
  # verbatim
  def rb_obj_classname
    add_functions :rb_class2name
    <<-END
      function rb_obj_classname(obj) {
        return rb_class2name(CLASS_OF(obj));
      }
    END
  end
  
  # changed string handling
  def rb_set_class_path
    add_functions :rb_str_new, :rb_class_path, :rb_ivar_set
    <<-END
      function rb_set_class_path(klass, under, name) {
        if (under == rb_cObject) {
          var str = rb_str_new(name);
        } else {
          var base_name = rb_class_path(under).ptr;
          var str = rb_str_new(base_name + "::" + name);
        }
        rb_ivar_set(klass, classpath, str);
      }
    END
  end
  
  # verbatim
  def readonly_setter
    add_function :rb_name_error, :rb_id2name
    <<-END
      function readonly_setter(val, id, variable) {
        rb_name_error(id, "%s is a read-only variable", rb_id2name(id));
      }
    END
  end
  
  # removed warning
  def undef_getter
    <<-END
      function undef_getter(id) {
        return Qnil;
      }
    END
  end
  
  # modified to return variable instead of using pointer
  def undef_setter
    add_function :val_getter, :val_setter
    <<-END
      function undef_setter(val, id, data, variable) {
        variable.getter = val_getter;
        variable.setter = val_setter;
      //variable.marker = val_marker;
        variable.data = val;
        return variable;
      }
    END
  end
  
  # verbatim
  def uninitialized_constant
    add_function :rb_name_error, :rb_class2name, :rb_id2name
    <<-END
      function uninitialized_constant(klass, id) {
        if (klass && (klass != rb_cObject)) {
          rb_name_error(id, "uninitialized constant %s::%s", rb_class2name(klass), rb_id2name(id));
        } else {
          rb_name_error(id, "uninitialized constant %s", rb_id2name(id));
        }
      }
    END
  end
  
  # verbatim
  def val_getter
    <<-END
      function val_getter(id, val) {
        return val;
      }
    END
  end
  
  # modified to return variable instead of using pointer
  def val_setter
    <<-END
      function val_setter(val, id, data, variable) {
        variable.data = val;
        return variable;
      }
    END
  end
  
  # verbatim
  def var_getter
    <<-END
      function var_getter(id, variable) {
        return variable || Qnil;
      }
    END
  end
  
  # modified to return variable instead of using pointer
  def var_setter
    <<-END
      function var_setter(val, id, variable) {
        return val;
      }
    END
  end
end
