class Red::MethodCompiler
  # left some node types unimplemented
  def assign
    add_function :dvar_asgn, :dvar_asgn_curr, :massign, :svalue_to_mrhs
    <<-END
      function assign(self, lhs, val, pcall) {
        ruby_current_node = lhs;
        if (val == Qundef) { val = Qnil; } // removed warning
        switch (nd_type(lhs)) {
          case NODE_DASGN:
            dvar_asgn(lhs.nd_vid, val);
            break;
          case NODE_DASGN_CURR:
            dvar_asgn_curr(lhs.nd_vid, val);
            break;
          case NODE_LASGN:
            // removed bug warning
            ruby_scope.local_vars[lhs.nd_cnt] = val;
            break;
          case NODE_MASGN:
            massign(self, lhs, svalue_to_mrhs(val, lhs.nd_head), pcall);
            break;
          default:
            console.log('unimplemented node type in rb_assign: 0x%s', nd_type(lhs).toString(16));
        }
      }
    END
  end
  
  # verbatim
  def avalue_to_svalue
    add_function :rb_check_array_type
    <<-END
      function avalue_to_svalue(v) {
        var top;
        var tmp = rb_check_array_type(v);
        if (NIL_P(tmp)) { return v; }
        if (tmp.ptr.length === 0) { return Qundef; }
        if (tmp.ptr.length == 1) {
          top = rb_check_array_type(tmp.ptr[0]);
          if (NIL_P(top)) { return tmp.ptr[0]; }
          if (top.ptr.length > 1) { return v; }
          return top;
        }
        return tmp;
      }
    END
  end
  
  # changed rb_str_new2 to rb_str_new, modified to use jsprintf instead of snprintf
  def backtrace
    add_function :ruby_set_current_source, :rb_id2name,
                 :rb_ary_push, :rb_str_new
    <<-END
      function backtrace(lev) {
        var frame = ruby_frame;
        var buf;
        var n;
        var ary = rb_ary_new();
        if (frame.last_func == ID_ALLOCATOR) { frame = frame.prev; }
        if (lev < 0) {
          ruby_set_current_source();
          if (frame.last_func) {
            buf = jsprintf("%s:%d:in '%s'", [ruby_sourcefile, ruby_sourceline, rb_id2name(frame.last_func)]);
          } else if (ruby_sourceline === 0) {
            buf = jsprintf("%s", [ruby_sourcefile]);
          } else {
            buf = jsprintf("%s:%d", [ruby_sourcefile, ruby_sourceline]);
          }
          rb_ary_push(ary, rb_str_new(buf));
          if (lev < -1) { return ary; }
        } else {
          while (lev-- > 0) {
            frame = frame.prev;
            if (!frame) {
              ary = Qnil;
              break;
            }
          }
        }
        for (; frame && (n = frame.node); frame = frame.prev) {
          if (frame.prev && frame.prev.last_func) {
            if (frame.prev.node == n) {
              if (frame.prev.last_func == frame.last_func) { continue; }
            }
            buf = jsprintf("%s:%d:in %s", [n.nd_file, nd_line(n), rb_id2name(frame.prev.last_func)]);
          } else {
            jsprintf("%s:%d", [n.nd_file, nd_line(n)]);
          }
          rb_ary_push(ary, rb_str_new(buf));
        }
        return ary;
      }
    END
  end
  
  # CHECK ON THIS
  def blk_copy_prev
    add_function :scope_dup, :frame_dup
    <<-END
      function blk_copy_prev(block) {
        var tmp;
        var vars;
        while (block.prev) {
          tmp = []; // was 'ALLOC_N(struct BLOCK, 1)'
          console.log('check blk_copy_prev');
          MEMCPY(tmp, block.prev, 1); // SHOULD THIS BE '[block.prev]' OR IS block.prev ALREADY AN ARRAY
          scope_dup(tmp.scope);
          frame_dup(tmp.frame);
          for (vars = tmp.dyna_vars; vars; vars = vars.next) {
            if (FL_TEST(vars, DVAR_DONT_RECYCLE)) { break; }
            FL_SET(vars, DVAR_DONT_RECYCLE);
          }
          block.prev = tmp;
          block = tmp;
        }
      }
    END
  end
  
  # CHECK
  def blk_dup
    add_function :frame_dup, :blk_copy_prev
    <<-END
      function blk_dup(dup, orig) {
        MEMCPY(dup, orig, 1);
        frame_dup(dup.frame);
        if (dup.iter) {
          blk_copy_prev(dup);
        } else {
          dup.prev = 0;
        }
      }
    END
  end
  
  # empty placeholder to identify Data structs as procs
  def blk_mark
    <<-END
      function blk_mark() {};
    END
  end
  
  # verbatim
  def block_orphan
    <<-END
      function block_orphan(data) {
        // removed thread check
        return (data.scope.flags & SCOPE_NOSTACK) ? 1 : 0;
      }
    END
  end
  
  # CHECK
  def block_pass
    add_function :rb_eval, :rb_obj_is_proc, :rb_check_convert_type, :rb_obj_classname,
                 :rb_raise, :proc_get_safe_level, :proc_set_safe_level, :proc_jump_error,
                 :block_orphan
    add_method :to_proc
    <<-END
      function block_pass(self, node) {
        var proc = rb_eval(self, node.nd_body);
        var data;
        var result = Qnil;
        var safe = ruby_safe_level;
        var state = 0;
        
        if (NIL_P(proc)) {
          PUSH_ITER(ITER_NOT);
          result = rb_eval(self, node.nd_iter);
          POP_ITER();
          return result;
        }
        if (!rb_obj_is_proc(proc)) {
          var b = rb_check_convert_type(proc, T_DATA, 'Proc', 'to_proc');
          if (!rb_obj_is_proc(b)) { rb_raise(rb_eTypeError, "wrong argument type %s (expected Proc)", rb_obj_classname(proc)); }
          proc = b;
        }
        if (ruby_safe_level >= 1 && OBJ_TAINTED(proc) && ruby_safe_level > proc_get_safe_level(proc)) { rb_raise(rb_eSecurityError, "Insecure: tainted block value"); }
        if (ruby_block && ruby_block.block_obj == proc) {
          PUSH_ITER(ITER_PAS);
          result = rb_eval(self, node.nd_iter);
          POP_ITER();
          return result;
        }
        
      //Data_Get_Struct(proc, data);
        var data = proc.data;
        var orphan = block_orphan(data);
        
        var old_block = ruby_block;
        var _block = data;
        _block.outer = ruby_block;
        if (orphan) { _block.uniq = block_unique++; }
        ruby_block = _block;
        PUSH_ITER(ITER_PRE);
        if (ruby_frame.iter == ITER_NOT) { ruby_frame.iter = ITER_PRE; }
          
        PUSH_TAG(PROT_LOOP);
        do {
          var goto_retry = 0;
          try {
            proc_set_safe_level(proc);
            if (safe > ruby_safe_level) { ruby_safe_level = safe; }
            result = rb_eval(self, node.nd_iter);
          } catch (x) {
            if (typeof(state = x) != 'number') { throw(state); }
            if (state == TAG_BREAK && TAG_DEST()) {
              result = prot_tag.retval;
              state = 0;
            } else if (state == TAG_RETRY) {
              state = 0;
              goto_retry = 1;
            }
          }
        } while (goto_retry);
        POP_TAG();
        POP_ITER();
        ruby_block = old_block;
        ruby_safe_level = safe;
        
        switch (state) { /* escape from orphan block */
          case 0:
            break;
          case TAG_RETURN:
            if (orphan) { proc_jump_error(state, prot_tag.retval); }
            break;
          default:
            JUMP_TAG(state);
        }
        
        return result;
      }
    END
  end
  
  # verbatim
  def break_jump
    add_function :localjump_error
    <<-END
      function break_jump(retval) {
        var tt = prot_tag;
        if (retval == Qundef) { retval = Qnil; }
        while (tt) {
          switch (tt.tag) {
            case PROT_THREAD:
            case PROT_YIELD:
            case PROT_LOOP:
            case PROT_LAMBDA:
              tt.dst = tt.frame.uniq;
              tt.retval = retval;
              JUMP_TAG(TAG_BREAK);
              break;
            case PROT_FUNC:
              tt = 0;
              continue;
            default:
              break;
          }
          tt = tt.prev;
        }
        localjump_error("unexpected break", retval, TAG_BREAK);
      }
    END
  end
  
  # verbatim
  def call_cfunc
    add_function :rb_raise, :rb_ary_new4
    <<-END
      function call_cfunc(func, recv, len, argc, argv) {
        if (len >= 0 && argc != len) { rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)", argc, len); }
        switch (len) {
          case -2:
            return func(recv, rb_ary_new4(argc, argv));
          case -1:
            return func(argc, argv, recv);
          case 0:  return func(recv);
          case 1:  return func(recv, argv[0]);
          case 2:  return func(recv, argv[0], argv[1]);
          case 3:  return func(recv, argv[0], argv[1], argv[2]);
          case 4:  return func(recv, argv[0], argv[1], argv[2], argv[3]);
          case 5:  return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4]);
          case 6:  return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
          case 7:  return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6]);
          case 8:  return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7]);
          case 9:  return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8]);
          case 10: return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9]);
          case 11: return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9], argv[10]);
          case 12: return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9], argv[10], argv[11]);
          case 13: return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9], argv[10], argv[11], argv[12]);
          case 14: return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9], argv[10], argv[11], argv[12], argv[13]);
          case 15: return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9], argv[10], argv[11], argv[12], argv[13], argv[14]);
          default:
            rb_raise(rb_eArgError, "too many arguments (%d)", len);
            break;
        }
        return Qnil;
      }
    END
  end
  
  # removed ruby_wrapper branch
  def class_prefix
    add_function :rb_raise, :rb_obj_as_string
    <<-END
      function class_prefix(self, cpath) {
        // removed bug warning
        if (cpath.nd_head) {
          var c = rb_eval(self, cpath.nd_head);
          switch (TYPE(c)) {
            case T_CLASS:
            case T_MODULE:
              break;
            default:
              rb_raise(rb_eTypeError, "%s is not a class/module", rb_obj_as_string(c).ptr);
          }
          return c;
        } else if (nd_type(cpath) == NODE_COLON2) {
          return ruby_cbase;
        } else { // removed ruby_wrapper branch
          return rb_cObject;
        }
      }
    END
  end
  
  # verbatim
  def dvar_asgn
    add_function :dvar_asgn_internal
    <<-END
      function dvar_asgn(id, value) {
        dvar_asgn_internal(id, value, 0);
      }
    END
  end
  
  # verbatim
  def dvar_asgn_curr
    add_function :dvar_asgn_internal
    <<-END
      function dvar_asgn_curr(id, value) {
        dvar_asgn_internal(id, value, 1);
      }
    END
  end
  
  # verbatim
  def dvar_asgn_internal
    add_function :new_dvar
    <<-END
      function dvar_asgn_internal(id, value, curr) {
        var n = 0;
        var vars = ruby_dyna_vars;
        while (vars) {
          if (curr && (vars.id === 0)) {
            /* first null is a dvar header */
            n++;
            if (n == 2) { break; }
          }
          if (vars.id == id) {
            vars.val = value;
            return;
          }
          vars = vars.next;
        }
        if (!ruby_dyna_vars) {
          ruby_dyna_vars = new_dvar(id, value, 0);
        } else {
          vars = new_dvar(id, value, ruby_dyna_vars.next);
          ruby_dyna_vars.next = vars;
        }
      }
    END
  end
  
  # verbatim
  def errat_getter
    add_function :get_backtrace
    <<-END
      function errat_getter(id) {
        return get_backtrace(ruby_errinfo);
      }
    END
  end
  
  # modified to return variable instead of using pointer
  def errat_setter
    add_function :rb_raise, :set_backtrace
    <<-END
      function errat_setter(val, id, variable) {
        if (NIL_P(ruby_errinfo)) { rb_raise(rb_eArgError, "$! not set"); }
        set_backtrace(ruby_errinfo, val);
        return val;
      }
    END
  end
  
  # modified to return variable instead of using pointer
  def errinfo_setter
    add_function :rb_obj_is_kind_of, :rb_raise
    <<-END
      function errinfo_setter(val, id, variable) {
        if (!NIL_P(val) && !rb_obj_is_kind_of(val, rb_eException)) { rb_raise(rb_eTypeError, "assigning non-exception to $!"); }
        return val;
      }
    END
  end
  
  # verbatim
  def error_pos
    add_function :ruby_set_current_source, :warn_printf, :rb_id2name
    <<-END
      function error_pos() {
        ruby_set_current_source();
        if (ruby_sourcefile) {
          if (ruby_frame.last_func) {
            warn_printf("%s:%d:in '%s'", ruby_sourcefile, ruby_sourceline, rb_id2name(ruby_frame.orig_func));
          } else if (ruby_sourceline === 0) {
            warn_printf("%s", ruby_sourcefile);
          } else {
            warn_printf("%s:%d", ruby_sourcefile, ruby_sourceline);
          }
        }
      }
    END
  end
  
  # added console.log command here, as in io_puts
  def error_print
    add_function :get_backtrace, :ruby_set_current_source, :warn_printf,
                 :error_pos, :rb_write_error, :rb_intern, :rb_class_name,
                 :rb_funcall, :rb_intern
    add_method :message
    <<-END
      function error_print() {
        var errat = Qnil;
        var eclass;
        var e;
        var elen;
        var einfo = '';
        if (NIL_P(ruby_errinfo)) { return; }
        PUSH_TAG(PROT_NONE);
        try { // was EXEC_TAG
          errat = get_backtrace(ruby_errinfo);
        } catch (x) {
          if (typeof(state = x) != 'number') { throw(state); }
          errat = Qnil;
        }
        try { // was EXEC_TAG
          if (NIL_P(errat)) {
            ruby_set_current_source();
            if (ruby_sourcefile) {
              warn_printf("%s:%d", ruby_sourcefile, ruby_sourceline);
            } else {
              warn_printf("%d", ruby_sourceline);
            }
          } else if (errat.ptr.length === 0) {
            error_pos();
          } else {
            var mesg = errat.ptr[0];
            if (NIL_P(mesg)) {
              error_pos();
            } else {
              var mesg = rb_write_error(mesg.ptr);
            }
          }
          eclass = CLASS_OF(ruby_errinfo);
        } catch (x) { // was 'goto error'
          if (typeof(state = x) != 'number') { throw(state); }
          prot_tag = _tag.prev; 
          return; // exits TAG_MACRO wrapper function
        }
        try { // was EXEC_TAG
          e = rb_funcall(ruby_errinfo, rb_intern('message'), 0, 0);
        //StringValue(e);
          if (e.data) { e = name_err_mesg_to_str(e); } // this line is a hack
          einfo = e.ptr;
          elen = einfo.length;
        } catch (x) {
          if (typeof(state = x) != 'number') { throw(state); }
          einfo = '';
          elen = 0;
        }
        try { // was EXEC_TAG
          if ((eclass == rb_eRuntimeError) && (elen === 0)) {
            rb_write_error(": unhandled exception\\n");
          } else {
            var epath = rb_class_name(eclass);
            if (elen === 0) {
              rb_write_error(": " + epath.ptr + "\\n");
            } else {
              var tail = 0;
              var len = elen;
              if (epath.ptr[0] == '#') { epath = 0; }
              if ((tail = einfo.indexOf('\\n')) !== 0) {
                len = tail - einfo;
                tail++ /* skip newline */
              }
              rb_write_error(": " + einfo);
              if (epath) { rb_write_error(" (" + epath.ptr + ")\\n"); }
              if (tail && (elen > len + 1)) {
                rb_write_error(tail);
                if (einfo[elen - 1] != '\\n') { rb_write_error("\\n"); }
              }
            }
          }
          if (!NIL_P(errat)) {
            var ep = errat;
            var truncate = (eclass == rb_eSysStackError);
            for (var i = 1, p = ep.ptr, l = ep.ptr.length; i < l; ++i) {
              if (TYPE(p[i]) == T_STRING) { warn_printf(" \\t \\tfrom %s\\n", p[i].ptr); }
              if (truncate && (i == 8) && (l > 18)) {
                warn_printf(" \\t \\t ... %d levels ...\\n", l - 13);
                i = l - 5;
              }
            }
          }
        } catch (x) { // was 'goto error'
          if (typeof(state = x) != 'number') { throw(state); }
        }
        POP_TAG();
        console.log(CONSOLE_LOG_BUFFER); // added
        CONSOLE_LOG_BUFFER = ''; // added
      }
    END
  end
  
  # removed 'autoload' call
  def ev_const_get
    add_function :rb_const_get, :st_lookup
    <<-END
      function ev_const_get(cref, id, self) {
        var cbase = cref;
        var result;
        while (cbase && cbase.nd_next) {
          var klass = cbase.nd_clss;
          if (!NIL_P(klass)) {
            while (klass.iv_tbl && (result = st_lookup(klass.iv_tbl, id))[0]) {
              if (result[1] == Qundef) { continue; } // removed 'autoload' call
              return result[1];
            }
          }
          cbase = cbase.nd_next;
        }
        return rb_const_get(NIL_P(cref.nd_clss) ? CLASS_OF(self) : cref.nd_clss, id);
      }
    END
  end
  
  # verbatim
  def exec_under
    <<-END
      function exec_under(func, under, cbase, args) {
        var val = Qnil; /* OK */
        var state = 0;
        var mode;
        var f = ruby_frame;
        PUSH_CLASS(under);
        PUSH_FRAME();
        ruby_frame.self = f.self;
        ruby_frame.last_func = f.last_func;
        ruby_frame.orig_func = f.orig_func;
        ruby_frame.last_class = f.last_class;
        ruby_frame.argc = f.argc;
        if (cbase) { PUSH_CREF(cbase); }
        mode = scope_vmode;
        SCOPE_SET(SCOPE_PUBLIC);
        PUSH_TAG(PROT_NONE);
        try { // was EXEC_TAG
          val = func(args);
        } catch (x) {
          if (typeof(state = x) != 'number') { throw(state); }
        }
        POP_TAG();
        if (cbase) { POP_CREF(); }
        SCOPE_SET(mode);
        POP_FRAME();
        POP_CLASS();
        if (state) { JUMP_TAG(state); }
        return val;
      }
    END
  end
  
  # FIND OUT WHY THE TOP FRAME ENDS UP WITH A PREV
  def frame_dup
    <<-END
      function frame_dup(frame) {
        for (;;) {
          frame.tmp = 0;
          if (!frame.prev || frame.this_is_the_top_frame) { break; }
          var tmp = frame.prev;
          frame.prev = tmp;
          frame = tmp;
        }
      }
    END
  end
  
  # CHECK
  def get_backtrace
    add_function :rb_funcall, :rb_check_backtrace
    add_method :backtrace
    <<-END
      function get_backtrace(info) {
        if (NIL_P(info)) { return Qnil; }
        info = rb_funcall(info, bt, 0);
        if (NIL_P(info)) { return Qnil; }
        return rb_check_backtrace(info);
      }
    END
  end
  
  # modified looping through array of exception types
  def handle_rescue
    add_function :rb_obj_is_kind_of, :rb_raise, :rb_funcall
    add_method :===
    <<-END
      function handle_rescue(self, node) {
        var argc;
        var argv;
      //TMP_PROTECT;
        if (!node.nd_args) { return rb_obj_is_kind_of(ruby_errinfo, rb_eStandardError); }
        BEGIN_CALLARGS;
        SETUP_ARGS(node.nd_args);
        END_CALLARGS;
        while (argc--) {
          if (!rb_obj_is_kind_of(argv[argc], rb_cModule)) { rb_raise(rb_eTypeError, "class or module required for rescue clause"); }
          if (RTEST(rb_funcall(argv[argc], eqq, 1, ruby_errinfo))) { return 1; }
        }
        return 0;
      }
    END
  end
  
  # unsupported
  def is_defined
    add_function :rb_raise
    <<-END
      function is_defined() {
        rb_raise(rb_eRuntimeError, "Red doesn't support 'defined?'");
      }
    END
  end
  
  # verbatim
  def iterate_method
    add_function :rb_funcall2
    <<-END
      function iterate_method(arg) {
        return rb_funcall2(arg.obj, arg.mid, arg.argc, arg.argv);
      }
    END
  end
  
  # verbatim
  def jump_tag_but_local_jump
    add_function :localjump_error
    <<-END
      function jump_tag_but_local_jump(state, val) {
        if (val == Qundef) { val = prot_tag.retval; }
        switch (state) {
          case 0:
            break;
          case TAG_RETURN:
            localjump_error("unexpected return", val, state);
            break;
          case TAG_BREAK:
            localjump_error("unexpected break", val, state);
            break;
          case TAG_NEXT:
            localjump_error("unexpected next", val, state);
            break;
          case TAG_REDO:
            localjump_error("unexpected redo", Qnil, state);
            break;
          case TAG_RETRY:
            localjump_error("retry outside of rescue clause", Qnil, state);
            break;
        }
        JUMP_TAG(state);
      }
    END
  end
  
  # changed rb_exc_new2 to rb_exc_new
  def localjump_error
    add_function :rb_exc_new, :rb_iv_set, :rb_exc_raise, :rb_intern
    <<-END
      function localjump_error(mesg, value, reason) {
        var exc = rb_exc_new(rb_eLocalJumpError, mesg); // was rb_exc_new2
        var id;
        rb_iv_set(exc, '@exit_value', value);
        switch (reason) {
          case TAG_BREAK:
            id = rb_intern('break');
            break;
          case TAG_REDO:
            id = rb_intern('redo');
            break;
          case TAG_RETRY:
            id = rb_intern('retry');
            break;
          case TAG_NEXT:
            id = rb_intern('next');
            break;
          case TAG_RETURN:
            id = rb_intern('return');
            break;
          default:
            id = rb_intern('noreason');
            break;
        }
        rb_iv_set(exc, '@reason', ID2SYM(id));
        rb_exc_raise(exc);
      }
    END
  end
  
  # verbatim
  def make_backtrace
    add_function :backtrace
    <<-END
      function make_backtrace() {
        return backtrace(-1);
      }
    END
  end
  
  # verbatim
  def massign
    add_function :assign, :rb_raise, :rb_ary_new4
    <<-END
      function massign(self, node, val, pcall) {
        var len = val.ptr.length;
        var list = node.nd_head;
        for (var i = 0, p = val.ptr; list && (i < len); i++) {
          assign(self, list.nd_head, p[i], pcall);
          list = list.nd_next;
        }
        if (pcall && list) {
          while (list) { i++; list = list.nd_next; }
          rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)", len, i);
        }
        if (node.nd_args) {
          if (node.nd_args == -1) {
            /* no check for mere `*' */
          } else if (!list && (i < len)) {
            assign(self, node.nd_args, rb_ary_new4(len - i, p.slice(i)), pcall);
          } else {
            assign(self, node.nd_args, rb_ary_new(), pcall);
          }
        } else if (pcall && (i < len)) {
          while (list) { i++; list = list.nd_next; }
          rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)", len, i);
        }
        while (list) {
          i++;
          assign(self, list.nd_head, Qnil, pcall);
          list = list.nd_next;
        }
        return val;
      }
    END
  end
  
  # hacked MEMCPY with offset
  def method_missing(x = nil)
    raise NoMethodError if x
    add_function :rb_method_missing, :rb_raise, :splat_value, :rb_funcall2
    add_method :method_missing
    <<-END
      function method_missing(obj, id, argc, argv, call_status) {
        var nargv;
        last_call_status = call_status;
        if (id == missing) {
          PUSH_FRAME();
          rb_method_missing(argc, argv, obj);
          POP_FRAME();
        } else if (id == ID_ALLOCATOR) {
          rb_raise(rb_eTypeError, "allocator undefined for %s", rb_class2name(obj));
        }
        if (argc < 0) {
          var tmp;
          argc = -argc - 1;
          tmp = splat_value(argv[argc]);
          nargv = []; // was 'nargv = ALLOCA_N(VALUE, argc + RARRAY(tmp)->len + 1)'
          MEMCPY(nargv, argv, argc, 1);
          MEMCPY(nargv, tmp.ptr, tmp.ptr.length, 1 + argc);
          argc += tmp.ptr.length;
        } else {
          nargv = []; // was 'nargv = ALLOCA_N(VALUE, argc+1)'
          MEMCPY(nargv, argv, argc, 1); // is it +1 or -1 offset?
        }
        nargv[0] = ID2SYM(id);
        return rb_funcall2(obj, missing, argc + 1, nargv);
      }
    END
  end
  
  # changed local vars handling, removed event hooks
  def module_setup
    add_function :rb_eval
    <<-END
      function module_setup(module, n) {
        var node = n.nd_body;
        var state = 0;
        var result = Qnil;
      //TMP_PROTECT;
        var frame = ruby_frame;
        frame.tmp = ruby_frame;
        ruby_frame = frame;
        PUSH_CLASS(module);
        PUSH_SCOPE();
        PUSH_VARS();
        if (node.nd_tbl) {
          var vars = []; // was VALUE *vars = TMP_ALLOC(node->nd_tbl[0]+1)
          vars.zero = node; // was *vars++ = (VALUE)node
          ruby_scope.local_vars = vars;
        //rb_mem_clear(ruby_scope->local_vars, node->nd_tbl[0]);
          ruby_scope.local_tbl = node.nd_tbl;
        } else {
          ruby_scope.local_vars = 0;
          ruby_scope.local_tbl = 0;
        }
        PUSH_CREF(module);
        PUSH_TAG(PROT_NONE);
        try { // was EXEC_TAG
          result = rb_eval(ruby_cbase, node.nd_next);
        } catch (x) {
          if (typeof(state = x) != 'number') { throw(state); }
        }
        POP_TAG();
        POP_CREF();
        POP_VARS();
        POP_SCOPE();
        POP_CLASS();
        ruby_frame = frame.tmp;
      //removed event hook handler
        if (state) { JUMP_TAG(state); }
        return result;
      }
    END
  end
  
  # verbatim
  def new_dvar
    <<-END
      function new_dvar(id, value, prev) {
        NEWOBJ(vars);
        OBJSETUP(vars, 0, T_VARMAP);
        vars.id = id;
        vars.val = value;
        vars.next = prev;
        return vars;
      }
    END
  end
  
  # verbatim
  def next_jump
    add_function :local_jump_error
    <<-END
      function next_jump(retval) {
        var tt = prot_tag;
        if (retval == Qundef) { retval = Qnil; }
        while (tt) {
          switch (tt.tag) {
            case PROT_THREAD:
            case PROT_YIELD:
            case PROT_LOOP:
            case PROT_LAMBDA:
            case PROT_FUNC:
              tt.dst = tt.frame.uniq;
              tt.retval = retval;
              JUMP_TAG(TAG_NEXT);
              break;
            default:
              break;
          }
          tt = tt.prev;
        }
        localjump_error("unexpected next", retval, TAG_NEXT);
      }
    END
  end
  
  # verbatim
  def print_undef
    add_function :rb_name_error, :rb_id2name, :rb_class2name
    <<-END
      function print_undef(klass, id) {
        rb_name_error(id, "undefined method '%s' for %s '%s'", rb_id2name(id), (TYPE(klass) == T_MODULE) ? "module" : "class", rb_class2name(klass));
      }
    END
  end
  
  # verbatim
  def proc_jump_error
    add_function :localjump_error
    <<-END
      function proc_jump_error(state, result) {
        var statement;
        switch (state) {
          case TAG_BREAK:
            statement = "break"; break;
          case TAG_RETURN:
            statement = "return"; break;
          case TAG_RETRY:
            statement = "retry"; break;
          default:
            statement = "local-jump"; break; /* should not happen */
        }
        var mesg = jsprintf("%s from proc-closure", [statement]);
        localjump_error(mesg, result, state);
      }
    END
  end
  
  # verbatim
  def rb_add_method
    add_function :rb_raise, :rb_intern, :rb_error_frozen, :rb_clear_cache_by_id, :rb_funcall, :rb_iv_get, :st_insert
    add_method :singleton_method_added, :method_added
    <<-END
      function rb_add_method(klass, mid, node, noex) {
        var body;
        if (NIL_P(klass)) { klass = rb_cObject; }
        if (ruby_safe_level >= 4 && (klass == rb_cObject || !OBJ_TAINTED(klass))) { rb_raise(rb_eSecurityError, "Insecure: can't define method"); }
        if (!FL_TEST(klass, FL_SINGLETON) && node && (nd_type(node) != NODE_ZSUPER) && (mid == rb_intern('initialize') || mid == rb_intern('initialize_copy'))) {
          noex = NOEX_PRIVATE | noex;
        } else if (FL_TEST(klass, FL_SINGLETON) && node && (nd_type(node) == NODE_CFUNC) && (mid == rb_intern('allocate'))) {
          // removed warning about defining 'allocate'
          mid = ID_ALLOCATOR;
        }
        if (OBJ_FROZEN(klass)) { rb_error_frozen("class/module"); }
        rb_clear_cache_by_id(mid);
        body = NEW_METHOD(node, NOEX_WITH_SAFE(noex));
        st_insert(klass.m_tbl, mid, body);
        if (node && (mid != ID_ALLOCATOR) && ruby_running) {
          if (FL_TEST(klass, FL_SINGLETON)) {
            rb_funcall(rb_iv_get(klass, '__attached__'), singleton_added, 1, ID2SYM(mid));
          } else {
            rb_funcall(klass, added, 1, ID2SYM(mid));
          }
        }
      }
    END
  end
  
  # expanded search_method
  def rb_alias
    add_function :rb_frozen_class_p, :search_method, :print_undef, :rb_iv_get, :rb_clear_cache_by_id, :rb_funcall, :st_insert
    add_method :singleton_method_added, :method_added
    <<-END
      function rb_alias(klass, name, def) {
        var origin;
        var orig;
        var body;
        var node;
        var singleton = 0;
        rb_frozen_class_p(klass);
        if (name == def) { return; }
        if (klass == rb_cObject) { rb_secure(4); }
        var tmp = search_method(klass, def); // expanded
        orig = tmp[0];
        origin = tmp[1]; // ^^
        if (!orig || !orig.nd_body) {
          if (TYPE(klass) == T_MODULE) {
            tmp = search_method(rb_cObject, def); // expanded
            orig = tmp[0];
            origin = tmp[1]; // ^^
          }
        }
        if (!orig || !orig.nd_body) { print_undef(klass, def); }
        if (FL_TEST(klass, FL_SINGLETON)) { singleton = rb_iv_get(klass, '__attached__'); }
        body = orig.nd_body;
        orig.u3++; // was orig->nd_cnt++
        if (nd_type(body) == NODE_FBODY) { /* was alias */
          def = body.nd_mid;
          origin = body.nd_orig;
          body = body.nd_head;
        }
        rb_clear_cache_by_id(name);
        // removed warning
        st_insert(klass.m_tbl, name, NEW_METHOD(NEW_FBODY(body, def, origin), NOEX_WITH_SAFE(orig.nd_noex)));
        if (!ruby_running) { return; }
        if (singleton) {
          rb_funcall(singleton, singleton_added, 1, ID2SYM(name));
        } else {
          rb_funcall(klass, added, 1, ID2SYM(name));
        }
      }
    END
  end
  
  # changed_string_handling
  def rb_attr
    add_function :rb_is_local_id, :rb_is_const_id, :rb_name_error, :rb_id2name, :rb_raise, :rb_intern, :rb_add_method
    <<-END
      function rb_attr(klass, id, read, write, ex) {
        var noex;
        if (!ex) {
          noex = NOEX_PUBLIC;
        } else if (SCOPE_TEST(SCOPE_PRIVATE)) {
          noex = NOEX_PRIVATE;
          // removed warning
        } else if (SCOPE_TEST(SCOPE_PROTECTED)) {
          noex = NOEX_PROTECTED;
        } else {
          noex = NOEX_PUBLIC;
        }
        if (!rb_is_local_id(id) && !rb_is_const_id(id)) { rb_name_error(id, "invalid attribute name '%s'", rb_id2name(id)); }
        var name = rb_id2name(id);
        if (!name) { rb_raise(rb_eArgError, "argument needs to be symbol or string"); }
        // removed string buf computation
        var attriv = rb_intern('@' + name);
        if (read) { rb_add_method(klass, id, NEW_IVAR(attriv), noex); }
        if (write) { rb_add_method(klass, rb_id_attrset(id), NEW_ATTRSET(attriv), noex); }
      }
    END
  end
  
  # verbatim
  def rb_block_call
    add_function :iterate_method
    <<-END
      function rb_block_call(obj, mid, argc, argv, bl_proc, data2) {
        var arg = {};
        arg.obj = obj;
        arg.mid = mid;
        arg.argc = argc;
        arg.argv = argv;
        return rb_iterate(iterate_method, arg, bl_proc, data2);
      }
    END
  end
  
  # verbatim
  def rb_block_given_p
    <<-END
      function rb_block_given_p() {
        return ((ruby_frame.iter == ITER_CUR) && ruby_block) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def rb_block_proc
    add_function :proc_alloc
    <<-END
      function rb_block_proc() {
        return proc_alloc(rb_cProc, Qfalse);
      }
    END
  end
  
  # modified cache access and expanded rb_get_method_body
  def rb_call
    add_function :rb_id2name, :rb_raise, :rb_get_method_body, :method_missing, :rb_class_real, :rb_obj_is_kind_of, :rb_call0
    <<-END
      function rb_call(klass, recv, mid, argc, argv, scope, self) {
        var body;
        var noex;
        var id = mid;
        var ent;
        if (!klass) { rb_raise(rb_eNotImpError, "method '%s' called on terminated object (0x%x)", rb_id2name(mid), recv); }
        /* is it in the method cache? */
        ent = cache[EXPR1(klass, mid)] || {}; // was 'ent = cache + EXPR1(klass, mid)'
        if ((ent.mid == mid) && (ent.klass == klass)) {
          if (!ent.method) { return method_missing(recv, mid, argc, argv, scope == 2 ? CSTAT_VCALL : 0); }
          body  = ent.method;
          klass = ent.origin;
          id    = ent.mid0;
          noex  = ent.noex;
        } else {
          var tmp = rb_get_method_body(klass, id, noex); // ff. was 'body = rb_get_method_body(&klass, &id, &noex)'
          body  = tmp[0];
          klass = tmp[1];
          id    = tmp[2];
          noex  = tmp[3];
          if (body === 0) {
            if (scope == 3) { return method_missing(recv, mid, argc, argv, CSTAT_SUPER); }
          //console.log(klass, recv, mid, argc, argv, scope, self);
          //throw('fail');
            return method_missing(recv, mid, argc, argv, scope == 2 ? CSTAT_VCALL : 0);
          }
        }
        if ((mid != missing) && (scope === 0)) {
          /* receiver specified form for private method */
          if (noex & NOEX_PRIVATE) { return method_missing(recv, mid, argc, argv, CSTAT_PRIV); }
          /* self must be kind of a specified form for protected method */
          if (noex & NOEX_PROTECTED) {
            var defined_class = klass;
            if (self == Qundef) { self = ruby_frame.self; }
            if (TYPE(defined_class) == T_ICLASS) { defined_class = defined_class.basic.klass; }
            if (!rb_obj_is_kind_of(self, rb_class_real(defined_class))) { return method_missing(recv, mid, argc, argv, CSTAT_PROT); }
          }
        }
        return rb_call0(klass, recv, mid, id, argc, argv, body, noex);
      }
    END
  end
  
  # CHECK
  def rb_call0
    add_function :rb_raise, :call_cfunc, :jump_tag_but_local_jump, :rb_attr_get
    <<-END
      function rb_call0(klass, recv, id, oid, argc, argv, body, flags) {
        var b2;
        var result = Qnil;
        var itr;
      //var tick;
      //TMP_PROTECT();
        var safe = -1;
        if ((NOEX_SAFE(flags) > ruby_safe_level) && (NOEX_SAFE(flags) > 2)) { rb_raise(rb_eSecurityError, "calling insecure method: %s", rb_id2name(id)); }
        switch (ruby_iter.iter) {
          case ITER_PRE:
          case ITER_PAS:
            itr = ITER_CUR;
            break;
          case ITER_CUR:
          default:
            itr = ITER_NOT;
            break;
        }
      //removed GC 'tick' process
        if (argc < 0) {
          console.log('This logical branch has never yet been called. This is the first time this message has ever been logged.');
          var tmp;
          var nargv;
          argc = -argc - 1;
          tmp = splat_value(argv[argc]);
          var nargv = [];
          MEMCPY(nargv, argv, argc);
          // CHECK THIS ***********************
          // CHECK THIS ***********************
          // CHECK THIS ***********************
          // CHECK THIS ***********************
          console.log('HEY CHECK IF THE MEMCPY IN rb_call0 IS CORRECT');
          MEMCPY(nargv, tmp.ptr, tmp.ptr.length, argc); // is it +argc or -argc?
          argc += tmp.ptr.length;
          argv = nargv;
        }
        
        PUSH_ITER(itr);
        PUSH_FRAME();
        ruby_frame.last_func = id;
        ruby_frame.orig_func = oid;
        ruby_frame.last_class = (flags & NOEX_NOSUPER) ? 0 : klass;
        ruby_frame.self = recv;
        ruby_frame.argc = argc;
        ruby_frame.flags = 0;
        
        switch(nd_type(body)) {
          case NODE_ATTRSET:
            if (argc != 1) { rb_raise(rb_eArgError, "wrong number of arguments (%d for 1)", argc); }
            result = rb_ivar_set(recv, body.nd_vid, argv[0]);
            break;
          
          case NODE_CFUNC:
            // removed bug warning
            // removed event hooks handler
            result = call_cfunc(body.nd_cfnc, recv, body.nd_argc, argc, argv);
            break;
          
          case NODE_IVAR:
            if (argc != 0) { rb_raise(rb_eArgError, "wrong number of arguments (%d for 0)", argc); }
            result = rb_attr_get(recv, body.nd_vid);
            break;
          
          // skipped other types of nodes for now
          
          case NODE_SCOPE:
            var local_vars;
            var state = 0;
            var saved_cref = 0;
            
            PUSH_SCOPE();
            
            if (body.nd_rval) {
              saved_cref = ruby_cref;
              ruby_cref = body.nd_rval;
            }
            
            PUSH_CLASS(ruby_cbase);
            
            if (body.nd_tbl) {
              local_vars = []; // was 'local_vars = TMP_ALLOC(body->nd_tbl[0]+1)'
            //*local_vars++ = (VALUE)body;
            //rb_mem_clear(local_vars, body->nd_tbl[0]);
              ruby_scope.local_tbl = body.nd_tbl;
              ruby_scope.local_vars = local_vars;
            } else {
              local_vars = ruby_scope.local_vars = 0;
              ruby_scope.local_tbl = 0;
            }
            b2 = body = body.nd_next;
            
            if (NOEX_SAFE(flags) > ruby_safe_level) {
              safe = ruby_safe_level;
              ruby_safe_level = NOEX_SAFE(flags);
            }
            
            PUSH_VARS();
            
            PUSH_TAG(PROT_FUNC);
            
            try { // was EXEC_TAG
              var node = 0;
              var nopt = 0;
              
              if (nd_type(body) == NODE_ARGS) {
                node = body;
                body = 0;
              } else if (nd_type(body) == NODE_BLOCK) {
                node = body.nd_head;
                body = body.nd_next;
              }
              
              if (node) {
                // removed bug warning
                var i = node.nd_cnt;
                if (argc < i) { rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)", argc, i); }
                if (!node.nd_rest) {
                  var optnode = node.nd_opt;
                  nopt = i;
                  while (optnode) {
                    nopt++;
                    optnode = optnode.nd_next;
                  }
                  if (argc > nopt) { rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)", argc, nopt); }
                }
                
                if (local_vars) {
                  if (i > 0) {
                    MEMCPY(local_vars, argv, i);
                  }
                }
                
                var argvp = i;
                argc -= i;
                
                if (node.nd_opt && node.nd_opt.nd_head) {
                  // i is now equal to the number of formal args
                  // argc is equal to the number of arguments remaining that were not assigned to formal args
                  var opt = node.nd_opt;
                  for (var i2 = 0; i2 < i; ++i2) { opt = opt.nd_next; } // ADDED; MOVES PAST FORMAL ARGS WHICH ARE NOW INCLUDED IN ND_OPT
                  // this loops through each optional argument, calling :assign
                  // after each optional argument is processed:
                  //   argvp is incremented by one. final result: argvp points to the start of the rest args in argv
                  //   argc is decremented by one. final result: argc is equal to the number of rest args only
                  //   i is incremented by one. final result: i is equal to the combined number of formal and optional args
                  while (opt && argc) {
                    assign(recv, opt.nd_head, argv[argvp], 1);
                    argvp++;
                    argc--;
                    ++i;
                    opt = opt.nd_next;
                  }
                  
                  if (opt) {
                    rb_eval(recv, opt);
                    while (opt) {
                      opt = opt.nd_next;
                      ++i;
                    }
                  }
                }
                
                if (!node.nd_rest) {
                  i = nopt;
                } else {
                  var v = rb_ary_new();
                  if (argc > 0) {
                    for (var argv_index = 0, l = argv.length, offset = l - argc, dest = v.ptr; argv_index < argc; ++argv_index) {
                      dest[argv_index] = argv[argv_index + offset];
                    }
                    i = -i - 1;
                  }
                  assign(recv, node.nd_rest, v, 1);
                }
                ruby_frame.argc = i;
              }
            //if (event_hooks) { EXEC_EVENT_HOOK(RUBY_EVENT_CALL, b2, recv, id, klass); }
              
              result = rb_eval(recv, body);
            } catch (x) {
              if (typeof(state = x) != 'number') { throw(state); }
              if ((state == TAG_RETURN) && TAG_DST()) {
                result = prot_tag.retval;
                state = 0;
              }
            }
            POP_TAG();
            POP_VARS();
            POP_CLASS();
            POP_SCOPE();
            ruby_cref = saved_cref;
            if (safe >= 0) { ruby_safe_level = safe; }
            switch (state) {
              case 0:
                break;
              case TAG_BREAK:
              case TAG_RETURN:
                JUMP_TAG(state);
                break;
              case TAG_RETRY:
                if (rb_block_given_p()) { JUMP_TAG(state); }
                /* fall through */
              default:
                jump_tag_but_local_jump(state, result);
            }
            break;
          default:
            console.log('unimplemented node type in rb_call0: %x', nd_type(body));
        }
        POP_FRAME();
        POP_ITER();
        return result;
      }
    END
  end
  
  # verbatim
  def rb_call_super
    add_function :rb_name_error, :rb_id2name, :method_missing, :rb_call
    <<-END
      function rb_call_super(argc, argv) {
        var result;
        var self;
        var klass;
        if (ruby_frame.last_class === 0) { rb_name_error(ruby_frame.last_func, "calling 'super' from '%s' is prohibited", rb_id2name(ruby_frame.orig_func)); }
        self = ruby_frame.self;
        klass = ruby_frame.last_class;
        if (klass.superclass === 0) { return method_missing(self, ruby_frame.orig_func, argc, argv, CSTAT_SUPER); }
        PUSH_ITER(ruby_iter.iter ? ITER_PRE : ITER_NOT);
        result = rb_call(klass.superclass, self, ruby_frame.orig_func, argc, argv, 3, Qundef);
        POP_ITER();
        return result;
      }
    END
  end
  
  # modified cache handling
  def rb_clear_cache
    <<-END
      function rb_clear_cache() {
        if (!ruby_running) { return; }
        for (var x in cache) { cache[x].mid = 0; }
      }
    END
  end
  
  # modified cache handling
  def rb_clear_cache_by_class
    <<-END
      function rb_clear_cache_by_class(klass) {
        if (!ruby_running) { return; }
        for (var x in cache) {
          var ent = cache[x];
          if ((ent.klass == klass) || (ent.origin == klass)) { ent.mid = 0; }
        }
      }
    END
  end
  
  # modified cache handling
  def rb_clear_cache_by_id
    <<-END
      function rb_clear_cache_by_id(id) {
        if (!ruby_running) { return; }
        for (var x in cache) {
          var ent = cache[x];
          if (ent.mid == id) { ent.mid = 0; }
        }
      }
    END
  end
  
  # CHECK THIS; IT'S WEIRD
  def rb_copy_node_scope
    <<-END
      function rb_copy_node_scope(node, rval) {
        var copy = NEW_NODE(NODE_SCOPE, 0, rval, node.nd_next);
        if (node.nd_tbl) {
          copy.nd_tbl = []; // was 'copy->nd_tbl = ALLOC_N(ID, node->nd_tbl[0]+1)'
          copy.nd_tbl.zero = node.nd_tbl; // added... but why?
          MEMCPY(copy.nd_tbl, node.nd_tbl, node.nd_tbl.length); // was 'MEMCPY(copy->nd_tbl, node->nd_tbl, ID, node->nd_tbl[0]+1)'
        } else {
          copy.nd_tbl = 0;
        }
        return copy;
      }
    END
  end
  
  # verbatim
  def rb_define_alloc_func
    add_function :rb_add_method, :rb_singleton_class, :rb_check_type
    <<-END
      function rb_define_alloc_func(klass, func) {
        Check_Type(klass, T_CLASS);
        rb_add_method(rb_singleton_class(klass), ID_ALLOCATOR, NEW_CFUNC(func, 0), NOEX_PRIVATE);
      }
    END
  end
  
  # verbatim
  def rb_dvar_ref
    <<-END
      function rb_dvar_ref(id) {
        var vars = ruby_dyna_vars;
        while (vars) {
          if (vars.id == id) { return vars.val; }
          vars = vars.next;
        }
        return Qnil;
      }
    END
  end
  
  # removed thread check
  def rb_ensure
    <<-END
      function rb_ensure(b_proc, data1, e_proc, data2) {
        var state;
        var result = Qnil;
        var retval;
        PUSH_TAG(PROT_NONE);
        try { // was EXEC_TAG
          result = b_proc(data1);
        } catch (x) {
          if (typeof(state = x) != 'number') { throw(state); }
        }
        POP_TAG();
        retval = (prot_tag) ? prot_tag.retval : Qnil; /* save retval */
        e_proc(data2); // was 'if (!thread_no_ensure()) { (*e_proc)(data2); }'
        if (prot_tag) { return_value(retval); }
        if (state) { JUMP_TAG(state); }
        return result;
      }
    END
  end
  
  # CHECK
  def rb_eval
    add_function :ev_const_get, :rb_dvar_ref, :block_pass, :rb_hash_new,
                 :rb_hash_aset, :rb_alias, :rb_to_id, :rb_ary_new,
                 :local_tbl, :module_setup, :class_prefix, :rb_copy_node_scope,
                 :rb_const_get_from, :rb_gvar_set, :rb_gvar_get, :rb_global_entry,
                 :handle_rescue, :massign
    add_method :[]=
    <<-END
      function rb_eval(self, node) {
        ruby_current_node = node;
        var state = 0;
        var result = Qnil;
        var contnode = 0;
        var finish_flag = 0xfe;
        var again_flag = 0xff;
        do {
          try {
            var goto_again = 0;
            if (!node) { RETURN(Qnil); }
            switch (nd_type(node)) {
              case NODE_ALIAS:
                rb_alias(ruby_class, rb_to_id(rb_eval(self, node.nd_1st)), rb_to_id(rb_eval(self, node.nd_2nd)));
                result = Qnil;
                break;
              
              case NODE_AND:
                result = rb_eval(self, node.nd_1st);
                if (!RTEST(result)) { break; }
                node = node.nd_2nd;
                throw({ goto_flag: again_flag });
                break;
              
              case NODE_ARRAY:
                var ary = rb_ary_new(); // changed from rb_ary_new2, ignoring node->nd_alen
                for (var i = 0, dest = ary.ptr; node; node = node.nd_next) {
                  dest[i++] = rb_eval(self, node.nd_head);
                  // removed ary->len
                }
                result = ary;
                break;
              
              // verbatim
              case NODE_ATTRASGN:
                var recv;
                var argc;
                var argv;
                var scope;
              //TMP_PROTECT;
                BEGIN_CALLARGS;
                if (node.nd_recv == 1) {
                  recv = self;
                  scope = 1;
                } else {
                  recv = rb_eval(self, node.nd_recv);
                  scope = 0;
                }
                SETUP_ARGS(node.nd_args);
                END_CALLARGS;
                ruby_current_node = node;
                rb_call(CLASS_OF(recv), recv, node.nd_mid, argc, argv, scope, self);
                result = argv[argc - 1];
              
              // verbatim
              case NODE_BEGIN:
                node = node.nd_body;
                throw({ goto_flag: again_flag }); // was 'goto again'
              
              // verbatim
              case NODE_BREAK:
                break_jump(rb_eval(self, node.nd_stts));
                break;
              
              // verbatim
              case NODE_BLOCK:
                if (contnode) {
                  result = rb_eval(self, node);
                  break;
                }
                contnode = node.nd_next;
                node = node.nd_head;
                throw({ goto_flag: again_flag }); // was 'goto again'
              
              case NODE_BLOCK_ARG:
                if (rb_block_given_p()) {
                  result = rb_block_proc();
                  ruby_scope.local_vars[node.nd_cnt] = result;
                } else {
                  result = Qnil;
                }
                break;
              
              // verbatim
              case NODE_BLOCK_PASS:
                result = block_pass(self, node);
                break;
              
              case NODE_CALL:
                var recv;
                var argc;
                var argv;
              //TMP_PROTECT;
                BEGIN_CALLARGS;
                recv = rb_eval(self, node.nd_recv);
                SETUP_ARGS(node.nd_args);
                END_CALLARGS;
                ruby_current_node = node;
                result = rb_call(CLASS_OF(recv), recv, node.nd_mid, argc, argv, 0, self);
                break;
              
              case NODE_CDECL:
                //u1: vid         (v)     if not zero, only need value and vid; if zero, need value, else, and else.nd_mid
                //u2: value/mid   (val)   value is always needed; mid is taken from else when else is needed
                //u3: else        (path)  only needed if vid is 0
                result = rb_eval(self, node.nd_value);
                if (node.nd_vid === 0) {
                  // CHECK node.nd_else.nd_mid
                  // CHECK node.nd_else.nd_mid
                  // CHECK node.nd_else.nd_mid
                  // CHECK node.nd_else.nd_mid
                  // CHECK node.nd_else.nd_mid
                  rb_const_set(class_prefix(self, node.nd_else), node.nd_else.nd_mid, result);
                } else {
                  rb_const_set(ruby_cbase, node.nd_vid, result);
                }
                break;
              
              // verbatim
              case NODE_CASE:
                var val = rb_eval(self, node.nd_head);
                var node = node.nd_body;
                while (node) {
                  var tag;
                  if (nd_type(node) != NODE_WHEN) { throw({ goto_flag: again_flag }); } // was 'goto again'
                  tag = node.nd_head;
                  while (tag) {
                    // removed event hook
                    if (tag.nd_head && (nd_type(tag.nd_head) == NODE_WHEN)) {
                      var v = rb_eval(self, tag.nd_head.nd_head);
                      if (TYPE(v) != T_ARRAY) { v = rb_ary_to_ary(v); }
                      for (var i = 0, p = v.ptr, l = v.ptr.length; i < l; ++i) {
                        if (RTEST(rb_funcall2(p[i], eqq, 1, [val]))) { // changed &val to [val]
                          node = node.nd_body;
                          throw({ goto_flag: again_flag }); // was 'goto again'
                        }
                      }
                      tag = tag.nd_next;
                      continue;
                    }
                    if (RTEST(rb_funcall2(rb_eval(self, tag.nd_head), eqq, 1, [val]))) { // changed &val to [val]
                      node = node.nd_body;
                      throw({ goto_flag: again_flag }); // was 'goto again'
                    }
                    tag = tag.nd_next;
                  }
                  node = node.nd_next;
                }
                RETURN(Qnil);
                break;
              
              case NODE_CLASS:
                var superclass;
                var gen = Qfalse;
                var cbase = class_prefix(self, node.nd_cpath);
                var cname = node.nd_cpath.nd_mid;
                
                if (node.nd_super) {
                  superclass = rb_eval(self, node.nd_super);
                  rb_check_inheritable(superclass);
                } else {
                  superclass = 0;
                }
                
                if (rb_const_defined_at(cbase, cname)) {
                  var klass = rb_const_get_at(cbase, cname);
                  if (TYPE(klass) != T_CLASS) { rb_raise(rb_eTypeError, "%s is not a class", rb_id2name(cname)); }
                  if (superclass) {
                    var tmp = rb_class_real(klass.superclass);
                    if (tmp != superclass) { rb_raise(rb_eTypeError, "superclass mismatch for class %s", rb_id2name(cname)); }
                    superclass = 0;
                  }
                  if (ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "extending class prohibited"); }
                } else {
                  if (!superclass) { superclass = rb_cObject; }
                  var klass = rb_define_class_id(cname, superclass);
                  rb_set_class_path(klass, cbase, rb_id2name(cname));
                  rb_const_set(cbase, cname, klass);
                  gen = Qtrue;
                }
                
                if (superclass && gen) { rb_class_inherited(superclass, klass); }
                result = module_setup(klass, node);
                break;
              
              case NODE_COLON2:
                var klass = rb_eval(self, node.nd_head);
                switch (TYPE(klass)) {
                  case T_CLASS:
                  case T_MODULE:
                    result = rb_const_get_from(klass, node.nd_mid);
                    break;
                  default:
                    rb_raise(rb_eTypeError, "%s is not a class/module", rb_obj_as_string(klass).ptr);
                }
                break;
              
              case NODE_COLON3:
                result = rb_const_get_from(rb_cObject, node.nd_mid);
                break;
              
              case NODE_CONST:
                result = ev_const_get(ruby_cref, node.nd_vid, self);
                break;
              
              case NODE_CVAR:
                result = rb_cvar_get(cvar_cbase(), node.nd_vid);
                break;
              
              case NODE_CVASGN:
              case NODE_CVDECL:
                result = rb_eval(self, node.nd_value);
                rb_cvar_set(cvar_cbase(), node.nd_vid, result);
                break;
              
              case NODE_DASGN_CURR:
                result = rb_eval(self, node.nd_value);
                dvar_asgn_curr(node.nd_vid, result);
                break;
              
              case NODE_DEFINED:
                var desc = is_defined(self, node.nd_head);
                result = desc ? rb_str_new(desc) : Qnil;
                break;
              
              case NODE_DEFN:
                if (node.nd_defn) {
                  rb_frozen_class_p(ruby_class);
                  var tmp = search_method(ruby_class, node.nd_mid);
                  var body = tmp[0];
                  var origin = tmp[1];

                  var noex = NOEX_PUBLIC;
                  if (SCOPE_TEST(SCOPE_PRIVATE) || (node.nd_mid == init)) { noex = NOEX_PRIVATE; } else
                  if (SCOPE_TEST(SCOPE_PROTECTED)) { noex = NOEX_PROTECTED; }
                  if (body && (origin == ruby_class) && (body.nd_body === 0)) { noex |= NOEX_NOSUPER; }

                  var defn = rb_copy_node_scope(node.nd_defn, ruby_cref);
                  rb_add_method(ruby_class, node.nd_mid, defn, noex);

                  if (scope_vmode == SCOPE_MODFUNC) {
                    rb_add_method(rb_singleton_class(ruby_class), node.nd_mid, defn, NOEX_PUBLIC);
                  }
                  result = Qnil;
                }
                break;
              
              case NODE_DEFS:
                if (node.nd_defn) {
                  var data;
                  var body = 0;
                  var recv = rb_eval(self, node.nd_recv);

                  if (ruby_safe_level >= 4 && !OBJ_TAINTED(recv)) { rb_raise(rb_eSecurityError, "Insecure: can't define singleton method"); }
                  if (FIXNUM_P(recv) || SYMBOL_P(recv)) { rb_raise(rb_eTypeError, "can't define singleton method '%s' for %s", rb_id2name(node.nd_mid, rb_obj_classname(recv))); }
                  if (OBJ_FROZEN(recv)) { rb_error_frozen("object"); }
                  var klass = rb_singleton_class(recv);
                  if ((data = st_lookup(klass.m_tbl, node.nd_mid))[0]) {
                    body = data[1];
                    if (ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "redefining method prohibited"); }
                  }
                  var defn = rb_copy_node_scope(node.nd_defn, ruby_cref);
                  rb_add_method(klass, node.nd_mid, defn, NOEX_PUBLIC | (body ? body.nd_noex & NOEX_UNDEF : 0));
                  result = Qnil;
                }
                break;
              
              case NODE_DOT2:
              case NODE_DOT3:
                var beg = rb_eval(self, node.nd_beg);
                var end = rb_eval(self, node.nd_end);
                result = rb_range_new(beg, end, nd_type(node) == NODE_DOT3);
                break;
              
              case NODE_DREGX:
              case NODE_DREGX_ONCE:
              case NODE_DSTR:
              case NODE_DSYM:
              case NODE_DXSTR:
                var str2;
                var list = node.nd_next;
                var str = rb_str_new(node.nd_lit);
                while (list) {
                  if (list.nd_head) {
                    switch (nd_type(list.nd_head)) {
                      case NODE_STR:
                        str2 = list.nd_head.nd_lit;
                        break;
                      default:
                        str2 = rb_eval(self, list.nd_head);
                    }
                    rb_str_append(str, str2);
                    OBJ_INFECT(str, str2);
                  }
                  list = list.nd_next;
                }
                switch (nd_type(node)) {
                  case NODE_DREGX:
                    result = rb_reg_new(str.ptr, str.ptr.length, node.nd_cflag);
                    break;
                  case NODE_DREGX_ONCE:
                    result = rb_reg_new(str.ptr, str.ptr.length, node.nd_cflag);
                    nd_set_type(node, NODE_LIT);
                    node.nd_lit = result;
                    break;
                  case NODE_DXSTR:
                    result = rb_funcall(self, '`', 1, str); // may need to change this to support backticks
                    break;
                  case NODE_DSYM:
                    result = rb_str_intern(str);
                    break;
                  default:
                    result = str;
                }
                break;
              
              case NODE_DVAR:
                result = rb_dvar_ref(node.nd_vid);
                break;
              
              // verbatim
              case NODE_ENSURE:
                PUSH_TAG(PROT_NONE);
                try {
                  result = rb_eval(self, node.nd_head);
                } catch (x) {
                  if (typeof(state = x) != 'number') { throw(state); }
                }
                POP_TAG();
                if (node.nd_ensr) {
                  var retval = prot_tag.retval; /* save retval */
                  var errinfo = ruby_errinfo;
                  rb_eval(self, node.nd_ensr);
                  return_value(retval);
                  ruby_errinfo = errinfo;
                }
                if (state) { JUMP_TAG(state); }
                break;
              
              case NODE_EVSTR:
                result = rb_obj_as_string(rb_eval(self, node.nd_body));
                break;
              
              // verbatim
              case NODE_FALSE:
                RETURN(Qfalse);
                break;
              
              case NODE_FCALL:
                var argc;
                var argv;
              //TMP_PROTECT;
                BEGIN_CALLARGS;
                SETUP_ARGS(node.nd_args);
                END_CALLARGS;
                ruby_current_node = node;
                result = rb_call(CLASS_OF(self), self, node.nd_mid, argc, argv, 1, self);
                break;
              
              // verbatim
              case NODE_GASGN:
                result = rb_eval(self, node.nd_value);
                rb_gvar_set(node.nd_entry, result);
                break;
              
              // verbatim
              case NODE_GVAR:
                result = rb_gvar_get(node.nd_entry);
                break;
              
              // modified hash to build from JS array rather than linked list
              case NODE_HASH:
                var hash = rb_hash_new();
                var list = node.nd_head;
                var key;
                var val;
                for (var i = 0, l = list.length; i < l; ++i) {
                  key = rb_eval(self, list[i]);
                  val = rb_eval(self, list[++i]);
                  rb_hash_aset(hash, key, val);
                }
                result = hash;
                break;
              
              case NODE_IASGN:
                result = rb_eval(self, node.nd_value);
                rb_ivar_set(self, node.nd_vid, result);
                break;
                
              // verbatim
              case NODE_IF:
                node = RTEST(rb_eval(self, node.nd_cond)) ? node.nd_body : node.nd_else; // removed event hooks
                throw({ goto_flag: again_flag }); // was 'goto again'
              
              // unwound 'goto' architecture
              case NODE_ITER:
              case NODE_FOR:
                PUSH_TAG(PROT_LOOP);
                PUSH_BLOCK(node.nd_var, node.nd_body);
                do { // added to handle 'goto' architecture
                  var goto_retry = 0;
                  try { // was EXEC_TAG
                    PUSH_ITER(ITER_PRE);
                    if (nd_type(node) == NODE_ITER) {
                      result = rb_eval(self, node.nd_iter);
                    } else {
                      var recv;
                      _block.flags &= ~BLOCK_D_SCOPE;
                      BEGIN_CALLARGS;
                      recv = rb_eval(self, node.nd_iter);
                      END_CALLARGS;
                      ruby_current_node = node;
                      result = rb_call(CLASS_OF(recv),recv,each,0,0,0,self);
                    }
                    POP_ITER();
                  } catch (x) {
                    if (typeof(state = x) != 'number') { throw(state); }
                    if ((state == TAG_BREAK) && TAG_DST()) {
                      result = prot_tag.retval;
                      state = 0;
                    } else if (state == TAG_RETRY) {
                      state = 0;
                      goto_retry = 1;
                    }
                  }
                } while (goto_retry); // added to handle 'goto' architecture
                POP_BLOCK();
                POP_TAG();
                if (state) { JUMP_TAG(state); }
                break;
              
              case NODE_IVAR:
                result = rb_ivar_get(self, node.nd_vid);
                break;
              
              case NODE_LASGN:
                result = rb_eval(self, node.nd_value);
                ruby_scope.local_vars[node.nd_cnt] = result;
                break;
              
              case NODE_LVAR:
                result = ruby_scope.local_vars[node.nd_cnt];
                break;
              
              case NODE_LIT:
                result = node.nd_lit;
                break;
              
              // verbatim
              case NODE_MASGN:
                result = massign(self, node, rb_eval(self, node.u2), 0);
                break;
              
              // verbatim
              case NODE_MATCH:
                result = rb_reg_match2(node.nd_lit);
                break;
              
              // verbatim
              case NODE_MATCH2:
                var l = rb_eval(self,node.nd_recv);
                var r = rb_eval(self,node.nd_value);
                result = rb_reg_match(l, r);
                break;
              
              // verbatim
              case NODE_MATCH3:
                var r = rb_eval(self,node.nd_recv);
                var l = rb_eval(self,node.nd_value);
                result = (TYPE(l) == T_STRING) ? rb_reg_match(r,l) : rb_funcall(l, match, 1, r);
                break;
              
              case NODE_MODULE:
                var module;
                var cbase = class_prefix(self, node.nd_cpath);
                var cname = node.nd_cpath.nd_mid;
                if (rb_const_defined_at(cbase, cname)) {
                  module = rb_const_get_at(cbase, cname);
                  if (TYPE(module) != T_MODULE) { rb_raise(rb_eTypeError, "%s is not a module", rb_id2name(cname)); }
                  if (ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "extending module prohibited"); }
                } else {
                  module = rb_define_module_id(cname);
                  rb_set_class_path(module, cbase, rb_id2name(cname));
                  rb_const_set(cbase, cname, module);
                }
                result = module_setup(module, node);
                break;
              
              // verbatim
              case NODE_NEXT:
              //CHECK_INTS;
                next_jump(rb_eval(self, node.nd_stts));
                break;

              // verbatim
              case NODE_NIL:
                RETURN(Qnil);
                break;

              case NODE_NOT:
                result = RTEST(rb_eval(self, node.nd_body)) ? Qfalse : Qtrue;
                break;

              // unsupported
              case NODE_OPT_N:
                break;

              case NODE_OR:
                result = rb_eval(self, node.nd_1st);
                if (RTEST(result)) { break; }
                node = node.nd_2nd;
                throw({ goto_flag: again_flag });
                break;

              // verbatim
              case NODE_POSTEXE:
                rb_f_END();
                nd_set_type(node, NODE_NIL); /* exec just once */
                result = Qnil;
                break;

              case NODE_REDO:
              //CHECK_INTS;
                JUMP_TAG(TAG_REDO);
                break;

              case NODE_RESCUE:
                var e_info = ruby_errinfo;
                var rescuing = 0;
                PUSH_TAG(PROT_NONE);
                do {
                  var goto_retry_entry = 0;
                  try {
                    result = rb_eval(self, node.nd_head);
                  } catch (x) {
                    if (typeof(state = x) != 'number') { throw(state); }
                    if (rescuing) {
                      if (rescuing < 0) {
                        /* in rescue argument, just reraise */
                      } else if (state == TAG_RETRY) {
                        rescuing = state = 0;
                        ruby_errinfo = e_info;
                        goto_retry_entry = 1;
                      } else if (state != TAG_RAISE) {
                        result = prot_tag.retval;
                      }
                    } else if (state == TAG_RAISE) {
                      var resq = node.nd_resq;
                      rescuing = -1;
                      while (resq) {
                        ruby_current_node = resq;
                        if (handle_rescue(self, resq)) {
                          state = 0;
                          rescuing = 1;
                          result = rb_eval(self, resq.nd_body);
                          break;
                        }
                        resq = resq.nd_head; /* next rescue */
                      }
                    } else {
                      result = prot_tag.retval;
                    }
                  }
                } while (goto_retry_entry);
                POP_TAG();
                if (state != TAG_RAISE) { ruby_errinfo = e_info; }
                if (state) { JUMP_TAG(state); }
                if (!rescuing && (node = node.nd_else)) { /* else clause given */
                  throw({ goto_flag: again_flag }); // was 'goto again'
                }
                break;

              case NODE_RETRY:
              //CHECK_INTS;
                JUMP_TAG(TAG_RETRY);
                break;

              case NODE_RETURN:
                return_jump(rb_eval(self, node.nd_stts));
                break;

              case NODE_SCLASS:
                result = rb_eval(self, node.nd_recv);
                if (FIXNUM_P(result) || SYMBOL_P(result)) { rb_raise(rb_eTypeError, "no virtual class for %s", rb_obj_classname(result)); }
                if (ruby_safe_level >= 4 && !OBJ_TAINTED(result)) { rb_raise(rb_eSecurityError, "Insecure: can't extend object"); }
                var klass = rb_singleton_class(result);
                result = module_setup(klass, node);
                break;

              // possibly unnecessary
              case NODE_SCOPE:
                console.log('you made it into a NODE_SCOPE in rb_eval(); how did you do that?');
                break;

              // verbatim
              case NODE_SELF:
                RETURN(self);
                break;

              // verbatim
              case NODE_SPLAT:
                result = splat_value(rb_eval(self, node.nd_head));
                break;

              case NODE_STR:
                result = rb_str_new(node.nd_lit);
                break;

              // verbatim
              case NODE_SVALUE:
                result = avalue_splat(rb_eval(self, node.nd_head));
                if (result == Qundef) { result = Qnil; }
                break;

              // verbatim
              case NODE_TO_ARY:
                result = rb_ary_to_ary(rb_eval(self, node.nd_head));
                break;

              // verbatim
              case NODE_TRUE:
                RETURN(Qtrue);
                break;

              // unwound 'goto' loop architecture
              case NODE_UNTIL:
                PUSH_TAG(PROT_LOOP);
                result = Qnil;
                try { // was EXEC_TAG
                  if (!(node.nd_state && RTEST(rb_eval(self, node.nd_cond)))) {
                    do { rb_eval(self, node.nd_body); } while (!RTEST(rb_eval(self, node.nd_cond)));
                  }
                } catch (x) {
                  if (typeof(state = x) != 'number') { throw(state); }
                  switch (state) {
                    case TAG_REDO:
                      state = 0;
                      do { rb_eval(self, node.nd_body); } while (!RTEST(rb_eval(self, node.nd_cond)));
                      break;
                    case TAG_NEXT:
                      state = 0;
                      while (!RTEST(rb_eval(self, node.nd_cond))) { rb_eval(self, node.nd_body); }
                      break;
                    case TAG_BREAK:
                      if (TAG_DST()) {
                        state = 0;
                        result = prot_tag.retval;
                      }
                      break;
                  }
                }
                POP_TAG();
                if (state) { JUMP_TAG(state); }
                RETURN(result);
                break;

              case NODE_VALIAS:
                rb_alias_variable(node.nd_1st, node.nd_2nd);
                result = Qnil;
                break;

              case NODE_VCALL:
                result = rb_call(CLASS_OF(self),self,node.nd_mid,0,0,2,self);
                break;

              // possibly unnecessary
              case NODE_WHEN:
                console.log('you made it into a NODE_WHEN in rb_eval(); how did you do that?');
                break;

              // unwound 'goto' loop architecture
              case NODE_WHILE:
                PUSH_TAG(PROT_LOOP);
                result = Qnil;
                try { // was EXEC_TAG
                  if (!(node.nd_state && !RTEST(rb_eval(self, node.nd_cond)))) {
                    do { rb_eval(self, node.nd_body); } while (RTEST(rb_eval(self, node.nd_cond)));
                  }
                } catch (x) {
                  if (typeof(state = x) != 'number') { throw(state); }
                  switch (state) {
                    case TAG_REDO:
                      state = 0;
                      do { rb_eval(self, node.nd_body); } while (RTEST(rb_eval(self, node.nd_cond)));
                      break;
                    case TAG_NEXT:
                      state = 0;
                      while (RTEST(rb_eval(self, node.nd_cond))) { rb_eval(self, node.nd_body); }
                      break;
                    case TAG_BREAK:
                      if (TAG_DST()) {
                        state = 0;
                        result = prot_tag.retval;
                      }
                      break;
                  }
                }
                POP_TAG();
                if (state) { JUMP_TAG(state); }
                RETURN(result);
                break;

              case NODE_XSTR:
                result = node.nd_head();
                result = (result === null || result === undefined) ? Qnil : result;
                break;

              case NODE_ZARRAY:
                result = rb_ary_new();
                break;
            }
          } catch (e) {
            switch (e.goto_flag) {
              case finish_flag:
                result = e.value;
                break;
              case again_flag:
                goto_again = 1;
                break;
              default:
                throw(e);
            }
          }
          if (contnode && !goto_again) {
            node = contnode;
            contnode = 0;
            goto_again = 1;
          }
        } while (goto_again);
        return result;
      }
    END
  end
  
  # replaced recursive hash threaded lookup with JS global var 'recursive_hash'
  def rb_exec_recursive
    add_function :rb_obj_id, :recursive_check, :recursive_push, :recursive_pop
    <<-END
      function rb_exec_recursive(func, obj, arg) {
        var hash = recursive_hash;
        var objid = rb_obj_id(obj);
        if (recursive_check(hash, objid)) {
          return func(obj, arg, Qtrue);
        } else {
          var result = Qundef;
          var state = 0;
          hash = recursive_push(hash, objid);
          PUSH_TAG(PROT_NONE);
          try { // was EXEC_TAG
            result = func(obj, arg, Qfalse);
          } catch (x) {
            if (typeof(state = x) != 'number') { throw(state); }
          }
          POP_TAG();
          recursive_pop(hash, objid);
          if (state) { JUMP_TAG(state); }
          return result;
        }
      }
    END
  end
  
  # expanded 'search_method'
  def rb_export_method
    add_function :rb_secure, :rb_add_method, :search_method
    <<-END
      function rb_export_method(klass, name, noex) {
        if (klass == rb_cObject) { rb_secure(4); }
        var tmp = search_method(klass, name);
        var body = tmp[0];
        var origin = tmp[1];
        if (!body && (TYPE(klass) == T_MODULE)) {
          tmp = search_method(rb_cObject, name);
          body = tmp[0];
          origin = tmp[1];
        }
        if (!body || !body.nd_body) { print_undef(klass, name); }
        if (body.nd_noex != noex) {
          if (klass == origin) {
            body.nd_noex = noex;
          } else {
            rb_add_method(klass, name, NEW_ZSUPER(), noex);
          }
        }
      }
    END
  end
  
  # verbatim
  def rb_f_block_given_p
    <<-END
      function rb_f_block_given_p() {
        if (ruby_frame.prev && (ruby_frame.prev.iter == ITER_CUR) && ruby_block) { return Qtrue; }
        return Qfalse;
      }
    END
  end
  
  # unsupported
  def rb_f_END
    add_function :rb_raise
    <<-END
      function rb_f_END() {
        rb_raise(rb_eRuntimeError, "Red doesn't support END blocks");
      }
    END
  end
  
  # ADDED
  def rb_f_log
    <<-END
      function rb_f_log(self,obj) {
        console.log(obj);
        return Qnil;
      }
    END
  end
  
  # verbatim
  def rb_f_raise
    add_function :rb_raise_jump, :rb_make_exception
    <<-END
      function rb_f_raise(argc, argv) {
        rb_raise_jump(rb_make_exception(argc, argv));
        return Qnil; /* not reached */
      }
    END
  end
  
  # verbatim
  def rb_f_send
    add_function :rb_block_given_p, :rb_call, :rb_to_id
    <<-END
      function rb_f_send(argc, argv, recv) {
        if (argc === 0) { rb_raise(rb_eArgError, "no method name given"); }
        var retval;
        PUSH_ITER(rb_block_given_p() ? ITER_PRE : ITER_NOT);
        retval = rb_call(CLASS_OF(recv), recv, rb_to_id(argv[0]), argc - 1, argv.slice(1), 1, Qundef);
        POP_ITER();
        return retval;
      }
    END
  end
  
  # verbatim
  def rb_frozen_class_p
    add_function :rb_error_frozen
    <<-END
      function rb_frozen_class_p(klass) {
        var desc = '???';
        if (OBJ_FROZEN(klass)) {
          if (FL_TEST(klass, FL_SINGLETON)) {
            desc = "object";
          } else {
            switch (TYPE(klass)) {
              case T_MODULE:
              case T_ICLASS:
                desc = "module";
                break;
              case T_CLASS:
                desc = "class";
                break;
            }
          }
          rb_error_frozen(desc);
        }
      }
    END
  end
  
  # collapsed rb_funcall and vafuncall; simplified va handling
  def rb_funcall
    add_function :rb_call
    <<-END
      function rb_funcall(recv, mid, n) {
        var argv = 0;
        if (n > 0) {
          for (var i = 0, argv = []; i < n; ++i) {
            argv[i] = arguments[i + 3];
          }
        }
        return rb_call(CLASS_OF(recv), recv, mid, n, argv, 1, Qundef);
      }
    END
  end
  
  # verbatim
  def rb_funcall2
    add_function :rb_call
    <<-END
      function rb_funcall2(recv, mid, argc, argv) {
        return rb_call(CLASS_OF(recv), recv, mid, argc, argv, 1, Qundef);
      }
    END
  end
  
  # modified to return array including 'pointers': [body, klassp, idp, noexp], changed cache handling
  def rb_get_method_body
    add_function :search_method
    <<-END
      function rb_get_method_body(klassp, idp, noexp) {
        var id = idp;
        var klass = klassp;
        var origin = 0;
        var body;
        var ent;
        var tmp = search_method(klass, id, origin); // expanded search_method
        body = tmp[0];
        origin = tmp[1];
        if (body === 0 || !body.nd_body) {
          /* store empty info in cache */
          ent = cache[EXPR1(klass, id)] = {}; // was 'ent = cache + EXPR1(klass, id)'
          ent.klass = klass;
          ent.origin = klass;
          ent.mid = ent.mid0 = id;
          ent.noex = 0;
          ent.method = 0;
          return [0,klassp,idp,noexp];
        }
        if (ruby_running) {
          /* store in cache */
          ent = cache[EXPR1(klass, id)] = {}; // was 'ent = cache + EXPR1(klass, id)'
          ent.klass = klass;
          ent.noex = body.nd_noex;
          noexp = body.nd_noex;
          body = body.nd_body;
          if (nd_type(body) == NODE_FBODY) {
            ent.mid = id;
            klassp = body.nd_orig;
            ent.origin = body.nd_orig;
            idp = ent.mid0 = body.nd_mid;
            body = ent.method = body.nd_head;
          } else {
            klassp = origin;
            ent.origin = origin;
            ent.mid = ent.mid0 = id;
            ent.method = body;
          }
        } else {
          noexp = body.nd_noex;
          body = body.nd_body;
          if (nd_type(body) == NODE_FBODY) {
            klassp = body.nd_orig;
            idp = body.nd_mid;
            body = body.nd_head;
          } else {
            klassp = origin;
          }
        }
        return [body, klassp, idp, noexp];
      }
    END
  end
  
  # verbatim
  def rb_iter_break
    add_function :break_jump
    <<-END
      function rb_iter_break() {
        break_jump(Qnil);
      }
    END
  end
  
  # unwound 'goto' architecture, expanded EXEC_TAG
  def rb_iterate
    <<-END
      function rb_iterate(it_proc, data1, bl_proc, data2) {
        var state = 0;
        var retval = Qnil;
        var node = NEW_IFUNC(bl_proc, data2);
        var self = ruby_top_self;
        PUSH_TAG(PROT_LOOP);
        PUSH_BLOCK(0, node);
        PUSH_ITER(ITER_PRE);
        do { // added to handle 'goto iter_retry'
          var goto_iter_retry = 0;
          try { // was EXEC_TAG
            retval = it_proc(data1);
          } catch (x) {
            if (typeof(state = x) != 'number') { throw(state); }
            if ((state == TAG_BREAK) && TAG_DST()) {
              retval = prot_tag.retval;
              state = 0;
            } else if (state == TAG_RETRY) {
              state = 0;
              goto_iter_retry = 1;
            }
          }
        } while (goto_iter_retry);
        POP_ITER();
        POP_BLOCK();
        POP_TAG();
        switch (state) {
          case 0:
            break;
          default:
            JUMP_TAG(state);
        }
        return retval;
      }
    END
  end
  
  # CHECK
  def rb_longjmp
    add_function :rb_exc_new, :ruby_set_current_source, :get_backtrace,
                 :make_backtrace, :set_backtrace, :rb_obj_dup
    <<-END
      function rb_longjmp(tag, mesg) {
        var at;
        // removed thread handling
        if (NIL_P(mesg)) { mesg = ruby_errinfo; }
        if (NIL_P(mesg)) { mesg = rb_exc_new(rb_eRuntimeError, 0, 0); }
        ruby_set_current_source();
        if (ruby_sourcefile && !NIL_P(mesg)) {
          at = get_backtrace(mesg);
          if (NIL_P(at)) {
            at = make_backtrace();
            if (OBJ_FROZEN(mesg)) { mesg = rb_obj_dup(mesg); }
            set_backtrace(mesg, at);
          }
        }
        if (!NIL_P(mesg)) { ruby_errinfo = mesg; }
        // removed 'debug' section
        // removed 'trap mask' call
        // removed event hook
        if (!prot_tag) { error_print(); }
        // removed thread handler
        JUMP_TAG(tag);
      }
    END
  end
  
  # unwound 'goto' architecture
  def rb_make_exception
    add_function :rb_exc_new3, :rb_intern, :rb_respond_to, :rb_funcall, :rb_obj_is_kind_of, :set_backtrace, :rb_raise
    add_method :exception
    <<-END
      function rb_make_exception(argc, argv) {
        var exception;
        var n;
        var mesg = Qnil;
        switch (argc) {
          case 0:
            mesg = Qnil;
            break;
          case 1:
            if (NIL_P(argv[0])) { break; }
            if (TYPE(argv[0]) == T_STRING) {
              mesg = rb_exc_new3(rb_eRuntimeError, argv[0]);
              break;
            }
            n = 0;
            // removed 'goto exception_call' and duplicated code here
            exception = rb_intern('exception'); 
            if (!rb_respond_to(argv[0], exception)) { rb_raise(rb_eTypeError, "exception class/object expected"); }
            mesg = rb_funcall(argv[0], exception, n, argv[1]);
            break;
          case 2:
          case 3:
            n = 1;
            exception = rb_intern('exception');
            if (!rb_respond_to(argv[0], exception)) { rb_raise(rb_eTypeError, "exception class/object expected"); }
            mesg = rb_funcall(argv[0], exception, n, argv[1]);
            break;
          default:
            rb_raise(rb_eArgError, "wrong number of arguments");
            break;
        }
        if (argc > 0) {
          if (!rb_obj_is_kind_of(mesg, rb_eException)) { rb_raise(rb_eTypeError, "exception object expected"); }
          if (argc > 2) { set_backtrace(mesg, argv[2]); }
        }
        return mesg;
      }
    END
  end
  
  # modified cache handling and expanded rb_get_method_body
  def rb_method_boundp
    add_function :rb_get_method_body
    <<-END
      function rb_method_boundp(klass, id, ex) {
        var ent;
        var noex;
        /* is it in the method cache? */
        ent = cache[EXPR1(klass, id)] || {}; // was 'ent = cache + EXPR1(klass, id)'
        if ((ent.mid == id) && (ent.klass == klass)) {
          if (ex && (ent.noex & NOEX_PRIVATE)) { return Qfalse; }
          if (!ent.method) { return Qfalse; }
          return Qtrue;
        }
        var tmp = rb_get_method_body(klass, id, noex); // expanded
        var body = tmp[0];
        var noex = tmp[3];
        if (body) { return (ex && (noex & NOEX_PRIVATE)) ? Qfalse : Qtrue; }
        return Qfalse;
      }
    END
  end
  
  # verbatim
  def rb_method_node
    add_function :rb_get_method_body
    <<-END
      function rb_method_node(klass, id) {
        return rb_get_method_body(klass, id)[0];
      }
    END
  end
  
  # verbatim
  def rb_need_block
    add_function :rb_block_given_p, :localjump_error
    <<-END
      function rb_need_block() {
        if (!rb_block_given_p()) { localjump_error("no block given", Qnil, 0); }
      }
    END
  end
  
  # reduced nesting of 'union' slots
  def rb_node_newnode
    <<-END
      function rb_node_newnode(type, a0, a1, a2) {
        var n = {
          'rvalue': last_value += 4,
          'flags': T_NODE,
          'nd_file': ruby_sourcefile,
          'u1': a0,
          'u2': a1,
          'u3': a2
        };
        nd_set_line(n,ruby_sourceline);
        nd_set_type(n,type);
        return n;
      }
    END
  end
  
  # verbatim
  def rb_obj_respond_to
    add_function :rb_method_node, :rb_method_boundp, :rb_funcall2
    add_method :respond_to?
    <<-END
      function rb_obj_respond_to(obj, id, priv) {
        var klass = CLASS_OF(obj);
        if (rb_method_node(klass, respond_to) == basic_respond_to) {
          return rb_method_boundp(klass, id, !priv);
        } else {
          var args = [];
          var n = 0;
          args[n++] = ID2SYM(id);
          if (priv) { args[n++] = Qtrue; }
          return RTEST(rb_funcall2(obj, respond_to, n, args));
        }
      }
    END
  end
  
  # removed cont_protect stuff, modified to return array [result, status] instead of using pointers
  def rb_protect
    <<-END
      function rb_protect(proc, data) {
        var result = Qnil;
        var status = 0;
        PUSH_TAG(PROT_NONE);
        try { // was EXEC_TAG
          result = proc(data);
        } catch (x) {
          if (typeof(status = x) != 'number') { throw(status); }
        }
        POP_TAG();
        if (status != 0) { return [Qnil, status]; }
        return [result, 0];
      }
    END
  end
  
  # verbatim
  def rb_raise_jump
    add_function :rb_longjmp
    <<-END
      function rb_raise_jump(mesg) {
        if (ruby_frame != top_frame) {
          PUSH_FRAME(); /* fake frame */
          ruby_frame = _frame.prev.prev;
          rb_longjmp(TAG_RAISE, mesg);
          POP_FRAME();
        }
        rb_longjmp(TAG_RAISE, mesg);
      }
    END
  end
  
  # verbatim
  def rb_rescue
    add_function :rb_rescue2
    <<-END
      function rb_rescue(b_proc, data1, r_proc, data2) {
        return rb_rescue2(b_proc, data1, r_proc, data2, rb_eStandardError, 0);
      }
    END
  end
  
  # modified to use JS 'arguments' object instead of va_list
  def rb_rescue2
    add_function :rb_obj_is_kind_of
    <<-END
      function rb_rescue2(b_proc, data1, r_proc, data2) {
        var result;
        var state = 0;
        var e_info = ruby_errinfo;
        var handle = Qfalse;
        PUSH_TAG(PROT_NONE);
        try { // was EXEC_TAG
          result = b_proc(data1);
        } catch (x) {
          if (typeof(state = x) != 'number') { throw(state); }
          switch (state) {
            case TAG_RETRY:
              if (!handle) { break; }
              handle = Qfalse;
              state = 0;
              ruby_errinfo = Qnil;
            case TAG_RAISE:
              if (handle) { break; }
              handle = Qfalse;
              for (var i = 4, l = arguments.length; i < l; ++i) {
                if (rb_obj_is_kind_of(ruby_errinfo, arguments[i])) {
                  handle = Qtrue;
                  break;
                }
              }
              if (handle) {
                state = 0;
                if (r_proc) {
                  result = r_proc(data2, ruby_errinfo);
                } else {
                  result = Qnil;
                }
                ruby_errinfo = e_info;
              }
          }
        }
        POP_TAG();
        if (state) { JUMP_TAG(state); }
        return result;
      }
    END
  end
  
  # verbatim
  def rb_respond_to
    add_function :rb_obj_respond_to
    <<-END
      function rb_respond_to(obj, id) {
        return rb_obj_respond_to(obj, id, Qfalse);
      }
    END
  end
  
  # verbatim
  def rb_secure
    add_function :rb_raise, :rb_id2name
    <<-END
      function rb_secure(level) {
        if (level <= ruby_safe_level) {
          if (ruby_frame.last_func) {
            rb_raise(rb_eSecurityError, "Insecure operation '%s' at level %d", rb_id2name(ruby_frame.last_func), ruby_safe_level);
          } else {
            rb_raise(rb_eSecurityError, "Insecure operation at level %d", ruby_safe_level);
          }
        }
      }
    END
  end
  
  # verbatim
  def rb_special_const_p
    <<-END
      function rb_special_const_p(obj) {
        return SPECIAL_CONST_P(obj) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def rb_svar
    <<-END
      function rb_svar(cnt) {
        var vars = ruby_dyna_vars;
        if (!ruby_scope.local_tbl) { return 0; }
        if (cnt >= ruby_scope.local_tbl[0]) { return 0; }
        var id = ruby_scope.local_tbl[cnt + 1];
        while (vars) {
          if (vars.id == id) { return vars.val; }
          vars = vars.next;
        }
        if (ruby_scope.local_vars === 0) { return 0; }
        return ruby_scope.local_vars[cnt];
      }
    END
  end
  
  # verbatim
  def rb_undef_alloc_func
    add_function :rb_add_method, :rb_singleton_class, :rb_check_type
    <<-END
      function rb_undef_alloc_func(klass) {
        Check_Type(klass, T_CLASS);
        rb_add_method(rb_singleton_class(klass), ID_ALLOCATOR, 0, NOEX_UNDEF);
      }
    END
  end
  
  # verbatim
  def rb_yield
    add_function :rb_yield_0
    <<-END
      function rb_yield(val) {
        return rb_yield_0(val, 0, 0, 0, Qfalse);
      }
    END
  end
  
  # CHECK
  def rb_yield_0
    add_function :rb_need_block, :new_dvar, :rb_raise, :svalue_to_mrhs, :massign, :assign,
                 :rb_ary_new3, :svalue_to_avalue, :avalue_to_svalue, :rb_block_proc,
                 :rb_eval, :scope_dup, :proc_jump_error
    <<-END
      // unwound 'goto' architecture, eliminated GC handlers
      function rb_yield_0(val, x, klass, flags, avalue) {
        var node;
        var vars;
        var result = Qnil;
        var old_cref;
        var block;
        var old_scope;
        var old_vmode;
        var frame;
        var cnode = ruby_current_node;
        var lambda = flags & YIELD_LAMBDA_CALL;
        var state = 0;
        rb_need_block();
        PUSH_VARS();
        block = ruby_block;
        frame = block.frame;
        frame.prev = ruby_frame;
        frame.node = cnode;
        ruby_frame = frame;
        old_cref = ruby_cref;
        ruby_cref = block.cref;
        old_scope = ruby_scope;
        ruby_scope = block.scope;
        old_vmode = scope_vmode;
        scope_vmode = (flags & YIELD_PUBLIC_DEF) ? SCOPE_PUBLIC : block.vmode;
        ruby_block = block.prev;
        if (block.flags & BLOCK_D_SCOPE) {
          ruby_dyna_vars = new_dvar(0, 0, block.dyna_vars)
        } else { /* FOR does not introduce new scope */
          ruby_dyna_vars = block.dyna_vars;
        }
        PUSH_CLASS(klass || block.klass);
        if (!klass) { self = block.self; }
        node = block.body;
        vars = block.vars;
        var goto_pop_state = 0;
        if (vars) {
          PUSH_TAG(PROT_NONE);
          try { // was EXEC_TAG
            var bvar = null;
            do { // added to handled 'goto block_var'
              var goto_block_var = 0;
              if (vars == 1) { // vars == (NODE*)1 : what is this?   original comment: /* no parameter || */
                if (lambda && val.ptr.length != 0) { rb_raise(rb_eArgError, "wrong number of arguments (%d for 0)", val.ptr.length); }
              } else if (vars == 2) { // vars == (NODE*)2
                if ((TYPE(val) == T_ARRAY) && (val.ptr.length != 0)) { rb_raise(rb_eArgError, "wrong number of arguments (%d for 0)", val.ptr.length); }
              } else if (!bvar && (nd_type(vars) == NODE_BLOCK_PASS)) {
                bvar = vars.nd_body;
                vars = vars.nd_args;
                goto_block_var = 1;
              } else if (nd_type(vars) == NODE_MASGN) {
                if (!avalue) { val = svalue_to_mrhs(val, vars.nd_head); }
                massign(self, vars, val, lambda);
              } else { // unwound local 'goto' architecture
                var len = 0;
                if (avalue) {
                  len = val.ptr.length;
                  if (len === 0) {
                    val = Qnil;
                    ruby_current_node = cnode;
                  } else if (len == 1) {
                    val = val.ptr[0];
                  } else {
                    // removed warning
                    ruby_current_node = cnode;
                  }
                } else if (val == Qundef) {
                  val = Qnil;
                  // removed warning
                  ruby_current_node = cnode;
                }
                assign(self, vars, val, lambda);
              }
            } while (goto_block_var); // added to handled 'goto block_var'
            if (bvar) {
              var blk;
              if (flags & YIELD_PROC_CALL) {
                blk = block.block_obj;
              } else {
                blk = rb_block_proc();
              }
              assign(self, bvar, blk, 0);
            }
          } catch (x) {
            if (typeof(state = x) != 'number') { throw(state); }
          }
          POP_TAG();
          if (state) { goto_pop_state = 1; }
        }
        if (!node && !goto_pop_state) {
          state = 0;
          goto_pop_state = 1;
        }
        if (!goto_pop_state) {
          ruby_current_node = node;
          PUSH_ITER(block.iter);
          PUSH_TAG(lambda ? PROT_NONE : PROT_YIELD);
          do { // added to handle 'goto redo'
            var goto_redo = 0;
            try { // was EXEC_TAG
              if ((nd_type(node) == NODE_CFUNC) || (nd_type(node) == NODE_IFUNC)) {
                switch (node.nd_state) {
                  case YIELD_FUNC_LAMBDA:
                    if (!avalue) { val = rb_ary_new3(1, val); }
                    break;
                  case YIELD_FUNC_AVALUE:
                    if (!avalue) { val = svalue_to_avalue(val); }
                    break;
                  default:
                    if (avalue) { val = avalue_to_svalue(val); }
                    if ((val == Qundef) && (node.nd_state != YIELD_FUNC_SVALUE)) { val = Qnil; }
                }
                result = node.nd_cfnc(val, node.nd_tval, self);
              } else { result = rb_eval(self, node); }
            } catch (x) {
              if (typeof(state = x) != 'number') { throw(state); }
              switch (state) {
                case TAG_REDO:
                  state = 0;
                //CHECK_INTS;
                  goto_redo = 1;
                case TAG_NEXT:
                  if (!lambda) {
                    state = 0;
                    result = prot_tag.retval;
                  }
                  break;
                case TAG_BREAK:
                  if (TAG_DST()) {
                    result = prot_tag.retval;
                  } else {
                    lambda = Qtrue; /* just pass TAG_BREAK */
                  }
                  break;
                default:
                  break;
              }
            }
          } while (goto_redo); // added to handle 'goto redo'
          POP_TAG();
          POP_ITER();
        } // added to handle 'goto pop_state'
        POP_CLASS();
        // removed GC stuff
        POP_VARS();
        ruby_block = block;
        ruby_frame = ruby_frame.prev;
        ruby_cref = old_cref;
        if (ruby_scope.flags & SCOPE_DONT_RECYCLE) { scope_dup(old_scope); }
        ruby_scope = old_scope;
        scope_vmode = old_vmode;
        switch (state) {
          case 0:
            break;
          case TAG_BREAK:
            if (!lambda) {
              var tt = prot_tag;
              while (tt) {
                if ((tt.tag == PROT_LOOP) && (tt.blkid == ruby_block.uniq)) {
                  tt.dst = tt.frame.uniq;
                  tt.retval = result;
                  JUMP_TAG(TAG_BREAK);
                }
                tt = tt.prev;
              }
              proc_jump_error(TAG_BREAK, result);
            }
            /* fall through */
          default:
            JUMP_TAG(state);
            break;
        }
        ruby_current_node = cnode;
        return result;
      } 
    END
  end
  
  # verbatim
  def recursive_check
    add_function :rb_hash_aref, :rb_hash_lookup
    <<-END
      function recursive_check(hash, obj) {
        if (NIL_P(hash) || (TYPE(hash) != T_HASH)) {
          return Qfalse;
        } else {
          var list = rb_hash_aref(hash, ID2SYM(ruby_frame.last_func));
          if (NIL_P(list) || TYPE(list) != T_HASH) { return Qfalse; }
          if (NIL_P(rb_hash_lookup(list, obj))) { return Qfalse; }
          return Qtrue;
        }
      }
    END
  end
  
  # verbatim
  def recursive_pop
    add_function :rb_inspect, :rb_raise, :rb_string_value, :rb_hash_aref, :rb_hash_delete
    <<-END
      function recursive_pop(hash, obj) {
        var sym = ID2SYM(ruby_frame.last_func);
        if (NIL_P(hash) || TYPE(hash) != T_HASH) {
          var symname = rb_inspect(sym);
          rb_raise(rb_eTypeError, "invalid inspect_tbl hash for %s", rb_string_value(symname).ptr);
        }
        var list = rb_hash_aref(hash, sym);
        if (NIL_P(list) || TYPE(list) != T_HASH) {
          var symname = rb_inspect(sym);
          rb_raise(rb_eTypeError, "invalid inspect_tbl list for %s", rb_string_value(symname).ptr);
        }
        rb_hash_delete(list, obj);
      }
    END
  end
  
  # replaced recursive hash threaded lookup with JS global var 'recursive_hash'
  def recursive_push
    add_function :rb_hash_new, :rb_hash_aref, :rb_hash_aset
    <<-END
      function recursive_push(hash, obj) {
        var list;
        var sym = ID2SYM(ruby_frame.last_func);
        if (NIL_P(hash) || (TYPE(hash) != T_HASH)) {
          hash = rb_hash_new();
          recursive_hash = hash;
          list = Qnil;
        } else {
          list = rb_hash_aref(hash, sym);
        }
        if (NIL_P(list) || TYPE(list) != T_HASH) {
          list = rb_hash_new();
          rb_hash_aset(hash, sym, list);
        }
        rb_hash_aset(list, obj, Qtrue);
        return hash;
      }
    END
  end
  
  # verbatim
  def return_jump
    add_function :localjump_error
    <<-END
      function return_jump(retval) {
        var tt = prot_tag;
        var yield = Qfalse;
        if (retval == Qundef) { retval = Qnil; }
        while (tt) {
          if (tt.tag == PROT_YIELD) {
            yield = Qtrue;
            tt = tt.prev;
          }
          if ((tt.tag == PROT_FUNC) && (tt.frame.uniq == ruby_frame.uniq)) {
            tt.dst = ruby_frame.uniq;
            tt.retval = retval;
            JUMP_TAG(TAG_RETURN);
          }
          if ((tt.tag == PROT_LAMBDA) && !yield) {
            tt.dst = tt.frame.uniq;
            tt.retval = retval;
            JUMP_TAG(TAG_RETURN);
          }
        //removed thread jump error
          tt = tt.prev;
        }
        localjump_error("unexpected return", retval, TAG_RETURN);
      }
    END
  end
  
  # verbatim
  def ruby_set_current_source
    <<-END
      function ruby_set_current_source() {
        if (ruby_current_node) {
          ruby_sourcefile = ruby_current_node.nd_file;
          ruby_sourceline = nd_line(ruby_current_node);
        }
      }
    END
  end
  
  # IS THE [0] OF A LOCAL TBL ITS LENGTH?
  def scope_dup
    <<-END
      function scope_dup(scope) {
        var tbl;
        var vars;
        scope.flags |= SCOPE_DONT_RECYCLE;
        if (scope.flags & SCOPE_MALLOC) { return; }
        if (scope.local_tbl) {
          tbl = scope.local_tbl;
          vars = []; // was 'vars = ALLOC_N(VALUE, tbl[0]+1)'
          vars.zero = scope.local_vars.zero; // added... but why?
          MEMCPY(vars, scope.local_vars, tbl[0]); // IS THE [0] OF A LOCAL TBL ITS LENGTH?
          scope.local_vars = vars;
          scope.flags |= SCOPE_MALLOC;
        }
      }
    END
  end
  
  # modified to return array including '*origin': [body, origin]
  def search_method
    <<-END
      function search_method(klass, id, origin) {
        var body;
        if (!klass) { return [0, origin]; } // returning array
        while (!(body = st_lookup(klass.m_tbl, id))[0]) {
          klass = klass.superclass;
          if (!klass) { return [0, origin]; }
        }
        origin = klass;
        return [body[1], origin]; // returning array
      }
    END
  end
  
  # verbatim
  def secure_visibility
    add_function :rb_raise
    <<-END
      function secure_visibility(self) {
        if (ruby_safe_level >= 4 && !OBJ_TAINTED(self)) { rb_raise(rb_eSecurityError, "Insecure: can't change method visibility"); }
      }
    END
  end
  
  # verbatim
  def set_backtrace
    add_function :rb_funcall, :rb_intern
    add_method :set_backtrace
    <<-END
      function set_backtrace(info, bt) {
        rb_funcall(info, rb_intern('set_backtrace'), 1, bt);
      }
    END
  end
  
  # verbatim
  def set_method_visibility
    add_function :rb_export_method, :rb_to_id, :rb_clear_cache_by_class, :secure_visibility
    <<-END
      function set_method_visibility(self, argc, argv, ex) {
        secure_visibility(self);
        for (var i = 0; i < argc; ++i) {
          rb_export_method(self, rb_to_id(argv[i]), ex);
        }
        rb_clear_cache_by_class(self);
      }
    END
  end
  
  # removed option to eval a string
  def specific_eval
    add_function :rb_block_given_p, :rb_raise, :yield_under
    <<-END
      function specific_eval(argc, argv, klass, self) {
        if (rb_block_given_p()) {
          if (argc > 0) { rb_raise(rb_eArgError, "wrong number of arguments (%d for 0)", argc); }
          return yield_under(klass, self, Qundef);
        } else {
          rb_raise(rb_eArgError, "block not supplied");
        }
      }
    END
  end
  
  # verbatim
  def splat_value
    add_function :rb_Array, :rb_ary_new3
    <<-END
      function splat_value(v) {
        return NIL_P(v) ? rb_ary_new3(1, Qnil) : rb_Array(v);
      }
    END
  end
  
  # verbatim
  def svalue_to_avalue
    add_function :rb_ary_new, :rb_check_array_type, :rb_ary_new3
    <<-END
      function svalue_to_avalue(v) {
        var tmp;
        var top;
        if (v == Qundef) { return rb_ary_new(); }
        tmp = rb_check_array_type(v);
        if (NIL_P(tmp)) { return rb_ary_new3(1, v); }
        if (tmp.ptr.length == 1) {
          top = rb_check_array_type(tmp.ptr[0]);
          if (!NIL_P(top) && top.ptr.length > 1) { return tmp; }
          return rb_ary_new3(1, v);
        }
        return tmp;
      }
    END
  end
  
  # changed rb_ary_new2 to rb_ary_new
  def svalue_to_mrhs
    add_function :rb_ary_new, :rb_check_array_type, :rb_ary_new3
    <<-END
      function svalue_to_mrhs(v, lhs) {
        if (v == Qundef) { return rb_ary_new(); }
        var tmp = rb_check_array_type(v);
        if (NIL_P(tmp)) { return rb_ary_new3(1, v); }
        /* no lhs means splat lhs only */
        if (!lhs) { return rb_ary_new3(1, v); }
        return tmp;
      }
    END
  end
  
  # verbatim
  def top_include
    add_function :rb_secure, :rb_mod_include
    <<-END
      function top_include(argc, argv, self) {
        rb_secure(4);
        return rb_mod_include(argc, argv, rb_cObject);
      }
    END
  end
  
  # verbatim
  def top_public
    add_function :rb_mod_public
    <<-END
      function top_public(argc, argv) {
        return rb_mod_public(argc, argv, rb_cObject);
      }
    END
  end
  
  # modified to use jsprintf instead of va_args
  def warn_printf
    add_function :rb_write_error
    <<-END
      function warn_printf(fmt) {
        for (var i = 1, ary = []; typeof(arguments[i]) != 'undefined'; ++i) { ary.push(arguments[i]); }
        var buf = jsprintf(fmt,ary);
        rb_write_error(buf);
      }
    END
  end
  
  # verbatim
  def yield_args_under_i
    add_function :rb_yield_0
    <<-END
      function yield_args_under_i(info) {
        return rb_yield_0(info[0], info[1], ruby_class, YIELD_PUBLIC_DEF, Qtrue);
      }
    END
  end
  
  # verbatim
  def yield_under
    add_function :exec_under, :yield_under_i, :yield_args_under_i
    <<-END
      function yield_under(under, self, args) {
        if (args == Qundef) {
          return exec_under(yield_under_i, under, 0, self);
        } else {
          return exec_under(yield_args_under_i, under, 0, [args, self]);
        }
      }
    END
  end
  
  # verbatim
  def yield_under_i
    add_function :rb_yield_0
    <<-END
      function yield_under_i(self) {
        return rb_yield_0(self, self, ruby_class, YIELD_PUBLIC_DEF, Qfalse);
      }
    END
  end
end
