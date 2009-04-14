class Red::MethodCompiler
  # verbatim
  def is_attrset_id
    add_function :is_notop_id
    <<-END
      function is_attrset_id(id) {
        return is_notop_id(id) && ((id & ID_SCOPE_MASK) == ID_ATTRSET);
      }
    END
  end
  
  # verbatim
  def is_class_id
    adD_function :is_notop_id
    <<-END
      function is_class_id(id) {
        return is_notop_id(id) && ((id & ID_SCOPE_MASK) == ID_CLASS);
      }
    END
  end
  
  # verbatim
  def is_const_id
    add_function :is_notop_id
    <<-END
      function is_const_id(id) {
        return is_notop_id(id) && ((id & ID_SCOPE_MASK) == ID_CONST);
      }
    END
  end
  
  # verbatim
  def is_global_id
    add_function :is_notop_id
    <<-END
      function is_global_id(id) {
        return is_notop_id(id) && ((id & ID_SCOPE_MASK) == ID_GLOBAL);
      }
    END
  end
  
  # removed SIGN_EXTEND_CHAR and ismbchar
  def is_identchar
    <<-END
      function is_identchar(c) {
        return ISALNUM(c) || (c == '_');
      }
    END
  end
  
  # verbatim
  def is_instance_id
    add_function :is_notop_id
    <<-END
      function is_instance_id(id) {
        return is_notop_id(id) && ((id & ID_SCOPE_MASK) == ID_INSTANCE);
      }
    END
  end
  
  # verbatim
  def is_junk_id
    add_function :is_notop_id
    <<-END
      function is_junk_id(id) {
        return is_notop_id(id) && ((id & ID_SCOPE_MASK) == ID_JUNK);
      }
    END
  end
  
  # verbatim
  def is_local_id
    add_function :is_notop_id
    <<-END
      function is_local_id(id) {
        return is_notop_id(id) && ((id & ID_SCOPE_MASK) == ID_LOCAL);
      }
    END
  end
  
  # verbatim
  def is_notop_id
    <<-END
      function is_notop_id(id) {
        return id > tLAST_TOKEN;
      }
    END
  end
  
  # removed handling of $~ and $_ 'global' variables
  def local_append
    <<-END
      function local_append(id) {
      //if (!lvtbl.tbl) { // was 'if (lvtbl->tbl === 0)'
      //  lvtbl.tbl = []; // was 'lvtbl->tbl = ALLOC_N(ID, 4)'
      //  lvtbl.tbl[0] = 0;
      //  lvtbl.tbl[1] = '_';
      //  lvtbl.tbl[2] = '~';
      //  lvtbl.cnt = 2;
      //  if (id == '_') { return 0; }
      //  if (id == '~') { return 1; }
      //}
      //// removed REALLOC_N else clause
      //lvtbl.tbl[lvtbl.cnt + 1] = id;
      //return lvtbl.cnt++;
        if (!lvtbl.tbl) {
          lvtbl.tbl = [];
          lvtbl.cnt = 0;
        }
        lvtbl.tbl[lvtbl.cnt] = id;
        return lvtbl.cnt++;
      }
    END
  end
  
  # removed offset of -1 from looping logic; 'cnt' now reflects actual index
  # CHECK: passing 0 as 'id' no longer returns 'lvtbl.cnt'; may need to replace this functionality
  def local_cnt
    add_function :local_append
    <<-END
      function local_cnt(id) {
      //if (id === 0) { return lvtbl.cnt; }
      //for (var cnt = 0, max = lvtbl.cnt; cnt < max; cnt++) {
      //  if (lvtbl.tbl[cnt] == id) { return cnt; }
      //}
        var index = (lvtbl.tbl || []).indexOf(id);
        if (index < 0) { return local_append(id); }
        return index;
      }
    END
  end
  
  # changed 'xfree' GC calls to 'delete'
  def local_pop
    <<-END
      function local_pop() {
        var local = lvtbl.prev;
        if (lvtbl.tbl) {
          if (!lvtbl.nofree) {
            delete lvtbl.tbl // was xfree(lvtbl->tbl)
          } else {
            lvtbl.tbl[0] = lvtbl.cnt;
          }
        }
        ruby_dyna_vars = lvtbl.dyna_vars;
        lvtbl = local;
      }
    END
  end
  
  # verbatim
  def local_push
    add_function :rb_dvar_push
    <<-END
      function local_push(top) {
        var local = {};
        local.prev = lvtbl;
        local.nofree = 0;
        local.cnt = 0;
        local.tbl = 0;
        local.dlev = 0;
        local.dyna_vars = ruby_dyna_vars;
        lvtbl = local;
        if (!top) {
          rb_dvar_push(0, ruby_dyna_vars);
          ruby_dyna_vars.next = 0;
        }
      }
    END
  end
  
  # verbatim
  def local_tbl
    <<-END
      function local_tbl() {
        lvtbl.nofree = 1;
        return lvtbl.tbl;
      }
    END
  end
  
  # CHECK
  def special_local_set
    add_function :top_local_init
    <<-END
      function special_local_set(c, val) {
        top_local_init();
        ruby_scope.local_vars[c] = val;
      }
    END
  end
  
  # CHECK
  def rb_backref_get
    add_function :rb_svar
    <<-END
      function rb_backref_get() {
        return ruby_scope.local_vars['~'] || Qnil;
      }
    END
  end
  
  # replaced 'rb_svar' with pointer to 'ruby_scope.local_vars'
  def rb_backref_set
    add_function :special_local_set
    <<-END
      function rb_backref_set(val) {
        if (rb_svar(1)) {
          ruby_scope.local_vars[1] = val;
        } else {
          special_local_set('~', val);
        }
      }
    END
  end
  
  # verbatim
  def rb_id_attrset
    <<-END
      function rb_id_attrset(id) {
        id &= ~ID_SCOPE_MASK;
        id |= ID_ATTRSET;
        return id;
      }
    END
  end
  
  # changed op_tbl loop, modified string buf handling
  def rb_id2name
    add_function :rb_id2name, :rb_intern, :is_local_id
    <<-END
      function rb_id2name(id) {
        var name;
        var data;
        var goto_again = 0;
        if (id < tLAST_TOKEN) {
          for (var s in op_tbl) { // modified
            if (op_tbl[s] == id) { return s; }
          }
        }
        if ((data = sym_rev_tbl[id])) { return data; } // was st_lookup
        if (is_attrset_id(id)) {
          var id2 = (id & ~ID_SCOPE_MASK) | ID_LOCAL;
          do { // was 'again:' goto label
            name = rb_id2name(id2);
            if (name) {
              var buf = name + '=';
              rb_intern(buf);
              return rb_id2name(id);
            }
            if ((goto_again = is_local_id(id2))) {
              id2 = (id & ~ID_SCOPE_MASK) | ID_CONST;
            }
          } while (goto_again);
        }
        return 0;
      }
    END
  end
  
  # CHECK
  def rb_intern
    add_function :rb_id_attrset, :is_attrset_id, :is_identchar#, :is_special_global_name
    <<-END
      function rb_intern(name) {
        var id;
        if ((id = sym_tbl[name])) { return id; } else { id = 0; }
          
        var last = name.length - 1;
        var m = 0;
        var skip_to_new_id = 0;
        var skip_to_id_regist = 0;
        
        switch (name[m]) {
          case '$':
            id |= ID_GLOBAL;
          //if (is_special_global_name(name[++m])) { skip_to_new_id = 1; }
            break;
          case '@':
            if (name[1] == '@') {
              m++;
              id |= ID_CLASS;
            } else {
              id |= ID_INSTANCE;
            }
            m++;
            break;
          default:
            if ((name[0] != '_') && ISASCII(name[0]) && !ISALNUM(name[0])) {
              var token;
              if ((token = op_tbl[name])) {
                id = token;
                skip_to_id_regist = 1;
                break;
              }
            }
            if (name[last] == '=') {
              id = rb_intern(name.slice(0,last));
              if (id > tLAST_TOKEN && !is_attrset_id(id)) {
                id = rb_id_attrset(id);
                skip_to_id_regist = 1;
                break;
              }
              id = ID_ATTRSET;
            } else if (ISUPPER(name[0])) {
              id = ID_CONST;
            } else {
              id = ID_LOCAL;
            }
        }
        
        if (!skip_to_id_regist) {
          if (!skip_to_new_id) {
            /* multibyte support not implemented */
            if (!ISDIGIT(name[m])) {
              while (m <= last && is_identchar(name[m])) { m++; }
            }
            if (name[m]) { id = ID_JUNK; }
          }
          id |= ++last_id << ID_SCOPE_SHIFT;
        }
        sym_tbl[name]   = id;
        sym_rev_tbl[id] = name;
        return id;
      }
    END
  end
  
  # verbatim
  def rb_is_const_id
    add_function :is_const_id
    <<-END
      function rb_is_const_id(id) {
        return is_const_id(id) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def rb_is_instance_id
    add_function :is_instance_id
    <<-END
      function rb_is_instance_id(id) {
        return is_instance_id(id) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def rb_is_local_id
    add_function :is_local_id
    <<-END
      function rb_is_local_id(id) {
        return is_local_id(id) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def rb_lastline_get
    add_function :rb_svar
    <<-END
      function rb_lastline_get() {
        var variable = rb_svar(0);
        if (variable) { return variable; }
        return Qnil;
      }
    END
  end
  
  # changed st_lookup
  def rb_sym_interned_p
    <<-END
      function rb_sym_interned_p(str) {
        if (sym_tbl[str.ptr]) { return Qtrue; } // was st_lookup
        return Qfalse;
      }
    END
  end
  
  # verbatim
  def top_local_init
    add_function :local_push
    <<-END
      function top_local_init() {
        local_push(1);
        lvtbl.cnt = ruby_scope.local_tbl ? ruby_scope.local_tbl[0] : 0;
        if (lvtbl.cnt > 0) {
          lvtbl.tbl = []; // was 'lvtbl->tbl = ALLOC_N(ID, lvtbl->cnt+3)'
          MEMCPY(lvtbl.tbl, ruby_scope.local_tbl, lvtbl.cnt + 1);
        } else {
          lvtbl.tbl = 0;
        }
        lvtbl.dlev = (ruby_dyna_vars) ? 1 : 0;
      }
    END
  end
  
  # CHECK; possibly unnecessary - seems to deal with reallocating 'local_tbl' in order to make room for special locals in the memory location directly preceding
  def top_local_setup
    add_function :rb_mem_clear
    <<-END
      function top_local_setup() {
        var len = lvtbl.cnt;
        if (len > 0) {
          var i = ruby_scope.local_tbl ? ruby_scope.local_tbl[0] : 0;
          if (i < len) {
            if ((i === 0) || ((ruby_scope.flags & SCOPE_MALLOC) === 0)) {
              var vars = [];
              if (ruby_scope.local_vars) {
                vars[-1] = ruby_scope.local_vars[-1];
                MEMCPY(vars, ruby_scope.local_vars, i);
                rb_mem_clear(vars, len - i, i);
              } else {
                vars[-1] = 0;
                rb_mem_clear(vars, len);
              }
              ruby_scope.local_vars = vars;
              ruby_scope.flags |= SCOPE_MALLOC;
            } else {
            //VALUE *vars = ruby_scope->local_vars-1;
              var vars = ruby_scope.local_vars[-1];
            //REALLOC_N(vars, VALUE, len+1);
              rb_mem_clear(ruby_scope.local_vars, len - i, i);
            }
            if (ruby_scope.local_tbl && (ruby_scope.local_vars[-1] === 0)) {
              if (!(ruby_scope.flags & SCOPE_CLONE)) { delete(ruby_scope.local_tbl); }
            }
            ruby_scope.local_vars[-1] = 0; /* no reference needed */
            ruby_scope.local_tbl = local_tbl();
          }
        }
        local_pop();
      }
    END
  end
end
