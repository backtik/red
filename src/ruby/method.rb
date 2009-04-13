class Red::MethodCompiler
  # empty placeholder to identify Data structs as methods
  def bm_mark
    <<-END
      function bm_mark() {};
    END
  end
  
  # verbatim
  def bmcall
    add_function :svalue_to_avalue, :method_call
    <<-END
      function bmcall(args, method) {
        var a = svalue_to_avalue(args);
        var ret = method_call(a.ptr.length, a.ptr, method);
        a = Qnil; /* prevent tail call */
        return ret;
      }
    END
  end
  
  # verbatim
  def method_call
    add_function :rb_raise, :rb_block_given_p, :rb_call0
    <<-END
      function method_call(argc, argv, method) {
        var safe;
        var result = Qnil; /* OK */
        var data = method.data;
        if (data.recv == Qundef) { rb_raise(rb_eTypeError, "can't call unbound method; bind first"); }
        if (OBJ_TAINTED(method)) {
          safe = NOEX_WITH(data.safe_level, 4) | NOEX_TAINTED;
        } else {
          safe = data.safe_level;
        }
        PUSH_ITER(rb_block_given_p() ? ITER_PRE : ITER_NOT);
        result = rb_call0(data.klass, data.recv, data.id, data.oid, argc, argv, data.body, safe);
        POP_ITER();
        return result;
      }
    END
  end
  
  # EMPTY
  def method_eq
    <<-END
      function method_eq() {}
    END
  end
  
  # EMPTY
  def method_inspect
    <<-END
      function method_inspect() {}
    END
  end
  
  # verbatim
  def method_proc
    add_function :mproc, :bmcall
    <<-END
      function method_proc(method) {
        var proc = rb_iterate(mproc, 0, bmcall, method);
        var mdata = method.data;
        var bdata = proc.data;
        bdata.body.nd_file = mdata.body.nd_file;
        nd_set_line(bdata.body, nd_line(mdata.body));
        bdata.body.nd_state = YIELD_FUNC_SVALUE;
        return proc;
      }
    END
  end
  
  # expanded Data_Make_Struct
  def method_unbind
    add_function :rb_data_object_alloc
    <<-END
      function method_unbind(obj) {
        Data_Get_Struct(obj, orig);
        var data = {};
        var method = rb_data_object_alloc(rb_cUnboundMethod, data, bm_mark); // was 'Data_Make_Struct(rb_cUnboundMethod, struct METHOD, bm_mark, free, data)'
        data.klass = orig.klass;
        data.recv = Qundef;
        data.id = orig.id;
        data.body = orig.body;
        data.rklass = orig.rklass;
        data.oid = orig.oid;
        OBJ_INFECT(method, obj);
        return method;
      }
    END
  end
  
  # expanded Data_Make_Struct
  def mnew
    add_function :rb_get_method_body, :print_undef, :bm_mark
    <<-END
      function mnew(klass, obj, id, mklass) {
        var method;
        var body;
        var noex;
        var data = {};
        var rklass = klass;
        var oid = id;
        do { // added to handle 'goto again'
          var goto_again = 0;
          var tmp = rb_get_method_body(klass, id, noex);
          var body = tmp[0];
          var klass = tmp[1];
          var id = tmp[2];
          var noex = tmp[3];
          if (body === 0) { print_undef(rklass, oid); }
          if (nd_type(body) == NODE_ZSUPER) {
            klass = klass.superclass;
            goto_again = 1;
          }
        } while (goto_again); // added to handle 'goto again'
        while ((rklass != klass) && (FL_TEST(rklass, FL_SINGLETON) || (TYPE(rklass) == T_ICLASS))) {
          rklass = rklass.superclass;
        }
        if (TYPE(klass) == T_ICLASS) { klass = klass.klass; }
        data = {
          'klass': klass,
          'recv': obj,
          'id': id,
          'body': body,
          'rklass': rklass,
          'oid': oid,
          'safe_level': NOEX_WITH_SAFE(noex)
        };
        method = rb_data_object_alloc(mklass, data, bm_mark)
        OBJ_INFECT(method, klass);
        return method;
      }
    END
  end
  
  # verbatim
  def mproc
    add_function :rb_block_proc
    <<-END
      function mproc(method) {
        PUSH_ITER(ITER_CUR);
        PUSH_FRAME();
        var proc = rb_block_proc();
        POP_FRAME();
        POP_ITER();
        return proc;
      }
    END
  end
  
  # verbatim
  def rb_obj_is_method
    <<-END
      function rb_obj_is_method(m) {
        return ((TYPE(m) == T_DATA) && (m.dmark == bm_mark)) ? Qtrue : Qfalse;
      }
    END
  end
end
