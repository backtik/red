class Red::MethodCompiler
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
          var classid = rb_intern("__classid__");
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
              var arg;
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
  def rb_ivar_set
    add_functions :rb_raise, :rb_error_frozen, :generic_ivar_set, :st_init_numtable, :st_insert
    <<-END
      function rb_ivar_set(obj, id, val) {
        if (!OBJ_TAINTED(obj) && rb_safe_level() >= 4) { rb_raise(rb_eSecurityError, "Insecure: can't modify instance variable"); }
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
end
