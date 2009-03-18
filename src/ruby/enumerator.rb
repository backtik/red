class Red::MethodCompiler
  # expanded 'Data_Make_Struct'
  def enumerator_allocate
    add_function :rb_data_object_alloc
    <<-END
      function enumerator_allocate(klass) {
        var ptr = {};
        var enum_obj = rb_data_object_alloc(klass, ptr, 0, -1);
        ptr.obj = Qundef;
        return enum_obj;
      }
    END
  end
  
  # verbatim
  def enumerator_each
    add_function :rb_block_given_p, :enumerator_ptr, :rb_block_call
    <<-END
      function enumerator_each(obj) {
        if (!rb_block_given_p()) { return obj; }
        var argc = 0;
        var argv = 0;
        var e = enumerator_ptr(obj);
        if (e.args) {
          argc = e.args.ptr.length;
          argv = e.args.ptr;
        }
        return rb_block_call(e.obj, e.meth, argc, argv, e.iter, e);
      }
    END
  end
  
  # verbatim
  def enumerator_each_i
    add_function :rb_yield
    <<-END
      function enumerator_each_i(v, enum_obj) {
        return rb_yield(v);
      }
    END
  end
  
  # expanded Data_Get_Struct
  def enumerator_init_copy
    add_function :enumerator_ptr, :rb_raise
    <<-END
      function enumerator_init_copy(obj, orig) {
        var ptr0 = enumerator_ptr(orig);
        var ptr1 = obj.data;
        if (!ptr1) { rb_raise(rb_eArgError, "unallocated enumerator"); }
        ptr1.obj  = ptr0.obj;
        ptr1.meth = ptr0.meth;
        ptr1.iter = ptr0.iter;
        ptr1.args = ptr0.args;
        return obj;
      }
    END
  end
  
  # verbatim
  def enumerator_init
    add_function :rb_ary_new4, :enumerator_each_i, :rb_to_id, :rb_raise
    <<-END
      function enumerator_init(enum_obj, obj, meth, argc, argv) {
        var ptr = enum_obj.data;
        if (!ptr) { rb_raise(rb_eArgError, "unallocated enumerator"); }
        ptr.obj  = obj;
        ptr.meth = rb_to_id(meth);
        ptr.iter = enumerator_each_i;
        if (argc) { ptr.args = rb_ary_new4(argc, argv); }
        return enum_obj;
      }
    END
  end
  
  # verbatim
  def enumerator_initialize
    add_function :rb_raise, :enumerator_init
    <<-END
      function enumerator_initialize(argc, argv, obj) {
        if (argc === 0) { rb_raise(rb_eArgError, "wrong number of argument (0 for 1)"); }
        var meth = sym_each;
        var argvp = 0;
        var recv = argv[argvp++];
        if (--argc) {
          meth = argv[argvp++];
          --argc;
        }
        return enumerator_init(obj, recv, meth, argc, argv.slice(argvp));
      }
    END
  end
  
  # expanded Data_Get_Struct
  def enumerator_ptr
    add_function :rb_raise
    <<-END
      function enumerator_ptr(obj) {
        var ptr = obj.data;
      //if (obj.dmark != enumerator_mark) { rb_raise(rb_eTypeError, "wrong argument type %s (expected Enumerable::Enumerator)", rb_obj_classname(obj)); }
        if (!ptr || (ptr.obj == Qundef)) { rb_raise(rb_eArgError, "uninitialized enumerator"); }
        return ptr;
      }
    END
  end
end

