class Red::MethodCompiler
  # CHECK
  def proc_alloc
    add_function :rb_block_given_p, :rb_f_block_given_p, :rb_raise, :frame_dup,
                 :blk_copy_prev, :scope_dup, :proc_save_safe_level
    <<-END
      function proc_alloc(klass, proc) {
        var data;
        if (!rb_block_given_p() && !rb_f_block_given_p()) { rb_raise(rb_eArgError, "tried to create Proc object without a block"); }
        if (!proc && ruby_block.block_obj && (CLASS_OF(ruby_block.block_obj) == klass)) { return ruby_block.block_obj; }
      //var block = Data_Make_Struct(klass, BLOCK, blk_mark, blk_free, data);
        var data = ruby_block;
        var block = NEWOBJ();
        OBJSETUP(block, klass, T_DATA);
        block.data = data;
      //data.orig_thread = rb_thread_current();
      //data.wrapper = ruby_wrapper;
        data.iter = data.prev ? Qtrue : Qfalse;
        data.block_obj = block;
        frame_dup(data.frame);
        if (data.iter) {
          blk_copy_prev(data);
        } else {
          data.prev = 0;
        }
        for (var p = data; p; p = p.prev) {
          for (var vars = p.dyna_vars; vars; vars = vars.next) {
            if (FL_TEST(vars, DVAR_DONT_RECYCLE)) { break; }
            FL_SET(vars, DVAR_DONT_RECYCLE);
          }
        }
        scope_dup(data.scope);
        proc_save_safe_level(block);
        if (proc) {
          data.flags |= BLOCK_LAMBDA;
        } else {
          ruby_block.block_obj = block;
        }
        return block;
      }
    END
  end
  
  # EMPTY
  def proc_eq
    <<-END
      function proc_eq() {}
    END
  end
  
  # CHECK
  def proc_get_safe_level
    <<-END
      function proc_get_safe_level(data) {
        return (data.flags & PROC_TMASK) >> PROC_TSHIFT;
      }
    END
  end
  
  # CHECK
  def proc_invoke
    add_function :proc_set_safe_level, :return_jump
    <<-END
      function proc_invoke(proc, args, self, klass) {
        var result = Qundef;
        var safe = ruby_safe_level;
        var avalue = Qtrue;
        var tmp = args;
        var bvar = Qnil;
        var state = 0;
        if (rb_block_given_p() && ruby_frame.last_func) {
          if (klass != ruby_frame.last_class) { klass = rb_obj_class(proc); }
          bvar = rb_block_proc();
        }
        var data = proc.data;
        var pcall = (data.flags & BLOCK_LAMBDA) ? YIELD_LAMBDA_CALL : 0;
        if (!pcall && args.ptr.length == 1) {
          avalue = Qfalse;
          args = args.ptr;
        }
        var _old_vars = ruby_dyna_vars; // ff. was PUSH_VARS
        ruby_dyna_vars = 0; // ^^
        ruby_dyna_vars = data.dyna_vars;
        var old_block = ruby_block;
        var _block = data;
        _block.block_obj = bvar;
        if (self != Qundef) { _block.frame.self = self; }
        if (klass) { _block.frame.last_class = klass; }
        _block.frame.argc = tmp.ptr.length;
        _block.frame.flags = ruby_frame.flgas;
        if (_block.frame.argc && DMETHOD_P()) {
          var scope = { val: last_value += 4 };
          OBJSETUP(scope, tmp, T_SCOPE);
          scope.local_tbl = _block.scope.local_tbl;
          scope.local_vars = _block.scope.local_vars;
          scope.flags |= SCOPE_CLONE;
          _block.scope = scope;
        }
        ruby_block = _block;
        var _iter = {}; // ff. was PUSH_ITER(ITER_CUR)
        _iter.prev = ruby_iter;
        _iter.iter = ITER_CUR;
        ruby_iter = _iter; // ^^
        ruby_frame.iter = ITER_CUR;
        var _tag = {}; // ff. was PUSH_TAG(pcall ? PROT_LAMBDA : PROT_NONE)
        _tag.retval = Qnil;
        _tag.frame = ruby_frame;
        _tag.iter = ruby_iter;
        _tag.prev = prot_tag;
        _tag.scope = ruby_scope;
        _tag.tag = pcall ? PROT_LAMBDA : PROT_NONE;
        _tag.dst = 0;
        _tag.blkid = 0;
        prot_tag = _tag; // ^
        try {
          proc_set_safe_level(proc);
          result = rb_yield_0(args[0], self, (self != Qundef) ? CLASS_OF(self) : 0, pcall | YIELD_PROC_CALL, avalue);
        //result = rb_yield_0(args, self, (self != Qundef) ? CLASS_OF(self) : 0, pcall | YIELD_PROC_CALL, avalue);
        } catch (x) {
          if (typeof(state = x) != 'number') { throw(state); }
          if (TAG_DST()) { result = prot_tag.retval; }
        }
        prot_tag = _tag.prev; // was POP_TAG
        ruby_iter = _iter.prev; // was POP_ITER
        ruby_block = old_block;
        if (_old_vars && (ruby_scope.flags & SCOPE_DONT_RECYCLE)) { // ff. was POP_VARS
          if (_old_vars.basic.flags) /* unless it's already recycled */ { FL_SET(_old_vars, DVAR_DONT_RECYCLE); }
        }
        ruby_dyna_vars = _old_vars; // ^^
        ruby_safe_level = safe;
        switch (state) {
          case 0:
            break;
          case TAG_RETRY:
            proc_jump_error(TAG_RETRY, Qnil);
            JUMP_TAG(state);
            break;
          case TAG_NEXT:
          case TAG_BREAK:
            if (!pcall && result != Qundef) { proc_jump_error(state, result); }
          case TAG_RETURN:
            if (result != Qundef) {
              if (pcall) { break; }
              return_jump(result);
            }
            break;
          default:
            JUMP_TAG(state);
        }
        return result;
      }
    END
  end
  
  # CHECK
  def proc_lambda
    add_function :proc_alloc
    <<-END
      function proc_lambda() {
        return proc_alloc(rb_cProc, Qtrue);
      }
    END
  end
  
  # verbatim
  def proc_s_new
    add_function :proc_alloc, :rb_obj_call_init
    <<-END
      function proc_s_new(argc, argv, klass) {
        var block = proc_alloc(klass, Qfalse);
        rb_obj_call_init(block, argc, argv);
        return block;
      }
    END
  end
  
  # CHECK
  def proc_save_safe_level
    <<-END
      function proc_save_safe_level(data) {
        var safe = ruby_safe_level;
        if (safe > PROC_TMAX) { safe = PROC_TMAX; }
        FL_SET(data, (safe << PROC_TSHIFT) & PROC_TMASK);
      }
    END
  end
  
  # CHECK
  def proc_set_safe_level
    add_function :proc_get_safe_level
    <<-END
      function proc_set_safe_level(data) {
        ruby_safe_level = proc_get_safe_level(data);
      }
    END
  end
  
  # eliminated "len" handling
  def proc_to_s
    add_function :rb_obj_classname
    <<-END
      function proc_to_s(self) {
        var node;
        var cname = rb_obj_classname(self);
        var str = rb_str_new();
        var data = self.data;
        if ((node = data.frame.node) || (node = data.body)) {
          p = jsprintf("#<%s:0x%x@%s:%d>", [cname, data.body.rvalue, node.ndfile, nd_line(node)]);
        } else {
          p = jsprintf("#<%s:0x%x>", [cname, data.body.rvalue]);
        }
        if (OBJ_TAINTED(self)) { OBJ_TAINT(str); }
        return str;
      }
    END
  end
  
  # verbatim
  def proc_to_self
    <<-END
      function proc_to_self(self) {
        return self;
      }
    END
  end
  
  # CHECK
  def rb_obj_is_proc
    <<-END
      function rb_obj_is_proc(proc) {
      //if (TYPE(proc) == T_DATA && RDATA(proc)->dfree == (RUBY_DATA_FUNC)blk_free) {
        return (TYPE(proc) == T_DATA) ? Qtrue : Qfalse;
      }
    END
  end
  
  # CHECK
  def rb_proc_call
    add_function :proc_invoke
    <<-END
      function rb_proc_call(proc, args) {
        return proc_invoke(proc, args, Qundef, 0);
      }
    END
  end
  
  # verbatim
  def rb_proc_new
    add_function :rb_iterate, :mproc
    <<-END
      function rb_proc_new(func, val) {/* VALUE yieldarg[, VALUE procarg] */
        var proc = rb_iterate(mproc, 0, func, val);
        var data = proc.data;
        data.body.nd_state = YIELD_FUNC_LAMBDA;
        data.flags |= BLOCK_LAMBDA;
        return proc;
      }
    END
  end
end
